use human_sort::compare;
use image::ImageFormat;
use oxidize_pdf::{Document, Image, Page};
use rayon::prelude::*;
use std::io::Cursor;
use std::sync::atomic::{AtomicUsize, Ordering};
use walkdir::WalkDir;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

static COUNTER: AtomicUsize = AtomicUsize::new(0);

// 测试scannedpdf的速度不理想
pub fn export_pdf(source_folder_path: &str, output_pdf_path: &str) -> Result<(), String> {
    let fixed_width: f64 = 595.0;

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
    let data = std::fs::read(path).map_err(|e| e.to_string())?;
    let format = image::guess_format(&data).unwrap();
    let dynamic_image = image::load_from_memory(&data).map_err(|e| e.to_string())?;

    let img_obj = match format {
        ImageFormat::Jpeg => Image::from_jpeg_data(data).map_err(|e| e.to_string())?,
        ImageFormat::Png => Image::from_png_data(data).map_err(|e| e.to_string())?,
        _ => {
            let mut bytes: Vec<u8> = Vec::new();
            dynamic_image
                .write_to(&mut Cursor::new(&mut bytes), ImageFormat::Jpeg)
                .map_err(|_| "转码失败".to_string())?;

            Image::from_jpeg_data(bytes).map_err(|e| e.to_string())?
        }
    };

    // 3. 准备元数据
    let id = COUNTER.fetch_add(1, Ordering::Relaxed);
    let name = format!("img_{}", id);

    let img_w = img_obj.width();
    let img_h = img_obj.height();
    let scale = fixed_width / (img_w as f64);
    let display_h = img_h as f64 * scale;

    Ok((img_obj, name, display_h))
}

/// 递归收集图片
fn collect_images(dir: &str) -> Vec<String> {
    let mut imgs = WalkDir::new(dir)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().is_file())
        .filter(|e| {
            let ext = e
                .path()
                .extension()
                .and_then(|e| e.to_str())
                .unwrap_or("")
                .to_lowercase();
            ["jpg", "jpeg", "png", "webp"].contains(&ext.as_str())
        })
        .map(|e| e.path().to_string_lossy().to_string())
        .collect::<Vec<String>>();

    imgs.sort_by(|a, b| compare(a, b));

    imgs
}
