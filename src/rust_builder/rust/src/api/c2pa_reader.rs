use c2pa::{Reader, assertions::{Actions, SoftwareAgent}};
use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::fs::File;
use std::io::{BufReader, Seek, SeekFrom};
use std::path::Path;
use exif::{In, Tag};

// Helper function to convert CBOR Value to JSON Value
fn cbor_to_json(cbor_val: &serde_cbor::Value) -> Option<serde_json::Value> {
    match cbor_val {
        serde_cbor::Value::Null => Some(serde_json::Value::Null),
        serde_cbor::Value::Bool(b) => Some(serde_json::Value::Bool(*b)),
        serde_cbor::Value::Integer(i) => {
            // CBOR uses i128, but JSON numbers typically use i64/f64
            if let Ok(i64_val) = i64::try_from(*i) {
                Some(serde_json::Value::Number(i64_val.into()))
            } else {
                // For very large integers, represent as string
                Some(serde_json::Value::String(i.to_string()))
            }
        }
        serde_cbor::Value::Float(f) => {
            serde_json::Number::from_f64(*f).map(serde_json::Value::Number)
        }
        serde_cbor::Value::Text(s) => Some(serde_json::Value::String(s.clone())),
        serde_cbor::Value::Bytes(b) => {
            // Convert bytes to string representation
            Some(serde_json::Value::String(format!("<{} bytes>", b.len())))
        }
        serde_cbor::Value::Array(arr) => {
            let json_arr: Vec<serde_json::Value> = arr
                .iter()
                .filter_map(cbor_to_json)
                .collect();
            Some(serde_json::Value::Array(json_arr))
        }
        serde_cbor::Value::Map(map) => {
            let json_map: serde_json::Map<String, serde_json::Value> = map
                .iter()
                .filter_map(|(k, v)| {
                    // CBOR map keys can be various types, convert to string
                    let key = match k {
                        serde_cbor::Value::Text(s) => Some(s.clone()),
                        serde_cbor::Value::Integer(i) => Some(i.to_string()),
                        _ => None,
                    };
                    key.and_then(|k| cbor_to_json(v).map(|v| (k, v)))
                })
                .collect();
            Some(serde_json::Value::Object(json_map))
        }
        _ => None,
    }
}

// Helper function to convert SoftwareAgent to String
fn software_agent_to_string(agent: &SoftwareAgent) -> String {
    match agent {
        SoftwareAgent::String(s) => s.clone(),
        SoftwareAgent::ClaimGeneratorInfo(info) => info.name.clone(),
    }
}

// Known AI generator identifiers - comprehensive list
const AI_GENERATORS: &[&str] = &[
    // Image generators
    "midjourney",
    "dall-e",
    "dalle",
    "dall·e",
    "stable diffusion",
    "stability.ai",
    "stability ai",
    "firefly",
    "adobe firefly",
    "imagen",
    "openai",
    "runway",
    "runwayml",
    "leonardo.ai",
    "leonardo ai",
    "bing image creator",
    "bing image",
    "copilot",
    "microsoft designer",
    "nightcafe",
    "artbreeder",
    "jasper art",
    "dreamstudio",
    "craiyon",
    "deep dream",
    "starryai",
    "wombo",
    "pixlr",
    "canva ai",
    "fotor ai",
    "ideogram",
    "bluewillow",
    "playground ai",
    "lexica",
    "invoke ai",
    "automatic1111",
    "comfyui",
    "fooocus",
    // Video generators
    "sora",
    "pika labs",
    "pika",
    "gen-2",
    "gen-3",
    "kaiber",
    "synthesia",
    "heygen",
    "d-id",
    "luma ai",
    "luma dream machine",
    // Audio generators
    "elevenlabs",
    "murf",
    "resemble ai",
    "descript",
    // General AI/ML indicators
    "generative ai",
    "ai generated",
    "ai-generated",
    "machine learning",
    "neural network",
    "diffusion model",
    "text-to-image",
    "text to image",
    "t2i",
    "img2img",
    // Google AI
    "google ai",
    "gemini",
    "bard",
    "vertex ai",
    "synthid",
];

// C2PA digital source types that indicate AI generation
// Only include types that SPECIFICALLY indicate trained/algorithmic AI generation
// See: https://cv.iptc.org/newscodes/digitalsourcetype/
const AI_DIGITAL_SOURCE_TYPES: &[&str] = &[
    "http://cv.iptc.org/newscodes/digitalsourcetype/trainedAlgorithmicMedia",
    "http://cv.iptc.org/newscodes/digitalsourcetype/compositeWithTrainedAlgorithmicMedia",
    "trainedAlgorithmicMedia",
    "compositeWithTrainedAlgorithmicMedia",
    // Note: "algorithmicMedia" alone is ambiguous - could be filters/effects
    // Note: "digitalArt" is NOT AI - it's manually created digital artwork
];

/// Verification status of a C2PA manifest
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum VerificationStatus {
    Verified,
    SignatureInvalid,
    CertificateExpired,
    CertificateUntrusted,
    NoManifest,
    Error { message: String },
}

/// Information about the content signer
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SignerInfo {
    pub name: Option<String>,
    pub organization: Option<String>,
    pub issued_by: Option<String>,
    pub timestamp: Option<String>,
}

/// A single action in the content's edit history
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentAction {
    pub action: String,
    pub software_agent: Option<String>,
    pub when: Option<String>,
    pub description: Option<String>,
    /// Parameters specific to this action (e.g., for color_adjustments: Exposure2012, Blacks2012, etc.)
    pub parameters: Option<String>,
    /// Reason for this action (C2PA v2)
    pub reason: Option<String>,
    /// Digital source type (e.g., trainedAlgorithmicMedia for AI)
    pub source_type: Option<String>,
}

/// AI generation information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiInfo {
    pub is_ai_generated: bool,
    pub generator_name: Option<String>,
    pub model_name: Option<String>,
    pub detection_source: Option<String>, // "c2pa", "exif", or "both"
    /// Set when the manifest itself attests that an invisible watermark was
    /// inserted, via a `c2pa.watermarked` action or a `c2pa.soft-binding`
    /// assertion. This is a signed claim carried by the manifest, not a pixel
    /// decode: Origin Lens reads the attestation, it does not read a watermark.
    pub watermark_declared: bool,
}

/// EXIF metadata result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExifInfo {
    pub software: Option<String>,
    pub make: Option<String>,
    pub model: Option<String>,
    pub artist: Option<String>,
    pub copyright: Option<String>,
    pub user_comment: Option<String>,
    pub image_description: Option<String>,
    pub date_time_original: Option<String>,
    pub ai_detected: bool,
    pub ai_generator: Option<String>,
}

/// The full C2PA analysis result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct C2paAnalysisResult {
    pub status: VerificationStatus,
    pub signer: Option<SignerInfo>,
    pub actions: Vec<ContentAction>,
    pub ai_info: Option<AiInfo>,
    pub exif_info: Option<ExifInfo>,
    pub claim_generator: Option<String>,
    pub title: Option<String>,
    pub format: Option<String>,
    pub instance_id: Option<String>,
    pub raw_manifest_json: Option<String>,
}

impl C2paAnalysisResult {
    fn no_manifest() -> Self {
        C2paAnalysisResult {
            status: VerificationStatus::NoManifest,
            signer: None,
            actions: vec![],
            ai_info: None,
            exif_info: None,
            claim_generator: None,
            title: None,
            format: None,
            instance_id: None,
            raw_manifest_json: None,
        }
    }

    fn no_manifest_with_exif(exif: ExifInfo) -> Self {
        let ai_info = if exif.ai_detected {
            Some(AiInfo {
                is_ai_generated: true,
                generator_name: exif.ai_generator.clone(),
                model_name: None,
                detection_source: Some("exif".to_string()),
                watermark_declared: false,
            })
        } else {
            None
        };
        
        C2paAnalysisResult {
            status: VerificationStatus::NoManifest,
            signer: None,
            actions: vec![],
            ai_info,
            exif_info: Some(exif),
            claim_generator: None,
            title: None,
            format: None,
            instance_id: None,
            raw_manifest_json: None,
        }
    }

    fn error(message: String) -> Self {
        C2paAnalysisResult {
            status: VerificationStatus::Error { message },
            signer: None,
            actions: vec![],
            ai_info: None,
            exif_info: None,
            claim_generator: None,
            title: None,
            format: None,
            instance_id: None,
            raw_manifest_json: None,
        }
    }
}

/// Parse EXIF metadata from a file and detect AI generators
fn parse_exif_from_file(file_path: &Path) -> Option<ExifInfo> {
    let file = File::open(file_path).ok()?;
    let mut bufreader = BufReader::new(&file);
    let exifreader = exif::Reader::new();
    let exif = exifreader.read_from_container(&mut bufreader).ok()?;
    
    let get_field = |tag: Tag| -> Option<String> {
        exif.get_field(tag, In::PRIMARY)
            .map(|f| f.display_value().with_unit(&exif).to_string())
    };
    
    let software = get_field(Tag::Software);
    let make = get_field(Tag::Make);
    let model = get_field(Tag::Model);
    let artist = get_field(Tag::Artist);
    let copyright = get_field(Tag::Copyright);
    let user_comment = get_field(Tag::UserComment);
    let image_description = get_field(Tag::ImageDescription);
    let date_time_original = get_field(Tag::DateTimeOriginal);
    
    // Check all text fields for AI generator signatures
    let all_text = [
        &software,
        &make,
        &model,
        &artist,
        &user_comment,
        &image_description,
    ]
    .iter()
    .filter_map(|o| o.as_ref())
    .map(|s| s.to_lowercase())
    .collect::<Vec<_>>()
    .join(" ");
    
    let mut ai_detected = false;
    let mut ai_generator: Option<String> = None;
    
    for gen in AI_GENERATORS {
        if all_text.contains(gen) {
            ai_detected = true;
            ai_generator = Some(gen.to_string());
            break;
        }
    }
    
    // Check for specific EXIF patterns that indicate AI generation
    if let Some(ref sw) = software {
        let sw_lower = sw.to_lowercase();
        // Check for known AI tools in Software field
        if sw_lower.contains("midjourney") 
            || sw_lower.contains("dall-e") 
            || sw_lower.contains("stable diffusion")
            || sw_lower.contains("firefly")
            || sw_lower.contains("imagen")
            || sw_lower.contains("novelai")
            || sw_lower.contains("automatic1111")
            || sw_lower.contains("comfyui")
        {
            ai_detected = true;
            ai_generator = Some(sw.clone());
        }
    }
    
    // Check UserComment for AI indicators (common in some AI-generated images)
    if let Some(ref comment) = user_comment {
        let comment_lower = comment.to_lowercase();
        if comment_lower.contains("generated by ai")
            || comment_lower.contains("ai generated")
            || comment_lower.contains("created with ai")
            || comment_lower.contains("made with ai")
            || comment_lower.contains("prompt:")
            || comment_lower.contains("negative prompt:")
            || comment_lower.contains("cfg scale")
            || comment_lower.contains("sampling steps")
            || comment_lower.contains("seed:")
        {
            ai_detected = true;
            if ai_generator.is_none() {
                ai_generator = Some("AI Generator (from metadata)".to_string());
            }
        }
    }
    
    Some(ExifInfo {
        software,
        make,
        model,
        artist,
        copyright,
        user_comment,
        image_description,
        date_time_original,
        ai_detected,
        ai_generator,
    })
}

/// Parse EXIF metadata from bytes
fn parse_exif_from_bytes(data: &[u8]) -> Option<ExifInfo> {
    let exifreader = exif::Reader::new();
    let exif = exifreader.read_raw(data.to_vec()).ok()?;
    
    let get_field = |tag: Tag| -> Option<String> {
        exif.get_field(tag, In::PRIMARY)
            .map(|f| f.display_value().with_unit(&exif).to_string())
    };
    
    let software = get_field(Tag::Software);
    let make = get_field(Tag::Make);
    let model = get_field(Tag::Model);
    let artist = get_field(Tag::Artist);
    let copyright = get_field(Tag::Copyright);
    let user_comment = get_field(Tag::UserComment);
    let image_description = get_field(Tag::ImageDescription);
    let date_time_original = get_field(Tag::DateTimeOriginal);
    
    // Check all text fields for AI generator signatures
    let all_text = [
        &software,
        &make,
        &model,
        &artist,
        &user_comment,
        &image_description,
    ]
    .iter()
    .filter_map(|o| o.as_ref())
    .map(|s| s.to_lowercase())
    .collect::<Vec<_>>()
    .join(" ");
    
    let mut ai_detected = false;
    let mut ai_generator: Option<String> = None;
    
    for gen in AI_GENERATORS {
        if all_text.contains(gen) {
            ai_detected = true;
            ai_generator = Some(gen.to_string());
            break;
        }
    }
    
    if let Some(ref sw) = software {
        let sw_lower = sw.to_lowercase();
        if sw_lower.contains("midjourney") 
            || sw_lower.contains("dall-e") 
            || sw_lower.contains("stable diffusion")
            || sw_lower.contains("firefly")
            || sw_lower.contains("imagen")
            || sw_lower.contains("novelai")
            || sw_lower.contains("automatic1111")
            || sw_lower.contains("comfyui")
        {
            ai_detected = true;
            ai_generator = Some(sw.clone());
        }
    }
    
    if let Some(ref comment) = user_comment {
        let comment_lower = comment.to_lowercase();
        if comment_lower.contains("generated by ai")
            || comment_lower.contains("ai generated")
            || comment_lower.contains("created with ai")
            || comment_lower.contains("made with ai")
            || comment_lower.contains("prompt:")
            || comment_lower.contains("negative prompt:")
            || comment_lower.contains("cfg scale")
            || comment_lower.contains("sampling steps")
            || comment_lower.contains("seed:")
        {
            ai_detected = true;
            if ai_generator.is_none() {
                ai_generator = Some("AI Generator (from metadata)".to_string());
            }
        }
    }
    
    Some(ExifInfo {
        software,
        make,
        model,
        artist,
        copyright,
        user_comment,
        image_description,
        date_time_original,
        ai_detected,
        ai_generator,
    })
}

/// Analyzes a file at the given path for C2PA metadata
#[frb(sync)]
pub fn analyze_c2pa_from_path(file_path: String) -> C2paAnalysisResult {
    let path = Path::new(&file_path);

    if !path.exists() {
        return C2paAnalysisResult::error(format!("File not found: {}", file_path));
    }

    let file = match File::open(path) {
        Ok(f) => f,
        Err(e) => return C2paAnalysisResult::error(format!("Failed to open file: {}", e)),
    };

    let reader = BufReader::new(file);

    // Determine format from extension
    let format = path
        .extension()
        .and_then(|ext| ext.to_str())
        .map(|ext| match ext.to_lowercase().as_str() {
            "jpg" | "jpeg" => "image/jpeg",
            "png" => "image/png",
            "webp" => "image/webp",
            "gif" => "image/gif",
            "avif" => "image/avif",
            "heic" | "heif" => "image/heif",
            "tif" | "tiff" => "image/tiff",
            "mp4" => "video/mp4",
            "mov" => "video/quicktime",
            _ => "application/octet-stream",
        })
        .unwrap_or("application/octet-stream");

    match Reader::from_stream(format, reader) {
        Ok(manifest_reader) => {
            let mut result = parse_manifest_reader(&manifest_reader);
            // Also parse EXIF and merge AI detection
            if let Some(exif_info) = parse_exif_from_file(path) {
                // Merge EXIF AI detection with C2PA AI detection
                if exif_info.ai_detected {
                    if let Some(ref mut ai_info) = result.ai_info {
                        // Already detected via C2PA, add EXIF as secondary source
                        if ai_info.detection_source == Some("c2pa".to_string()) {
                            ai_info.detection_source = Some("both".to_string());
                        }
                        if ai_info.generator_name.is_none() {
                            ai_info.generator_name = exif_info.ai_generator.clone();
                        }
                    } else {
                        // Not detected via C2PA, use EXIF detection
                        result.ai_info = Some(AiInfo {
                            is_ai_generated: true,
                            generator_name: exif_info.ai_generator.clone(),
                            model_name: None,
                            detection_source: Some("exif".to_string()),
                            watermark_declared: false,
                        });
                    }
                }
                result.exif_info = Some(exif_info);
            }
            result
        }
        Err(e) => {
            let error_msg = e.to_string().to_lowercase();
            // Check for various "no manifest" conditions
            if error_msg.contains("not found")
                || error_msg.contains("jumbfnotfound")
                || error_msg.contains("no manifest")
                || error_msg.contains("jumbf")
            {
                // No C2PA manifest, but still parse EXIF
                if let Some(exif_info) = parse_exif_from_file(path) {
                    C2paAnalysisResult::no_manifest_with_exif(exif_info)
                } else {
                    C2paAnalysisResult::no_manifest()
                }
            } 
            // CBOR parsing errors often mean corrupted or incompatible manifest
            else if error_msg.contains("cbor") 
                || error_msg.contains("claim could not be")
                || error_msg.contains("deserialization")
                || error_msg.contains("invalid")
            {
                // Parse EXIF even on C2PA error
                let exif_info = parse_exif_from_file(path);
                C2paAnalysisResult {
                    status: VerificationStatus::Error { 
                        message: "This image contains C2PA data that could not be parsed. It may be corrupted or use an unsupported format.".to_string() 
                    },
                    signer: None,
                    actions: vec![],
                    ai_info: exif_info.as_ref().filter(|e| e.ai_detected).map(|e| AiInfo {
                        is_ai_generated: true,
                        generator_name: e.ai_generator.clone(),
                        model_name: None,
                        detection_source: Some("exif".to_string()),
                        watermark_declared: false,
                    }),
                    exif_info,
                    claim_generator: None,
                    title: None,
                    format: None,
                    instance_id: None,
                    raw_manifest_json: None,
                }
            }
            else {
                C2paAnalysisResult::error(e.to_string())
            }
        }
    }
}

/// Analyzes raw bytes for C2PA metadata
#[frb(sync)]
pub fn analyze_c2pa_from_bytes(data: Vec<u8>, mime_type: String) -> C2paAnalysisResult {
    let data_clone = data.clone();
    
    // First try synchronous parsing
    let cursor = std::io::Cursor::new(data.clone());
    match Reader::from_stream(&mime_type, cursor) {
        Ok(manifest_reader) => {
            let mut result = parse_manifest_reader(&manifest_reader);
            // Also parse EXIF and merge AI detection
            if let Some(exif_info) = parse_exif_from_bytes(&data_clone) {
                // Merge EXIF AI detection with C2PA AI detection
                if exif_info.ai_detected {
                    if let Some(ref mut ai_info) = result.ai_info {
                        // Already detected via C2PA, add EXIF as secondary source
                        if ai_info.detection_source == Some("c2pa".to_string()) {
                            ai_info.detection_source = Some("both".to_string());
                        }
                        if ai_info.generator_name.is_none() {
                            ai_info.generator_name = exif_info.ai_generator.clone();
                        }
                    } else {
                        // Not detected via C2PA, use EXIF detection
                        result.ai_info = Some(AiInfo {
                            is_ai_generated: true,
                            generator_name: exif_info.ai_generator.clone(),
                            model_name: None,
                            detection_source: Some("exif".to_string()),
                            watermark_declared: false,
                        });
                    }
                }
                result.exif_info = Some(exif_info);
            }
            result
        }
        Err(e) => {
            let error_msg = e.to_string().to_lowercase();
            
            // Check if remote manifest fetching is needed
            if error_msg.contains("remote manifest") || error_msg.contains("fetch") {
                // Try async version which supports remote manifest fetching
                // Create a tokio runtime for async operations
                match tokio::runtime::Runtime::new() {
                    Ok(rt) => {
                        let data_for_async = data.clone();
                        let mime_for_async = mime_type.clone();
                        let result = rt.block_on(async {
                            let cursor = std::io::Cursor::new(data_for_async);
                            match Reader::from_stream_async(&mime_for_async, cursor).await {
                                Ok(manifest_reader) => {
                                    let mut result = parse_manifest_reader(&manifest_reader);
                                    if let Some(exif_info) = parse_exif_from_bytes(&data_clone) {
                                        if exif_info.ai_detected {
                                            if let Some(ref mut ai_info) = result.ai_info {
                                                if ai_info.detection_source == Some("c2pa".to_string()) {
                                                    ai_info.detection_source = Some("both".to_string());
                                                }
                                                if ai_info.generator_name.is_none() {
                                                    ai_info.generator_name = exif_info.ai_generator.clone();
                                                }
                                            } else {
                                                result.ai_info = Some(AiInfo {
                                                    is_ai_generated: true,
                                                    generator_name: exif_info.ai_generator.clone(),
                                                    model_name: None,
                                                    detection_source: Some("exif".to_string()),
                                                    watermark_declared: false,
                                                });
                                            }
                                        }
                                        result.exif_info = Some(exif_info);
                                    }
                                    result
                                }
                                Err(async_e) => {
                                    let async_error_msg = async_e.to_string().to_lowercase();
                                    if async_error_msg.contains("not found")
                                        || async_error_msg.contains("jumbfnotfound")
                                        || async_error_msg.contains("no manifest")
                                        || async_error_msg.contains("jumbf")
                                    {
                                        if let Some(exif_info) = parse_exif_from_bytes(&data_clone) {
                                            C2paAnalysisResult::no_manifest_with_exif(exif_info)
                                        } else {
                                            C2paAnalysisResult::no_manifest()
                                        }
                                    } else {
                                        C2paAnalysisResult::error(async_e.to_string())
                                    }
                                }
                            }
                        });
                        return result;
                    }
                    Err(rt_e) => {
                        return C2paAnalysisResult::error(format!("Failed to create async runtime: {}", rt_e));
                    }
                }
            }
            
            // Check for various "no manifest" conditions
            if error_msg.contains("not found")
                || error_msg.contains("jumbfnotfound")
                || error_msg.contains("no manifest")
                || error_msg.contains("jumbf")
            {
                // No C2PA manifest, but still parse EXIF
                if let Some(exif_info) = parse_exif_from_bytes(&data_clone) {
                    C2paAnalysisResult::no_manifest_with_exif(exif_info)
                } else {
                    C2paAnalysisResult::no_manifest()
                }
            } 
            // CBOR parsing errors often mean corrupted or incompatible manifest
            else if error_msg.contains("cbor") 
                || error_msg.contains("claim could not be")
                || error_msg.contains("deserialization")
                || error_msg.contains("invalid")
            {
                // Parse EXIF even on C2PA error
                let exif_info = parse_exif_from_bytes(&data_clone);
                C2paAnalysisResult {
                    status: VerificationStatus::Error { 
                        message: "This image contains C2PA data that could not be parsed. It may be corrupted or use an unsupported format.".to_string() 
                    },
                    signer: None,
                    actions: vec![],
                    ai_info: exif_info.as_ref().filter(|e| e.ai_detected).map(|e| AiInfo {
                        is_ai_generated: true,
                        generator_name: e.ai_generator.clone(),
                        model_name: None,
                        detection_source: Some("exif".to_string()),
                        watermark_declared: false,
                    }),
                    exif_info,
                    claim_generator: None,
                    title: None,
                    format: None,
                    instance_id: None,
                    raw_manifest_json: None,
                }
            }
            else {
                C2paAnalysisResult::error(e.to_string())
            }
        }
    }
}

/// Extract a field from a certificate distinguished name string
/// e.g., "CN=Name, O=Organization, C=US" -> extract_cert_field(s, "O=") returns "Organization"
fn extract_cert_field(dn: &str, field_prefix: &str) -> Option<String> {
    // Handle both comma-separated and slash-separated DNs
    let parts: Vec<&str> = if dn.contains(',') {
        dn.split(',').collect()
    } else if dn.contains('/') {
        dn.split('/').collect()
    } else {
        vec![dn]
    };
    
    for part in parts {
        let trimmed = part.trim();
        if trimmed.starts_with(field_prefix) {
            let value = trimmed[field_prefix.len()..].trim();
            // Remove quotes if present
            let cleaned = value.trim_matches('"').trim_matches('\'');
            if !cleaned.is_empty() {
                return Some(cleaned.to_string());
            }
        }
    }
    None
}

fn parse_manifest_reader(reader: &Reader) -> C2paAnalysisResult {
    let manifest = match reader.active_manifest() {
        Some(m) => m,
        None => return C2paAnalysisResult::no_manifest(),
    };

    // Parse signer info with improved extraction
    let signer = manifest.signature_info().map(|sig| {
        // Try to extract organization from issuer string
        // Common formats: "CN=Name, O=Organization, C=Country"
        let organization = sig.issuer.as_ref().and_then(|issuer| {
            extract_cert_field(issuer, "O=")
                .or_else(|| extract_cert_field(issuer, "OU="))
        });
        
        // Extract common name for display
        let name = sig.issuer.as_ref().and_then(|issuer| {
            extract_cert_field(issuer, "CN=")
        }).or_else(|| sig.issuer.clone());

        SignerInfo {
            name,
            organization,
            issued_by: sig.issuer.clone(),
            timestamp: sig.time.clone(),
        }
    });

    // Parse actions - get them from assertions
    let mut actions = Vec::new();
    if let Ok(action_assertions) = manifest.find_assertion::<Actions>(Actions::LABEL) {
        for action in action_assertions.actions() {
            // Convert parameters HashMap to JSON string for easier handling in Dart
            let params_json = action.parameters().and_then(|params| {
                if params.is_empty() {
                    None
                } else {
                    // Convert CBOR values to serde_json Value for serialization
                    let json_map: std::collections::HashMap<String, serde_json::Value> = params
                        .iter()
                        .filter_map(|(k, v)| {
                            // Convert serde_cbor::Value to serde_json::Value
                            cbor_to_json(v).map(|jv| (k.clone(), jv))
                        })
                        .collect();
                    serde_json::to_string(&json_map).ok()
                }
            });
            
            actions.push(ContentAction {
                action: action.action().to_string(),
                software_agent: action.software_agent().map(software_agent_to_string),
                when: action.when().map(|t| t.to_string()),
                description: None,
                parameters: params_json,
                reason: action.reason().map(|s| s.to_string()),
                source_type: action.source_type().map(|s| s.to_string()),
            });
        }
    }

    // Get claim generator - returns &str not Option<&str>
    let claim_gen = manifest.claim_generator();

    // Get raw JSON first so we can use it for AI detection
    let raw_json = serde_json::to_string_pretty(&reader.json()).ok();

    // Check for AI generation indicators (now with raw JSON)
    let mut ai_info = detect_ai_generation(&actions, claim_gen, raw_json.as_deref());

    // A manifest can attest a watermark independently of whether the generator
    // was recognised, so this is applied after the generator heuristics rather
    // than inside them. When only the watermark declaration is present, it is
    // itself evidence of AI generation: the specification defines the action as
    // inserting a watermark for soft binding.
    if detect_watermark_declaration(&actions, raw_json.as_deref()) {
        match ai_info.as_mut() {
            Some(info) => info.watermark_declared = true,
            None => {
                ai_info = Some(AiInfo {
                    is_ai_generated: true,
                    generator_name: None,
                    model_name: None,
                    detection_source: Some("c2pa".to_string()),
                    watermark_declared: true,
                })
            }
        }
    }

    // Determine verification status
    let status = classify_validation_status(reader.validation_status());

    C2paAnalysisResult {
        status,
        signer,
        actions,
        ai_info,
        exif_info: None, // Will be filled in by caller if needed
        claim_generator: Some(claim_gen.to_string()),
        title: manifest.title().map(|s| s.to_string()),
        format: Some(manifest.format().to_string()),
        instance_id: Some(manifest.instance_id().to_string()),
        raw_manifest_json: raw_json,
    }
}

/// Does the manifest itself attest that an invisible watermark was inserted?
///
/// Two signals, both defined by the C2PA specification:
///
/// * the `c2pa.watermarked` action, "an invisible watermark was inserted into
///   the digital content for the purpose of creating a soft binding";
/// * the `c2pa.soft-binding` assertion, which the specification requires
///   alongside that action to describe the inserted watermark.
///
/// ⚠️ This reads a signed claim, it does not read a watermark. Origin Lens has
/// no watermark decoder: it reports that a manifest says a watermark exists,
/// which is a different and weaker statement than detecting one. A stripped or
/// re-encoded file can lose the manifest while keeping the watermark, and an
/// unsigned manifest can assert a watermark that was never inserted.
fn detect_watermark_declaration(actions: &[ContentAction], raw_json: Option<&str>) -> bool {
    if actions
        .iter()
        .any(|a| a.action.eq_ignore_ascii_case("c2pa.watermarked"))
    {
        return true;
    }

    // The soft-binding assertion carries its label in the manifest JSON.
    raw_json
        .map(|json| json.contains("c2pa.soft-binding"))
        .unwrap_or(false)
}

fn detect_ai_generation(actions: &[ContentAction], claim_generator: &str, raw_json: Option<&str>) -> Option<AiInfo> {
    // 1. Check actions for AI-related activities
    for action in actions {
        let action_lower = action.action.to_lowercase();
        
        // Check for standard C2PA AI-related action types
        if action_lower.contains("c2pa.created")
            || action_lower.contains("c2pa.placed")
            || action_lower.contains("generated")
            || action_lower.contains("ai")
            || action_lower.contains("c2pa.drawing")
            || action_lower.contains("c2pa.unknown")
        {
            if let Some(agent) = &action.software_agent {
                let agent_lower = agent.to_lowercase();
                for gen in AI_GENERATORS {
                    if agent_lower.contains(gen) {
                        return Some(AiInfo {
                            is_ai_generated: true,
                            generator_name: Some(agent.clone()),
                            model_name: extract_model_name(&agent_lower),
                            detection_source: Some("c2pa".to_string()),
                            watermark_declared: false,
                        });
                    }
                }
            }
            
            // Check description for AI indicators
            if let Some(desc) = &action.description {
                let desc_lower = desc.to_lowercase();
                for gen in AI_GENERATORS {
                    if desc_lower.contains(gen) {
                        return Some(AiInfo {
                            is_ai_generated: true,
                            generator_name: Some(desc.clone()),
                            model_name: extract_model_name(&desc_lower),
                            detection_source: Some("c2pa".to_string()),
                            watermark_declared: false,
                        });
                    }
                }
            }
        }
    }

    // 2. Check claim generator
    let gen_lower = claim_generator.to_lowercase();
    for ai_gen in AI_GENERATORS {
        if gen_lower.contains(ai_gen) {
            return Some(AiInfo {
                is_ai_generated: true,
                generator_name: Some(claim_generator.to_string()),
                model_name: extract_model_name(&gen_lower),
                detection_source: Some("c2pa".to_string()),
                watermark_declared: false,
            });
        }
    }

    // 3. Parse raw JSON to check for digitalSourceType and other AI indicators
    if let Some(json_str) = raw_json {
        if let Ok(json_value) = serde_json::from_str::<Value>(json_str) {
            // Check for AI indicators in the JSON
            if let Some(ai_info) = check_json_for_ai_indicators(&json_value) {
                return Some(ai_info);
            }
        }
    }

    None
}

/// Extract model name from generator string
fn extract_model_name(generator: &str) -> Option<String> {
    // Try to extract version/model info
    let patterns = [
        ("dall-e-3", "DALL-E 3"),
        ("dall-e-2", "DALL-E 2"),
        ("dall-e 3", "DALL-E 3"),
        ("dall-e 2", "DALL-E 2"),
        ("midjourney v6", "Midjourney v6"),
        ("midjourney v5", "Midjourney v5"),
        ("sd-xl", "Stable Diffusion XL"),
        ("sdxl", "Stable Diffusion XL"),
        ("sd 1.5", "Stable Diffusion 1.5"),
        ("sd 2.1", "Stable Diffusion 2.1"),
        ("stable diffusion xl", "Stable Diffusion XL"),
        ("firefly 2", "Adobe Firefly 2"),
        ("firefly 3", "Adobe Firefly 3"),
        ("imagen 2", "Google Imagen 2"),
        ("imagen 3", "Google Imagen 3"),
        ("gen-3", "Runway Gen-3"),
        ("gen-2", "Runway Gen-2"),
        ("sora", "OpenAI Sora"),
    ];
    
    for (pattern, name) in patterns {
        if generator.contains(pattern) {
            return Some(name.to_string());
        }
    }
    None
}

/// Check JSON manifest for AI generation indicators
fn check_json_for_ai_indicators(json: &Value) -> Option<AiInfo> {
    let json_str = json.to_string().to_lowercase();
    
    // Check for digitalSourceType indicating AI generation (only trainedAlgorithmicMedia variants)
    for source_type in AI_DIGITAL_SOURCE_TYPES {
        if json_str.contains(&source_type.to_lowercase()) {
            // Try to extract more specific generator info
            let generator = extract_generator_from_json(json);
            return Some(AiInfo {
                is_ai_generated: true,
                generator_name: generator.or_else(|| Some("AI Generated (from digitalSourceType)".to_string())),
                model_name: None,
                detection_source: Some("c2pa".to_string()),
                watermark_declared: false,
            });
        }
    }
    
    // Check for explicit c2pa.ai assertions (must be the exact assertion label)
    if json_str.contains("\"c2pa.ai\"") || json_str.contains("\"label\":\"c2pa.ai") {
        let generator = extract_generator_from_json(json);
        return Some(AiInfo {
            is_ai_generated: true,
            generator_name: generator.or_else(|| Some("AI Generated".to_string())),
            model_name: None,
            detection_source: Some("c2pa".to_string()),
            watermark_declared: false,
        });
    }
    
    // Check for "trained" AND "algorithmic" together (indicates trained AI model)
    if json_str.contains("trainedalgorithmic") || 
       (json_str.contains("trained") && json_str.contains("algorithmic") && json_str.contains("media")) {
        return Some(AiInfo {
            is_ai_generated: true,
            generator_name: Some("AI/ML Generated Content".to_string()),
            model_name: None,
            detection_source: Some("c2pa".to_string()),
            watermark_declared: false,
        });
    }
    
    // Check for explicit "synthetic media" or "artificially generated" phrases
    if json_str.contains("synthetic media") || json_str.contains("artificially generated") {
        return Some(AiInfo {
            is_ai_generated: true,
            generator_name: Some("Synthetic/AI Generated".to_string()),
            model_name: None,
            detection_source: Some("c2pa".to_string()),
            watermark_declared: false,
        });
    }
    
    None
}

/// Try to extract generator name from JSON manifest
fn extract_generator_from_json(json: &Value) -> Option<String> {
    // Try common paths where generator info might be stored
    if let Some(manifests) = json.get("manifests").and_then(|m| m.as_object()) {
        for (_, manifest) in manifests {
            // Check claim_generator
            if let Some(gen) = manifest.get("claim_generator").and_then(|g| g.as_str()) {
                return Some(gen.to_string());
            }
            
            // Check assertions for software agents
            if let Some(assertions) = manifest.get("assertions").and_then(|a| a.as_array()) {
                for assertion in assertions {
                    if let Some(data) = assertion.get("data") {
                        // Check for software_agent in actions
                        if let Some(actions) = data.get("actions").and_then(|a| a.as_array()) {
                            for action in actions {
                                if let Some(agent) = action.get("softwareAgent").and_then(|a| a.as_str()) {
                                    let agent_lower = agent.to_lowercase();
                                    for gen in AI_GENERATORS {
                                        if agent_lower.contains(gen) {
                                            return Some(agent.to_string());
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    None
}

/// Returns the C2PA SDK version
#[frb(sync)]
/// Map a c2pa validation-status list onto the app's verification status.
///
/// The library's `status_for_store` filters out every success code before it
/// builds this list, so a non-empty list always means at least one check
/// failed. Any fall-through to `Verified` is therefore wrong by construction,
/// which is what the earlier substring test did: it looked for lowercase
/// "signature", "expired" and "trust" and treated everything else as verified.
/// Codes such as `claimSignature.mismatch` (capital S) and
/// `assertion.dataHash.mismatch` matched none of those tests, so an image whose
/// content no longer matches its signed hash was displayed as authentic.
///
/// Codes are compared exactly, against the constants in c2pa-rs 0.32.7. A code
/// that matches no category is not silently accepted: it is reported verbatim,
/// so an unrecognised failure surfaces instead of disappearing.
fn classify_validation_status(statuses: Option<&[c2pa::validation_status::ValidationStatus]>) -> VerificationStatus {
    let statuses = match statuses {
        None => return VerificationStatus::Verified,
        Some(s) if s.is_empty() => return VerificationStatus::Verified,
        Some(s) => s,
    };

    const SIGNATURE_FAILURES: [&str; 2] = ["claimSignature.mismatch", "claimSignature.missing"];
    const EXPIRY_FAILURES: [&str; 2] = ["signingCredential.expired", "timeStamp.outsideValidity"];
    const TRUST_FAILURES: [&str; 5] = [
        "signingCredential.untrusted",
        "signingCredential.invalid",
        "signingCredential.revoked",
        "timeStamp.untrusted",
        "timeStamp.mismatch",
    ];

    let has = |set: &[&str]| statuses.iter().any(|s| set.contains(&s.code()));

    if has(&SIGNATURE_FAILURES) {
        VerificationStatus::SignatureInvalid
    } else if has(&EXPIRY_FAILURES) {
        VerificationStatus::CertificateExpired
    } else if has(&TRUST_FAILURES) {
        VerificationStatus::CertificateUntrusted
    } else {
        // Integrity and structural failures, including asset-binding mismatches.
        // The prefix matters: the Dart layer treats an Error as "no manifest" and
        // routes such images to the remote assessment. A manifest that fails
        // validation is still a manifest, and must not be uploaded on that basis.
        let codes: Vec<&str> = statuses.iter().map(|s| s.code()).collect();
        VerificationStatus::Error {
            message: format!("C2PA manifest validation failed: {}", codes.join(", ")),
        }
    }
}

pub fn c2pa_sdk_version() -> String {
    "c2pa-rs 0.32".to_string()
}

/// Check if the native library is properly loaded
#[frb(sync)]
pub fn is_c2pa_available() -> bool {
    true
}
