use std::time::{SystemTime, UNIX_EPOCH};

use hmac::{Hmac, Mac};
pub use reqwest::header::InvalidHeaderValue;
pub use reqwest::{
    header::{HeaderMap, HeaderValue, ACCEPT, AUTHORIZATION, CONTENT_TYPE, USER_AGENT},
    Method,
};
use sha2::Sha256;

const API_KEY: &str = "C69BAF41DA5ABD1FFEDC6D2FEA56B";
const SECRET_KEY: &str = r#"~d}$Q7$eIni=V)9\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn"#;
const NONCE: &str = "4ce7a7aa759b40f794d189a88b84aba8";

pub struct Client {
    pub token: String,
    pub base_url: String,
}

impl Client {
    pub fn new(token: String, base_url: String) -> Self {
        Self { token, base_url }
    }

    pub fn set_base_url(&self, base_url: String) -> Self {
        self.base_url = base_url;
        self
    }

    pub fn create_headers(
        url: &str,
        method: &Method,
        authorization: &str,
        image_quality: &str,
    ) -> Result<HeaderMap, InvalidHeaderValue> {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs()
            .to_string();

        Self::create_headers_at(url, method, authorization, image_quality, &timestamp)
    }

    fn create_headers_at(
        url: &str,
        method: &Method,
        authorization: &str,
        image_quality: &str,
        timestamp: &str,
    ) -> Result<HeaderMap, reqwest::header::InvalidHeaderValue> {
        let signature = Self::get_signature(url, timestamp, method);
        let mut headers = HeaderMap::new();

        headers.insert(
            ACCEPT,
            HeaderValue::from_static("application/vnd.picacomic.com.v1+json"),
        );
        headers.insert(USER_AGENT, HeaderValue::from_static("okhttp/3.8.1"));
        headers.insert(
            CONTENT_TYPE,
            HeaderValue::from_static("application/json; charset=UTF-8"),
        );
        headers.insert("api-key", HeaderValue::from_static(API_KEY));
        headers.insert("app-build-version", HeaderValue::from_static("45"));
        headers.insert("app-platform", HeaderValue::from_static("android"));
        headers.insert("app-uuid", HeaderValue::from_static("defaultUuid"));
        headers.insert("app-version", HeaderValue::from_static("2.2.1.3.3.4"));
        headers.insert("nonce", HeaderValue::from_static(NONCE));
        headers.insert("app-channel", HeaderValue::from_static("1"));
        headers.insert("time", HeaderValue::from_str(timestamp)?);
        headers.insert("signature", HeaderValue::from_str(&signature)?);
        headers.insert(AUTHORIZATION, HeaderValue::from_str(authorization)?);
        headers.insert("image-quality", HeaderValue::from_str(image_quality)?);

        Ok(headers)
    }

    fn get_signature(url: &str, timestamp: &str, method: &Method) -> String {
        let key = format!("{url}{timestamp}{NONCE}{}{API_KEY}", method.as_str()).to_lowercase();
        let mut mac = Hmac::<Sha256>::new_from_slice(SECRET_KEY.as_bytes())
            .expect("HMAC accepts keys of any size");
        mac.update(key.as_bytes());
        hex::encode(mac.finalize().into_bytes())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn creates_the_same_headers_as_dart() {
        let headers = Client::create_headers_at(
            "comics/123/order/1/pages?page=2",
            &Method::GET,
            "test-token",
            "original",
            "1700000000",
        )
        .unwrap();

        assert_eq!(headers.len(), 14);
        assert_eq!(headers["authorization"], "test-token");
        assert_eq!(headers["image-quality"], "original");
        assert_eq!(headers["time"], "1700000000");
        assert_eq!(
            headers["signature"],
            "c24ac6edef82b597aa8762ee6476674d12b5f8a29f193343e232122d02e63561"
        );
    }
}
