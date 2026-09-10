# Test fixtures

These images come from the c2pa-rs test corpus. They are vendored rather than
downloaded at test time so the regression tests keep their evidence: a test that
fetches its own subject over the network cannot say what it examined.

## Origin

| | |
|---|---|
| Repository | https://github.com/contentauth/c2pa-rs |
| Path | `sdk/tests/fixtures/` |
| Tag | `v0.32.7` |
| Commit | `1cd586773492bb5489e0ce00ad1246b3e8d1034b` |
| Retrieved | 10 September 2026 |

That tag is the c2pa version this application resolves to, recorded in
`rust_builder/rust/Cargo.lock`. The fixtures and the library that reads them are
therefore the same release.

## License

Copyright 2020 Adobe. Licensed under MIT OR Apache-2.0, per `sdk/Cargo.toml` in
the source repository. Both are compatible with this project's GPL-3.0 license.
Upstream carries no NOTICE file; this file serves as the required attribution.

## Contents

Verified with `shasum -a 256`:

```
cf250bee1d27d12281ac11a4cc407ffeb9392de25f04edcb3ab2318c38f3d7e4  C.jpg
1e1d290412fa720065ad493d3267e2880c5fe210c8611e263d9891d89ecbb26b  CA.jpg
c6191e787b051b64f7ae247d5e73a3db79f7e213f55f407b11af0033ed142e45  CIE-sig-CA.jpg
e60095941bc37701dbc22878f8f12286c489bf3190a3e535190a098b98fe18ca  E-sig-CA.jpg
27f408321dd399c26a0a66bb77b5c9189ef38c79a80f63caa10fb6f7a6ab98bc  XCA.jpg
9ac395ca04fc9d348acf6f81920f5e894d336341c3f764ca86c354eec6f7c2d6  no_manifest.jpg
```

What each one produces when read through this application, recorded from an
actual run rather than assumed from its filename:

| Fixture | Status | Note |
|---|---|---|
| `C.jpg` | Verified | manifest, one action |
| `CA.jpg` | Verified | manifest, two actions |
| `CIE-sig-CA.jpg` | Verified | manifest, three actions |
| `E-sig-CA.jpg` | CertificateUntrusted | signer not in a trust list |
| `XCA.jpg` | Error | `assertion.dataHash.mismatch` |
| `no_manifest.jpg` | NoManifest | no C2PA data |

`XCA.jpg` is the one that matters. Its content no longer matches the hash its
manifest signed, and the reader's earlier substring-based classification
displayed it as authentic. `tampered_asset_binding_is_not_verified` in
`../c2pa_fixtures.rs` fails against that implementation and passes against the
current one.

The images themselves are coloured ribbons against a blurred background, and one
Lorem ipsum text card. No people, brands or identifiable places, and no EXIF
artist, copyright, camera or GPS fields.
