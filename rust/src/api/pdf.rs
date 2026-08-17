use human_sort::compare;
use image::{codecs::jpeg::JpegEncoder, ColorType, DynamicImage, GenericImageView, ImageFormat};
use rayon::prelude::*;
use std::fs::File;
use std::io::{BufWriter, Write};
use std::ops::Range;
use walkdir::WalkDir;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

const PAGE_WIDTH: f64 = 595.0;
const JPEG_QUALITY: u8 = 90;
const MAX_PARALLEL_IMAGES: usize = 8;
const MAX_BATCH_MEMORY_BYTES: u64 = 384 * 1024 * 1024;

pub fn export_pdf(source_folder_path: &str, output_pdf_path: &str) -> Result<(), String> {
    let all_images = collect_images(source_folder_path);
    let file = File::create(output_pdf_path).map_err(|e| e.to_string())?;
    let writer = BufWriter::with_capacity(1024 * 1024, file);
    let mut pdf = PdfStreamWriter::new(writer)?;

    for range in processing_batches(&all_images) {
        let processed_batch: Vec<Result<ProcessedImage, String>> = all_images[range]
            .par_iter()
            .map(|path| process_single_image(path, PAGE_WIDTH))
            .collect();

        for result in processed_batch {
            match result {
                Ok(image) => pdf.add_image_page(image)?,
                Err(e) => eprintln!("警告: 跳过损坏或无法读取的图片: {e}"),
            }
        }
    }

    pdf.finish()
}

fn export_batch_size() -> usize {
    std::thread::available_parallelism()
        .map(|threads| threads.get())
        .unwrap_or(4)
        .clamp(1, MAX_PARALLEL_IMAGES)
}

fn processing_batches(paths: &[String]) -> Vec<Range<usize>> {
    let max_images = export_batch_size();
    let mut batches = Vec::new();
    let mut start = 0;

    while start < paths.len() {
        let mut end = start;
        let mut estimated_bytes = 0u64;

        while end < paths.len() && end - start < max_images {
            let next_estimate = estimate_image_memory(&paths[end]);
            if end > start && estimated_bytes.saturating_add(next_estimate) > MAX_BATCH_MEMORY_BYTES
            {
                break;
            }

            estimated_bytes = estimated_bytes.saturating_add(next_estimate);
            end += 1;
        }

        batches.push(start..end);
        start = end;
    }

    batches
}

fn estimate_image_memory(path: &str) -> u64 {
    let file_size = std::fs::metadata(path).map(|meta| meta.len()).unwrap_or(0);
    let extension = std::path::Path::new(path)
        .extension()
        .and_then(|ext| ext.to_str())
        .unwrap_or_default()
        .to_ascii_lowercase();

    if extension == "jpg" || extension == "jpeg" {
        return file_size.max(1);
    }

    match image::image_dimensions(path) {
        Ok((width, height)) => {
            let pixels = width as u64 * height as u64;
            file_size.saturating_add(pixels.saturating_mul(8)).max(1)
        }
        Err(_) => file_size.saturating_add(64 * 1024 * 1024).max(1),
    }
}

struct ProcessedImage {
    data: Vec<u8>,
    width: u32,
    height: u32,
    color_space: &'static str,
    bits_per_component: u8,
    display_height: f64,
}

fn process_single_image(path: &str, fixed_width: f64) -> Result<ProcessedImage, String> {
    let data = std::fs::read(path).map_err(|e| format!("{path}: {e}"))?;
    let format = image::guess_format(&data).map_err(|e| format!("{path}: {e}"))?;

    match format {
        ImageFormat::Jpeg => {
            let info = parse_jpeg_info(&data).map_err(|e| format!("{path}: {e}"))?;
            build_processed_image(
                data,
                info.width,
                info.height,
                info.color_space,
                info.bits_per_component,
                fixed_width,
            )
            .map_err(|e| format!("{path}: {e}"))
        }
        ImageFormat::Png | ImageFormat::WebP => {
            let dynamic_image = image::load_from_memory_with_format(&data, format)
                .map_err(|e| format!("{path}: {e}"))?;
            let (width, height) = dynamic_image.dimensions();
            let jpeg = encode_dynamic_image_as_jpeg(dynamic_image)?;
            build_processed_image(jpeg, width, height, "DeviceRGB", 8, fixed_width)
                .map_err(|e| format!("{path}: {e}"))
        }
        _ => Err(format!("{path}: unsupported image format")),
    }
}

fn build_processed_image(
    data: Vec<u8>,
    width: u32,
    height: u32,
    color_space: &'static str,
    bits_per_component: u8,
    fixed_width: f64,
) -> Result<ProcessedImage, String> {
    if width == 0 || height == 0 {
        return Err("image has zero width or height".to_string());
    }

    Ok(ProcessedImage {
        data,
        width,
        height,
        color_space,
        bits_per_component,
        display_height: height as f64 * (fixed_width / width as f64),
    })
}

fn encode_dynamic_image_as_jpeg(image: DynamicImage) -> Result<Vec<u8>, String> {
    let (width, height) = image.dimensions();
    let rgb = if image.has_alpha() {
        flatten_alpha_on_white(image)
    } else {
        image.to_rgb8().into_raw()
    };
    let mut bytes = Vec::new();
    let mut encoder = JpegEncoder::new_with_quality(&mut bytes, JPEG_QUALITY);

    encoder
        .encode(&rgb, width, height, ColorType::Rgb8.into())
        .map_err(|e| format!("transcode failed: {e}"))?;

    Ok(bytes)
}

fn flatten_alpha_on_white(image: DynamicImage) -> Vec<u8> {
    let rgba = image.to_rgba8();
    let mut rgb = Vec::with_capacity(rgba.width() as usize * rgba.height() as usize * 3);

    for pixel in rgba.pixels() {
        let alpha = pixel[3] as u16;
        for channel in &pixel.0[..3] {
            let blended = (*channel as u16 * alpha + 255 * (255 - alpha) + 127) / 255;
            rgb.push(blended as u8);
        }
    }

    rgb
}

struct JpegInfo {
    width: u32,
    height: u32,
    color_space: &'static str,
    bits_per_component: u8,
}

fn parse_jpeg_info(data: &[u8]) -> Result<JpegInfo, String> {
    if data.len() < 4 || data[0] != 0xff || data[1] != 0xd8 {
        return Err("invalid JPEG header".to_string());
    }

    let mut index = 2;
    while index + 3 < data.len() {
        while index < data.len() && data[index] != 0xff {
            index += 1;
        }
        while index < data.len() && data[index] == 0xff {
            index += 1;
        }
        if index >= data.len() {
            break;
        }

        let marker = data[index];
        index += 1;

        if marker == 0xd9 || marker == 0xda {
            break;
        }
        if marker == 0x01 || (0xd0..=0xd7).contains(&marker) {
            continue;
        }
        if index + 2 > data.len() {
            return Err("truncated JPEG segment".to_string());
        }

        let length = u16::from_be_bytes([data[index], data[index + 1]]) as usize;
        if length < 2 || index + length > data.len() {
            return Err("invalid JPEG segment length".to_string());
        }

        let segment_start = index + 2;
        if is_jpeg_start_of_frame(marker) {
            if length < 8 {
                return Err("invalid JPEG frame header".to_string());
            }

            let components = data[segment_start + 5];
            let color_space = match components {
                1 => "DeviceGray",
                3 => "DeviceRGB",
                4 => "DeviceCMYK",
                _ => return Err(format!("unsupported JPEG component count: {components}")),
            };

            return Ok(JpegInfo {
                bits_per_component: data[segment_start],
                height: u16::from_be_bytes([data[segment_start + 1], data[segment_start + 2]])
                    as u32,
                width: u16::from_be_bytes([data[segment_start + 3], data[segment_start + 4]])
                    as u32,
                color_space,
            });
        }

        index += length;
    }

    Err("JPEG dimensions not found".to_string())
}

fn is_jpeg_start_of_frame(marker: u8) -> bool {
    matches!(
        marker,
        0xc0 | 0xc1 | 0xc2 | 0xc3 | 0xc5 | 0xc6 | 0xc7 | 0xc9 | 0xca | 0xcb | 0xcd | 0xce | 0xcf
    )
}

struct PdfStreamWriter<W: Write> {
    writer: W,
    offsets: Vec<u64>,
    position: u64,
    next_object_id: usize,
    page_ids: Vec<usize>,
}

impl<W: Write> PdfStreamWriter<W> {
    fn new(writer: W) -> Result<Self, String> {
        let mut pdf = Self {
            writer,
            offsets: vec![0; 3],
            position: 0,
            next_object_id: 3,
            page_ids: Vec::new(),
        };
        pdf.write_bytes(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")?;
        Ok(pdf)
    }

    fn add_image_page(&mut self, image: ProcessedImage) -> Result<(), String> {
        let image_id = self.allocate_object_id();
        let content_id = self.allocate_object_id();
        let page_id = self.allocate_object_id();
        let image_name = format!("Im{}", self.page_ids.len() + 1);

        self.write_image_object(image_id, &image)?;
        self.write_content_object(content_id, &image_name, image.display_height)?;
        self.write_page_object(
            page_id,
            image_id,
            content_id,
            &image_name,
            image.display_height,
        )?;
        self.page_ids.push(page_id);

        Ok(())
    }

    fn finish(mut self) -> Result<(), String> {
        self.write_pages_object()?;
        self.write_catalog_object()?;

        let start_xref = self.position;
        let object_count = self.next_object_id;
        self.write_text(&format!("xref\n0 {object_count}\n"))?;
        self.write_text("0000000000 65535 f \n")?;

        for id in 1..object_count {
            self.write_text(&format!("{:010} 00000 n \n", self.offsets[id]))?;
        }

        self.write_text(&format!(
            "trailer\n<< /Size {object_count} /Root 1 0 R >>\nstartxref\n{start_xref}\n%%EOF\n"
        ))?;
        self.writer.flush().map_err(|e| e.to_string())
    }

    fn allocate_object_id(&mut self) -> usize {
        let id = self.next_object_id;
        self.next_object_id += 1;
        if self.offsets.len() <= id {
            self.offsets.resize(id + 1, 0);
        }
        id
    }

    fn write_image_object(&mut self, id: usize, image: &ProcessedImage) -> Result<(), String> {
        self.begin_object(id)?;
        self.write_text(&format!(
            "<< /Type /XObject /Subtype /Image /Width {} /Height {} /ColorSpace /{} /BitsPerComponent {} /Filter /DCTDecode /Length {} >>\nstream\n",
            image.width,
            image.height,
            image.color_space,
            image.bits_per_component,
            image.data.len()
        ))?;
        self.write_bytes(&image.data)?;
        self.write_text("\nendstream\nendobj\n")
    }

    fn write_content_object(
        &mut self,
        id: usize,
        image_name: &str,
        display_height: f64,
    ) -> Result<(), String> {
        let content = format!(
            "q\n{} 0 0 {} 0 0 cm\n/{} Do\nQ\n",
            pdf_number(PAGE_WIDTH),
            pdf_number(display_height),
            image_name
        );

        self.begin_object(id)?;
        self.write_text(&format!("<< /Length {} >>\nstream\n", content.len()))?;
        self.write_text(&content)?;
        self.write_text("endstream\nendobj\n")
    }

    fn write_page_object(
        &mut self,
        id: usize,
        image_id: usize,
        content_id: usize,
        image_name: &str,
        display_height: f64,
    ) -> Result<(), String> {
        self.begin_object(id)?;
        self.write_text(&format!(
            "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {} {}] /Resources << /XObject << /{} {} 0 R >> >> /Contents {} 0 R >>\nendobj\n",
            pdf_number(PAGE_WIDTH),
            pdf_number(display_height),
            image_name,
            image_id,
            content_id
        ))
    }

    fn write_pages_object(&mut self) -> Result<(), String> {
        self.begin_object(2)?;
        let kids = self
            .page_ids
            .iter()
            .map(|id| format!("{id} 0 R"))
            .collect::<Vec<_>>()
            .join(" ");
        self.write_text(&format!(
            "<< /Type /Pages /Kids [{}] /Count {} >>\nendobj\n",
            kids,
            self.page_ids.len()
        ))
    }

    fn write_catalog_object(&mut self) -> Result<(), String> {
        self.begin_object(1)?;
        self.write_text("<< /Type /Catalog /Pages 2 0 R >>\nendobj\n")
    }

    fn begin_object(&mut self, id: usize) -> Result<(), String> {
        if self.offsets.len() <= id {
            self.offsets.resize(id + 1, 0);
        }
        self.offsets[id] = self.position;
        self.write_text(&format!("{id} 0 obj\n"))
    }

    fn write_text(&mut self, text: &str) -> Result<(), String> {
        self.write_bytes(text.as_bytes())
    }

    fn write_bytes(&mut self, bytes: &[u8]) -> Result<(), String> {
        self.writer.write_all(bytes).map_err(|e| e.to_string())?;
        self.position += bytes.len() as u64;
        Ok(())
    }
}

fn pdf_number(value: f64) -> String {
    let mut text = format!("{value:.4}");
    while text.contains('.') && text.ends_with('0') {
        text.pop();
    }
    if text.ends_with('.') {
        text.pop();
    }

    text
}

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

#[cfg(test)]
mod tests {
    use super::*;
    use image::{ImageBuffer, ImageFormat, Rgb, Rgba};
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::time::{SystemTime, UNIX_EPOCH};

    fn temp_dir(name: &str) -> PathBuf {
        let stamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let dir = std::env::temp_dir().join(format!("haka_comic_{name}_{stamp}"));
        fs::create_dir_all(&dir).unwrap();
        dir
    }

    fn write_test_image(path: &Path, format: ImageFormat) {
        if format == ImageFormat::Jpeg {
            let img = ImageBuffer::from_fn(4, 3, |x, y| {
                if (x + y) % 2 == 0 {
                    Rgb([255u8, 0, 0])
                } else {
                    Rgb([0u8, 0, 255])
                }
            });
            img.save_with_format(path, format).unwrap();
            return;
        }

        let img = ImageBuffer::from_fn(4, 3, |x, y| {
            if (x + y) % 2 == 0 {
                Rgba([255u8, 0, 0, 255])
            } else {
                Rgba([0u8, 0, 255, 128])
            }
        });
        img.save_with_format(path, format).unwrap();
    }

    #[test]
    fn collect_images_uses_human_sort_order() {
        let dir = temp_dir("sort");
        fs::write(dir.join("10.jpg"), b"").unwrap();
        fs::write(dir.join("2.jpg"), b"").unwrap();
        fs::write(dir.join("1.txt"), b"").unwrap();

        let images = collect_images(dir.to_str().unwrap());
        let names = images
            .iter()
            .map(|path| Path::new(path).file_name().unwrap().to_str().unwrap())
            .collect::<Vec<_>>();

        assert_eq!(names, vec!["2.jpg", "10.jpg"]);

        fs::remove_dir_all(dir).unwrap();
    }

    #[test]
    fn export_pdf_embeds_all_supported_images_as_jpeg_streams() {
        let dir = temp_dir("export");
        let jpeg_path = dir.join("1.jpg");
        let png_path = dir.join("2.png");
        let pdf_path = dir.join("out.pdf");

        write_test_image(&jpeg_path, ImageFormat::Jpeg);
        write_test_image(&png_path, ImageFormat::Png);

        export_pdf(dir.to_str().unwrap(), pdf_path.to_str().unwrap()).unwrap();

        let pdf = fs::read(&pdf_path).unwrap();
        let pdf_text = String::from_utf8_lossy(&pdf);
        let image_stream_count = pdf_text.matches("/Subtype /Image").count();
        let dct_decode_count = pdf_text.matches("/Filter /DCTDecode").count();

        assert_eq!(image_stream_count, 2);
        assert_eq!(dct_decode_count, 2);
        assert!(!pdf.windows(8).any(|window| window == b"\x89PNG\r\n\x1a\n"));
        assert!(pdf.ends_with(b"%%EOF\n"));

        fs::remove_dir_all(dir).unwrap();
    }
}
