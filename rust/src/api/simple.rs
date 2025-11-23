use image::GenericImageView;
use oxidize_pdf::{Document, Image, Page};
use std::fs::File;
use std::path::Path;
use walkdir::WalkDir;
pub use zip::CompressionMethod;
use zip::{
    write::{FileOptions, ZipWriter},
    ZipArchive,
};

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[flutter_rust_bridge::frb(mirror(CompressionMethod))]
pub enum _CompressionMethod {
    Stored,
    Deflated,
    Deflate64,
    Bzip2,
    Aes,
    Zstd,
    Lzma,
    Xz,
    Ppmd,
}

// 压缩
pub fn compress(
    source_folder_path: &str,
    output_zip_path: &str,
    compression_method: CompressionMethod,
) -> Result<(), String> {
    let path = Path::new(source_folder_path);

    if !path.is_dir() {
        return Err(format!(
            "Source folder '{}' is not a directory",
            source_folder_path
        ));
    }

    let file = File::create(output_zip_path).map_err(|e| e.to_string())?;
    let mut zip = ZipWriter::new(file);

    let options: FileOptions<'_, ()> =
        FileOptions::default().compression_method(compression_method);

    for entry in WalkDir::new(source_folder_path) {
        let entry = entry.map_err(|e| e.to_string())?;
        let entry_path = entry.path();

        // 跳过输出的zip文件本身
        if entry_path == Path::new(output_zip_path) {
            continue;
        }

        let relative_path = entry_path
            .strip_prefix(source_folder_path)
            .map_err(|e| e.to_string())?;

        if entry_path.is_file() {
            zip.start_file(relative_path.to_string_lossy(), options)
                .map_err(|e| e.to_string())?;
            let mut f = File::open(entry_path).map_err(|e| e.to_string())?;
            std::io::copy(&mut f, &mut zip).map_err(|e| e.to_string())?;
        } else if relative_path.as_os_str().len() != 0 {
            zip.add_directory(relative_path.to_string_lossy(), options)
                .map_err(|e| e.to_string())?;
        }
    }

    zip.finish().map_err(|e| e.to_string())?;

    Ok(())
}

// 解压
pub fn decompress(source_zip_path: &str, output_folder_path: &str) -> Result<(), String> {
    let file = File::open(source_zip_path).map_err(|e| e.to_string())?;
    let mut archive = ZipArchive::new(file).map_err(|e| e.to_string())?;

    for i in 0..archive.len() {
        let mut file = archive.by_index(i).map_err(|e| e.to_string())?;
        let out_path = Path::new(output_folder_path).join(file.mangled_name());

        if (*file.name()).ends_with('/') {
            std::fs::create_dir_all(&out_path).map_err(|e| e.to_string())?;
        } else {
            if let Some(p) = out_path.parent() {
                if !p.exists() {
                    std::fs::create_dir_all(&p).map_err(|e| e.to_string())?;
                }
            }
            let mut out_file = File::create(&out_path).map_err(|e| e.to_string())?;
            std::io::copy(&mut file, &mut out_file).map_err(|e| e.to_string())?;
        }
    }

    Ok(())
}

// 导出pdf
pub fn export_pdf(source_folder_path: &str, output_pdf_path: &str) -> Result<(), String> {
    let fixed_width: f64 = 210.0;

    let mut doc = Document::new();

    let images = collect_images(source_folder_path);

    for image in images.iter() {
        println!("Add image: {:?}", image.path);

        let img = image::open(image.path.clone()).unwrap();
        let (img_w, img_h) = img.dimensions();

        // 等比缩放计算
        let scale = fixed_width / (img_w as f64);
        let display_h = img_h as f64 * scale;

        let mut page = Page::new(fixed_width, display_h);

        let img = match image.ext.as_str() {
            "jpg" | "jpeg" => Image::from_jpeg_file(&image.path).unwrap(),
            "png" => Image::from_png_file(&image.path).unwrap(),
            _ => continue,
        };

        let name = Path::new(&image.path)
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap();

        page.add_image(name, img);

        page.draw_image(name, 0.0, 0.0, fixed_width, display_h)
            .unwrap();

        doc.add_page(page);
    }

    doc.save(output_pdf_path).map_err(|e| e.to_string())?;

    println!("PDF saved → {}", output_pdf_path);

    Ok(())
}

struct ImageMeta {
    pub path: String,
    pub ext: String,
}

/// 递归收集图片
fn collect_images(dir: &str) -> Vec<ImageMeta> {
    let mut imgs: Vec<ImageMeta> = vec![];

    for entry in WalkDir::new(dir) {
        let entry = entry.unwrap();
        let path = entry.path();

        if path.is_file() {
            let ext = path
                .extension()
                .and_then(|e| e.to_str())
                .unwrap_or("")
                .to_lowercase();
            if ["jpg", "jpeg", "png", "webp"].contains(&ext.as_str()) {
                imgs.push(ImageMeta {
                    path: path.to_string_lossy().to_string(),
                    ext,
                });
            }
        }
    }
    imgs.sort_by(|a, b| a.path.cmp(&b.path));
    imgs
}
