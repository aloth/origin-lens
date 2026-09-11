# Changelog

Origin Lens verifies image authenticity on device. It reads C2PA Content Credentials, checks their signatures and asset binding, and parses EXIF metadata, so you can see what an image claims about its own origin.

This file records what changed in each release. Entries before 1.4.0 were written from the release notes published at the time.

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
