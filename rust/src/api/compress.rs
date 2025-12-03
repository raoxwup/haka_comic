use std::fs::File;
use std::path::Path;
use walkdir::WalkDir;
pub use zip::CompressionMethod;
use zip::{
    write::{FileOptions, ZipWriter},
    ZipArchive,
};

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

pub struct Zipper {
    writer: ZipWriter<File>,
    options: FileOptions<'static, ()>,
}

pub fn create_zipper(
    zip_path: String,
    compression_method: CompressionMethod,
) -> Result<Zipper, String> {
    let file = File::create(&zip_path).map_err(|e| e.to_string())?;
    let writer = ZipWriter::new(file);

    let options = FileOptions::default().compression_method(compression_method);

    Ok(Zipper { writer, options })
}

impl Zipper {
    /// 添加单个文件（会自动保留相对路径结构）
    pub fn add_file(
        &mut self,
        file_path: String,
        path_in_zip: Option<String>,
    ) -> Result<(), String> {
        let path = Path::new(&file_path);
        if !path.is_file() {
            return Err(format!("Not a file: {}", file_path));
        }

        let name_in_zip = match path_in_zip {
            Some(name) => name,
            None => path.file_name().unwrap().to_string_lossy().into_owned(),
        };

        self.writer
            .start_file(name_in_zip.clone(), self.options)
            .map_err(|e| format!("start_file {}: {}", name_in_zip, e))?;

        let mut f = File::open(path).map_err(|e| e.to_string())?;
        std::io::copy(&mut f, &mut self.writer).map_err(|e| e.to_string())?;

        Ok(())
    }

    /// 添加整个目录（递归，所有文件都会被加入）
    pub fn add_directory(&mut self, dir_path: String) -> Result<(), String> {
        let root = Path::new(&dir_path);
        if !root.is_dir() {
            return Err(format!("Not a directory: {}", dir_path));
        }

        let root_name = root
            .file_name()
            .ok_or("Invalid directory name")?
            .to_string_lossy()
            .to_string();

        for entry in walkdir::WalkDir::new(&root) {
            let entry = entry.map_err(|e| e.to_string())?;
            let path = entry.path();

            // 处理目录：目录也要写入 zip（并以 / 结尾）
            if path.is_dir() {
                let relative = path
                    .strip_prefix(root)
                    .map_err(|_| "strip_prefix failed for dir")?;

                let name_in_zip = if relative.as_os_str().is_empty() {
                    // 根目录
                    format!("{}/", root_name)
                } else {
                    format!(
                        "{}/{}/",
                        root_name,
                        relative.to_string_lossy().replace('\\', "/")
                    )
                };

                self.writer
                    .add_directory(name_in_zip, self.options)
                    .map_err(|e| format!("add_directory: {}", e))?;

                continue;
            }

            // 处理文件
            if path.is_file() {
                let relative = path
                    .strip_prefix(root)
                    .map_err(|_| "strip_prefix failed for file")?;

                let name_in_zip = format!(
                    "{}/{}",
                    root_name,
                    relative.to_string_lossy().replace('\\', "/")
                );

                self.writer
                    .start_file(name_in_zip.clone(), self.options)
                    .map_err(|e| format!("start_file {}: {}", name_in_zip, e))?;

                let mut f = File::open(path).map_err(|e| e.to_string())?;
                std::io::copy(&mut f, &mut self.writer)
                    .map_err(|e| format!("copy {}: {}", name_in_zip, e))?;
            }
        }

        Ok(())
    }

    pub fn add_empty_directory(&mut self, dir_name: String) -> Result<(), String> {
        let name = if dir_name.ends_with('/') {
            dir_name
        } else {
            format!("{}/", dir_name)
        };
        self.writer
            .add_directory(name, self.options)
            .map_err(|e| e.to_string())
    }

    pub fn close(self) -> Result<(), String> {
        self.writer.finish().map_err(|e| e.to_string())?;
        Ok(())
    }
}
