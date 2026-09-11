//! Fixture-driven checks for the C2PA reader.
//!
//! The fixtures come from c2pa-rs v0.32.7's own test corpus, which is the same
//! library version this app resolves to according to Cargo.lock. They are read
//! through the app's public API, so these tests exercise the path the app
//! actually uses rather than a reimplementation of it.
//!
//! Run with: cargo test --test c2pa_fixtures -- --nocapture

use rust_lib_origin_lens::api::c2pa_reader::{
    analyze_c2pa_from_path, fetch_remote_manifest, VerificationStatus,
};

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
        VerificationStatus::RemoteManifestPending { url } => {
            format!("RemoteManifestPending({url})")
        }
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
        "cloud.jpg",
        "remote_manifest_loopback.jpg",
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

/// An image whose XMP names a remote manifest must not be fetched during
/// analysis.
///
/// This is the invariant the `fetch_remote_manifests` feature broke. With that
/// feature compiled in, `Store::load_jumbf_from_stream` answered a missing
/// embedded manifest by fetching the `dcterms:provenance` URL over the network
/// from inside `Reader::from_stream`, before any code in this crate could ask
/// anyone. Analysis of one image silently contacted a host that the image
/// itself had chosen.
///
/// Without the feature the same code path returns `Error::RemoteManifestUrl`,
/// which this crate turns into `RemoteManifestPending` carrying the URL. The
/// request becomes something a person can be asked about, and an unanswered
/// question is a reportable state rather than a completed fetch.
///
/// `cloud.jpg` names a real Adobe host, which is what makes it evidence: if
/// analysis ever fetches again, this test sends a request to a third party
/// during an offline unit-test run. The assertion is that the returned state
/// is pending and still carries the untouched URL, so nothing resolved it.
#[test]
fn remote_manifest_is_not_fetched_during_analysis() {
    let path = fixture("cloud.jpg");
    assert!(
        std::path::Path::new(&path).exists(),
        "fixture cloud.jpg is missing; this test cannot prove anything without it"
    );

    let result = analyze_c2pa_from_path(path);

    match &result.status {
        VerificationStatus::RemoteManifestPending { url } => {
            assert_eq!(
                url, "https://cai-manifests.adobe.com/manifests/adobe-urn-uuid-5f37e182-3687-462e-a7fb-573462780391",
                "the pending state must carry the URL the image named, unmodified"
            );
        }
        other => panic!(
            "an image with a remote manifest reference produced {} instead of a pending state; \
             if this reads as Verified, analysis fetched the manifest over the network",
            describe(other)
        ),
    }

    // Nothing was read, so nothing may be reported as read.
    assert!(
        result.raw_manifest_json.is_none(),
        "no manifest was fetched, yet manifest JSON is present"
    );
    assert!(
        result.signer.is_none(),
        "no manifest was fetched, yet a signer is reported"
    );
    assert!(
        result.actions.is_empty(),
        "no manifest was fetched, yet actions are reported"
    );

    // Local EXIF parsing still runs: it costs no network request.
    assert!(
        result.exif_info.is_some(),
        "local EXIF parsing should still happen on the pending path"
    );
}

/// The same invariant, provable without trusting a third party to stay
/// unreachable.
///
/// `remote_manifest_loopback.jpg` is `cloud.jpg` with the provenance URL
/// rewritten to a closed loopback port. A fetch here cannot leave the machine,
/// and cannot succeed: were analysis to attempt one it would block on a
/// connection refusal and surface as an error rather than a pending state.
#[test]
fn loopback_remote_manifest_is_not_fetched_during_analysis() {
    let path = fixture("remote_manifest_loopback.jpg");
    assert!(
        std::path::Path::new(&path).exists(),
        "fixture remote_manifest_loopback.jpg is missing"
    );

    let result = analyze_c2pa_from_path(path);

    match &result.status {
        VerificationStatus::RemoteManifestPending { url } => {
            assert!(
                url.starts_with("https://127.0.0.1:1/"),
                "expected the loopback URL to be reported verbatim, got: {url}"
            );
        }
        other => panic!(
            "expected a pending state, got {}; a connection error here means analysis tried to fetch",
            describe(other)
        ),
    }
}

/// A plain-http manifest address is refused, and is not promoted to https.
///
/// `Store::is_valid_remote_url` in c2pa-rs accepts both schemes, so this is a
/// deliberate narrowing rather than an inherited default. Silently upgrading
/// the scheme would be worse than refusing: it would answer the question the
/// user was shown with a different request than the one they approved.
///
/// The URL used here is a closed loopback port, so a regression that removed
/// the scheme check would fail on connection rather than reach any host.
#[test]
fn http_manifest_url_is_refused() {
    let image = std::fs::read(fixture("cloud.jpg")).expect("reading fixture");

    let result = fetch_remote_manifest(
        "http://127.0.0.1:1/manifest".to_string(),
        image,
        "image/jpeg".to_string(),
    );

    match &result.status {
        VerificationStatus::Error { message } => {
            assert!(
                message.contains("https"),
                "the refusal should say why, got: {message}"
            );
        }
        other => panic!("an http manifest URL produced {}", describe(other)),
    }
}

/// A manifest address that is not a URL at all is refused before any request.
#[test]
fn malformed_manifest_url_is_refused() {
    let image = std::fs::read(fixture("cloud.jpg")).expect("reading fixture");

    let result = fetch_remote_manifest(
        "not a url".to_string(),
        image,
        "image/jpeg".to_string(),
    );

    assert!(
        matches!(result.status, VerificationStatus::Error { .. }),
        "a malformed manifest address produced {}",
        describe(&result.status)
    );
}
