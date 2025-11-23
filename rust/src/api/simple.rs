use image::ImageReader;
use oxidize_pdf::{Document, Image, Page};
use rayon::prelude::*;
use std::fs::File;
use std::io::{BufReader, Cursor};
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
// pub fn export_pdf(source_folder_path: &str, output_pdf_path: &str) -> Result<(), String> {
//     let fixed_width: f64 = 210.0;

//     let mut doc = Document::new();

//     let images = collect_images(source_folder_path);

//     for path in images.iter() {
//         let reader = ImageReader::new(BufReader::new(File::open(path).unwrap()))
//             .with_guessed_format()
//             .unwrap();

//         let img = match reader.format() {
//             Some(image::ImageFormat::Jpeg) => Image::from_jpeg_file(path).unwrap(),
//             Some(image::ImageFormat::Png) => Image::from_png_file(path).unwrap(),
//             _ => {
//                 let mut bytes: Vec<u8> = Vec::new();
//                 reader
//                     .decode()
//                     .unwrap()
//                     .write_to(&mut Cursor::new(&mut bytes), image::ImageFormat::Jpeg)
//                     .unwrap();
//                 Image::from_jpeg_data(bytes).unwrap()
//             }
//         };

//         let img_w = img.width();
//         let img_h = img.height();

//         let scale = fixed_width / (img_w as f64);
//         let display_h = img_h as f64 * scale;

//         let mut page = Page::new(fixed_width, display_h);

//         let name = Path::new(path)
//             .file_name()
//             .and_then(|n| n.to_str())
//             .unwrap();

//         page.add_image(name, img);

//         page.draw_image(name, 0.0, 0.0, fixed_width, display_h)
//             .unwrap();

//         doc.add_page(page);
//     }

//     doc.save(output_pdf_path).map_err(|e| e.to_string())?;

//     println!("PDF saved → {}", output_pdf_path);

//     Ok(())
// }

pub fn export_pdf(source_folder_path: &str, output_pdf_path: &str) -> Result<(), String> {
    let fixed_width: f64 = 210.0;

    let all_images = collect_images(source_folder_path);

    let mut doc = Document::new();

    const BATCH_SIZE: usize = 20;

    for (_, chunk) in all_images.chunks(BATCH_SIZE).enumerate() {
        let processed_batch: Vec<Result<(Image, String, f64), String>> = chunk
            .par_iter()
            .map(|path| process_single_image(path, fixed_width))
            .collect();

        for result in processed_batch {
            match result {
                Ok((img, name, display_h)) => {
                    let mut page = Page::new(fixed_width, display_h);
                    page.add_image(&name, img);

                    if let Err(e) = page.draw_image(&name, 0.0, 0.0, fixed_width, display_h) {
                        eprintln!("警告: 图片绘制失败 [{}]: {}", name, e);
                    }

                    doc.add_page(page);
                }
                Err(e) => {
                    eprintln!("警告: 跳过损坏或无法读取的图片: {}", e);
                }
            }
        }
    }

    doc.save(output_pdf_path).map_err(|e| e.to_string())?;

    Ok(())
}

fn process_single_image(path: &str, fixed_width: f64) -> Result<(Image, String, f64), String> {
    let file = File::open(path).map_err(|e| e.to_string())?;
    let reader = ImageReader::new(BufReader::new(file))
        .with_guessed_format()
        .map_err(|e| e.to_string())?;

    let format = reader.format();

    let img_obj = match format {
        Some(image::ImageFormat::Jpeg) => Image::from_jpeg_file(path).map_err(|e| e.to_string())?,
        Some(image::ImageFormat::Png) => Image::from_png_file(path).map_err(|e| e.to_string())?,
        _ => {
            let mut bytes: Vec<u8> = Vec::new();
            reader
                .decode()
                .map_err(|_| "解码失败".to_string())?
                .write_to(&mut Cursor::new(&mut bytes), image::ImageFormat::Jpeg)
                .map_err(|_| "转码失败".to_string())?;

            Image::from_jpeg_data(bytes).map_err(|e| e.to_string())?
        }
    };

    // 3. 准备元数据
    let name = Path::new(path)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown")
        .to_string();

    let img_w = img_obj.width();
    let img_h = img_obj.height();
    let scale = fixed_width / (img_w as f64);
    let display_h = img_h as f64 * scale;

    Ok((img_obj, name, display_h))
}

/// 递归收集图片
fn collect_images(dir: &str) -> Vec<String> {
    let mut imgs = vec![];

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
                imgs.push(path.to_string_lossy().to_string());
            }
        }
    }
    imgs.sort();
    imgs
}
