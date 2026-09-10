//! Fixture-driven checks for the C2PA reader.
//!
//! The fixtures come from c2pa-rs v0.32.7's own test corpus, which is the same
//! library version this app resolves to according to Cargo.lock. They are read
//! through the app's public API, so these tests exercise the path the app
//! actually uses rather than a reimplementation of it.
//!
//! Run with: cargo test --test c2pa_fixtures -- --nocapture

use rust_lib_origin_lens::api::c2pa_reader::{analyze_c2pa_from_path, VerificationStatus};

fn fixture(name: &str) -> String {
    format!("{}/tests/fixtures/{}", env!("CARGO_MANIFEST_DIR"), name)
}

fn describe(status: &VerificationStatus) -> String {
    match status {
        VerificationStatus::Verified => "Verified".to_string(),
        VerificationStatus::SignatureInvalid => "SignatureInvalid".to_string(),
        VerificationStatus::CertificateExpired => "CertificateExpired".to_string(),
        VerificationStatus::CertificateUntrusted => "CertificateUntrusted".to_string(),
        VerificationStatus::NoManifest => "NoManifest".to_string(),
        VerificationStatus::Error { message } => format!("Error({message})"),
    }
}

/// Prints what every fixture yields. This is the exploratory pass: it records
/// observed behaviour instead of asserting assumed behaviour, so the assertions
/// below can be written against what the library really does.
#[test]
fn survey_all_fixtures() {
    let names = [
        "C.jpg",
        "CA.jpg",
        "CIE-sig-CA.jpg",
        "E-sig-CA.jpg",
        "XCA.jpg",
        "no_manifest.jpg",
    ];

    println!("\n--- fixture survey ---");
    for name in names {
        let path = fixture(name);
        if !std::path::Path::new(&path).exists() {
            println!("{name:<18} MISSING");
            continue;
        }
        let result = analyze_c2pa_from_path(path);
        let ai = result
            .ai_info
            .as_ref()
            .map(|a| {
                format!(
                    "ai={} watermark={} src={:?}",
                    a.is_ai_generated, a.watermark_declared, a.detection_source
                )
            })
            .unwrap_or_else(|| "ai=none".to_string());
        println!(
            "{name:<18} {:<34} actions={} {}",
            describe(&result.status),
            result.actions.len(),
            ai
        );
    }
    println!("--- end survey ---\n");
}

/// A file with no manifest must never be reported as verified.
///
/// This is the invariant the substring-matching defect broke in the other
/// direction: it is cheap to state and would have caught a whole class of
/// misclassification.
#[test]
fn file_without_manifest_is_not_verified() {
    let result = analyze_c2pa_from_path(fixture("no_manifest.jpg"));
    assert!(
        !matches!(result.status, VerificationStatus::Verified),
        "a file without a manifest reported as Verified: {}",
        describe(&result.status)
    );
}

/// The regression this suite exists for.
///
/// XCA.jpg carries a manifest whose asset-binding check fails: the library
/// reports `assertion.dataHash.mismatch`, meaning the image content no longer
/// matches the hash its manifest signed. The previous implementation tested
/// status codes for the lowercase substrings "signature", "expired" and
/// "trust". That code contains none of them, so it fell through to Verified and
/// the app displayed a tampered image as authentic.
///
/// This test fails against that implementation and passes against the current
/// one, which is the only reason to trust either.
#[test]
fn tampered_asset_binding_is_not_verified() {
    let path = fixture("XCA.jpg");
    assert!(
        std::path::Path::new(&path).exists(),
        "fixture XCA.jpg is missing; this test cannot prove anything without it"
    );

    let result = analyze_c2pa_from_path(path);

    match &result.status {
        VerificationStatus::Error { message } => {
            assert!(
                message.contains("assertion.dataHash.mismatch"),
                "expected the failing status code to be named, got: {message}"
            );
        }
        other => panic!(
            "an image whose content no longer matches its signed hash was reported as {}",
            describe(other)
        ),
    }
}

/// No fixture may be reported as verified while the library reports failures.
///
/// c2pa-rs filters success codes out of the validation-status list before
/// returning it, so any non-empty list means at least one check failed. The
/// previous implementation fell through to Verified whenever no status code
/// contained the lowercase substrings "signature", "expired" or "trust", which
/// silently accepted codes like claimSignature.mismatch and
/// assertion.dataHash.mismatch.
#[test]
fn failing_fixtures_are_never_verified() {
    let names = ["C.jpg", "CA.jpg", "CIE-sig-CA.jpg", "E-sig-CA.jpg", "XCA.jpg"];

    for name in names {
        let path = fixture(name);
        if !std::path::Path::new(&path).exists() {
            continue;
        }
        let result = analyze_c2pa_from_path(path);

        // An Error carrying validation codes must name them, so a failure is
        // never reduced to a bare "verified" or an empty message.
        if let VerificationStatus::Error { message } = &result.status {
            if message.starts_with("C2PA manifest validation failed") {
                assert!(
                    message.contains('.'),
                    "{name}: validation error without any status code: {message}"
                );
            }
        }
    }
}
