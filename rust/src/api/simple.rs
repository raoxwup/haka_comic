use std::fs::File;
use std::path::Path;
use walkdir::WalkDir;
use zip::{
    write::{FileOptions, ZipWriter},
    CompressionMethod, ZipArchive,
};

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

// 压缩文件夹
pub fn compress_folder(source_folder: &str, output_zip: &str, method: &str) -> Result<(), String> {
    let method = match method {
        "Stored" => CompressionMethod::Stored,
        "Deflated" => CompressionMethod::Deflated,
        "Bzip2" => CompressionMethod::Bzip2,
        "Zstd" => CompressionMethod::Zstd,
        _ => return Err(format!("Unsupported compression method: {}", method)),
    };

    let path = Path::new(source_folder);

    if !path.is_dir() {
        return Err(format!(
            "Source folder '{}' is not a directory",
            source_folder
        ));
    }

    let file = File::create(output_zip).map_err(|e| e.to_string())?;
    let mut zip = ZipWriter::new(file);

    let options: FileOptions<'_, ()> = FileOptions::default().compression_method(method);

    for entry in WalkDir::new(source_folder) {
        let entry = entry.map_err(|e| e.to_string())?;
        let entry_path = entry.path();

        // 跳过输出的zip文件本身
        if entry_path == Path::new(output_zip) {
            continue;
        }

        let relative_path = entry_path
            .strip_prefix(source_folder)
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
pub fn decompress_folder(zip_file: &str, output_folder: &str) -> Result<(), String> {
    let file = File::open(zip_file).map_err(|e| e.to_string())?;
    let mut archive = ZipArchive::new(file).map_err(|e| e.to_string())?;

    for i in 0..archive.len() {
        let mut file = archive.by_index(i).map_err(|e| e.to_string())?;
        let outpath = Path::new(output_folder).join(file.mangled_name());

        if (*file.name()).ends_with('/') {
            std::fs::create_dir_all(&outpath).map_err(|e| e.to_string())?;
        } else {
            if let Some(p) = outpath.parent() {
                if !p.exists() {
                    std::fs::create_dir_all(&p).map_err(|e| e.to_string())?;
                }
            }
            let mut outfile = File::create(&outpath).map_err(|e| e.to_string())?;
            std::io::copy(&mut file, &mut outfile).map_err(|e| e.to_string())?;
        }
    }

    Ok(())
}
