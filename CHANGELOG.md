# Changelog

Origin Lens verifies image authenticity on device. It reads C2PA Content Credentials, checks their signatures and asset binding, and parses EXIF metadata, so you can see what an image claims about its own origin.

This file records what changed in each release. Entries before 1.4.0 were written from the release notes published at the time.

## 1.4.1 - 2026-10-26

### Color-coded verdicts

Every analysis now opens with a verdict in one of four colors, drawn as a solid band at the top of the status card. Color and title come from one tested function with a fixed order: red over purple over green over yellow. Every color pair meets WCAG AA contrast, and the band carries a single screen reader label.

| Verdict | Color | Meaning |
|---|---|---|
| Content Credentials Valid | green | The signature is valid and the image is unchanged since signing. The signer is not checked against a trust list. |
| AI-Generated (Signed) | purple | Valid, signed credentials declare the image as AI-generated. |
| Credentials Invalid | red | The credentials fail validation. |
| Credentials Don't Match This Image | red | The image was changed after it was signed. |
| Certificate Expired | yellow | The signing certificate has expired, so the signature could not be checked. |
| Signer Not Verified | yellow | The signing certificate could not be validated. |
| No Content Credentials | yellow | Most images carry none, which alone is not a sign of manipulation. |
| Screenshot | yellow | A screenshot never carries the original's credentials. |
| Credentials Held Elsewhere | yellow | The image points to credentials on another server that have not been fetched. |

"Content Credentials Valid" replaces "Verified Authentic", and "Signer Not Verified" replaces "Untrusted Certificate".

AI tool names found only in unsigned EXIF metadata appear as a secondary line and never set the verdict. Below a red verdict, the creator and history sections are titled "Claimed by the failed credentials". Raw status codes appear on a secondary line below a plain sentence. Screenshots are recognized by the EXIF marker that iOS and macOS write, never by image size.

### Signature validation with OpenSSL

The verification core builds c2pa-rs 0.32.7 with OpenSSL 3.6.3 and validates manifest signatures on device. The SDK version in the app reads "c2pa-rs 0.32.7 (OpenSSL)". The OpenSSL license notice is in `THIRD_PARTY_NOTICES.md`.

### Gallery

The Gallery button opens the system photo picker and passes the photo file to the analysis as stored, without re-encoding it. No photo library permission is needed.

### Also in this release

- EXIF details are shown for every image that carries them, with or without Content Credentials, including images opened from a web address.
- The Gemini card is titled "AI Opinion (Gemini, experimental)", uses neutral colors, and shows one of three outcomes: a reported SynthID watermark, none reported, or no answer.
- The reverse image search prompt names each service involved: with the built-in keys, the image is stored for five minutes on imgbb and its address is sent to SerpAPI, which searches Google; without them, it goes directly to Google, Bing and Yandex. The privacy policy uses the same wording, and the in-app link points at this release's tag.
- Configuration logs state only whether an API key is set.
- The Learn tab has a "Cite Origin Lens" row that copies references to both papers. Several FAQ answers are updated, including the Adobe Firefly test, which now expects "AI-Generated (Signed)".
- Tests cover every verdict and its exact text, the contrast of each band color, and the citation text against `CITATION.cff`. Rust tests use the c2pa-rs test fixtures and a synthetic screenshot PNG. CI runs the widget tests on a pinned Flutter 3.38.3.

## 1.4.0 - 2026-09-11

### Content Credentials held elsewhere are now fetched only with your consent

Some images carry no credentials themselves and instead name a web address where their credentials are held. Until now, Origin Lens fetched that address automatically while reading the image. The request went out before the app could ask, and to an address chosen by the image rather than by you.

This version stops and asks. When an image points to credentials stored elsewhere, the analysis reports that state instead of resolving it, and shows you a dialog naming the host. The dialog is explicit about what the request does and does not do: your image is not sent, and what the address learns is your IP address and the fact that these particular credentials were requested.

Approval is per host. Unlike the AI assessment and reverse image search, which have a fixed destination and offer a "Don't ask again" option, an approval here covers only the host you approved. A blanket permission would be a permission for any address a future image chooses to name.

Requests that do go out are now bounded. HTTPS only, with an unencrypted address refused rather than quietly upgraded, redirects that would downgrade the connection refused, an explicit timeout, and a 2 MB size limit enforced against the data actually received. Credentials that arrive are verified against the image on your device, so an address cannot vouch for an image by serving credentials belonging to a different one.

The AI assessment no longer starts while this question is open. It previously ran whenever no credentials were found, which would have uploaded the image to answer a question that the pending credentials may answer without any upload.

### Watermark attestations are visible

Origin Lens has read the `c2pa.watermarked` action since 1.3.0, but the result never reached the interface. It is now shown, worded to keep the claim and the check apart: a manifest attests that an invisible watermark was inserted, and Origin Lens reads that attestation rather than detecting a watermark in the image. A file stripped of its manifest can keep its watermark, and an unsigned manifest can claim a watermark that was never inserted.

### Also in this release

- The privacy policy documents the credential fetch and separates it from the two paths that do send an image. It also records that the address for this path cannot be listed in advance, because the image names it.
- The in-app privacy policy link points at this release's tag rather than at the main branch, so a given build shows the notice that governs it.
- The FAQ links the WebSci 2026 paper describing the app.
- Tests cover the new behaviour with two vendored fixtures, one naming a real host and one a closed loopback address, so a regression that fetched during analysis would be caught offline.

## 1.3.1 - 2026-09-10

Privacy policy correction. The policy documented reverse image search but said nothing about the AI assessment, and generalised from the local verification core to the whole app. Section 3 now describes what the AI assessment sends, where it goes, and that it returns an opinion rather than a cryptographic result. Documentation only, with no change in behaviour.

## 1.3.0 - 2026-09-10

Corrected validation verdicts, upload confirmations, and watermark attestations.

The reader classified validation results by testing status codes for lowercase substrings, and treated anything else as verified. The library's codes are camelCase, so an image whose content no longer matched its signed hash was displayed as authentic. Status codes are now compared exactly, and unrecognised failures are reported rather than silently accepted.

Both paths that upload an image, the AI assessment and reverse image search, now ask first, each with its own separately stored "Don't ask again" preference. Previously the AI assessment ran as a silent fallback and reverse search uploaded on a single tap.

The reader also began recognising the `c2pa.watermarked` action and the `c2pa.soft-binding` assertion.

## 1.2.0 - 2026-09-09

Metadata-stripping warnings and a narrower upload path. Adds a warning when an image comes from a service known to strip metadata, support for your own SerpAPI key, CBOR to JSON conversion of raw manifest assertions, and EXIF parsing even when no manifest is present. Manifests that are present but unparseable no longer trigger the remote assessment.

## 1.1.0 - 2026-09-04

First tagged release. SynthID watermark detection alongside the existing C2PA and EXIF paths, a verification flow combining several detection methods rather than a single signal, and clearer status indicators for the verification states.
