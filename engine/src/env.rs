//! Environment knobs: KIRARA_<KEY>, with the pre-rename JPQUIZ_<KEY> still accepted.
use std::ffi::OsString;

pub fn var_os(key: &str) -> Option<OsString> {
    std::env::var_os(format!("KIRARA_{key}")).or_else(|| std::env::var_os(format!("JPQUIZ_{key}")))
}

pub fn var(key: &str) -> Result<String, std::env::VarError> {
    std::env::var(format!("KIRARA_{key}")).or_else(|_| std::env::var(format!("JPQUIZ_{key}")))
}
