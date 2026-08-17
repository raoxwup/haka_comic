use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize)]
pub struct Image {
    #[serde(rename = "fileServer")]
    file_server: String,
    path: String,
    #[serde(rename = "originalName")]
    original_name: String,
}

impl Image {
    pub fn url(&self, is_proxy: bool) -> String {
        if is_proxy {
            self.proxy_url()
        } else {
            self.direct_url()
        }
    }

    // 直连url
    fn direct_url(&self) -> String {
        format!("{}/static/{}", self.file_server, self.path)
    }

    // CND代理url
    fn proxy_url(&self) -> String {
        self.direct_url().replace("picacomic", "go2778")
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ChapterImage {
    _id: String,
    media: Image,
}
