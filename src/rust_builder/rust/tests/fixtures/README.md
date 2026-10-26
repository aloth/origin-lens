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
| Retrieved | 10 September 2026, `cloud.jpg` on 11 September 2026 |

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
e6ad9f51be5bb83f137322a3f260b5881738e3528aee208727e75b6daaba6092  cloud.jpg
74bd327a0fc65c62a312460f34496e02813e5e6df3c6d8b6d70483985f78da4b  remote_manifest_loopback.jpg
447ff48c6145a1b72c6a63473c1a46a8b56986d6840ad16d2c5bebb66c4dbeaf  screenshot_marker.png
```

`remote_manifest_loopback.jpg` and `screenshot_marker.png` are the two files
here that upstream does not ship. The first is derived from `cloud.jpg`, see
"Derived fixture" below; the second is synthetic, see "Synthetic fixture".

What each one produces when read through this application, recorded from an
actual run rather than assumed from its filename:

| Fixture | Status | Note |
|---|---|---|
| `C.jpg` | Verified | manifest, one action |
| `CA.jpg` | Verified | manifest, two actions |
| `CIE-sig-CA.jpg` | Verified | manifest, three actions |
| `E-sig-CA.jpg` | SignatureInvalid | `claimSignature.mismatch`: the COSE signature does not verify |
| `XCA.jpg` | ContentChanged | `assertion.dataHash.mismatch` |
| `no_manifest.jpg` | NoManifest | no C2PA data |
| `cloud.jpg` | RemoteManifestPending | XMP names a manifest at `cai-manifests.adobe.com`, not fetched |
| `remote_manifest_loopback.jpg` | RemoteManifestPending | same, address rewritten to a closed loopback port |
| `screenshot_marker.png` | NoManifest | EXIF UserComment `Screenshot`, `is_screenshot` true |

`E-sig-CA.jpg` only reads as SignatureInvalid when c2pa is built with its
`openssl` feature. Without it, c2pa-rs 0.32 validates every signature with
`DummyValidator`, which accepts anything, and the file reads as
CertificateUntrusted. `broken_signature_is_signature_invalid` in
`../c2pa_fixtures.rs` fails whenever that validator is active.

`XCA.jpg` is the one that matters for validation. Its content no longer matches
the hash its manifest signed, and the reader's earlier substring-based
classification displayed it as authentic.
`tampered_asset_binding_is_content_changed` in `../c2pa_fixtures.rs` fails
against that implementation and passes against the current one.

The two remote-manifest fixtures carry the equivalent evidence for the fetch
path. `cloud.jpg` names a real third-party host, so a regression that fetches
during analysis would send a request to Adobe from an offline unit-test run.
`remote_manifest_loopback.jpg` makes that same regression provable without
depending on any third party: the address cannot be reached, so an attempted
fetch fails on connection instead of returning the pending state. Verified by
re-adding the `fetch_remote_manifests` feature and running
`loopback_remote_manifest_is_not_fetched_during_analysis`, which then fails
with "could not fetch the remote manifest".

## Derived fixture

`remote_manifest_loopback.jpg` is `cloud.jpg` with one substitution inside the
XMP packet, nothing else. The replacement was padded to the same byte length as
the original so every JPEG segment length stays valid and the file size is
unchanged at 183901 bytes:

```
from: https://cai-manifests.adobe.com/manifests/adobe-urn-uuid-5f37e182-3687-462e-a7fb-573462780391
to:   https://127.0.0.1:1/manifests/unreachable-by-design?pad=0000000000000000000000000000000000000
```

Reproduce it from `cloud.jpg` with:

```python
orig = b'https://cai-manifests.adobe.com/manifests/adobe-urn-uuid-5f37e182-3687-462e-a7fb-573462780391'
base = b'https://127.0.0.1:1/manifests/unreachable-by-design'
new = base + b'?pad=' + b'0' * (len(orig) - len(base) - len('?pad='))
assert len(new) == len(orig)
data = open('cloud.jpg', 'rb').read()
assert data.count(orig) == 1
open('remote_manifest_loopback.jpg', 'wb').write(data.replace(orig, new))
```

It inherits `cloud.jpg`'s license and copyright, being a single-string
derivative of it.

## Synthetic fixture

`screenshot_marker.png` is a 2x2 grey PNG, 145 bytes, generated by a script
rather than captured. Its `eXIf` chunk holds a big-endian TIFF structure with
one Exif IFD entry, UserComment (UNDEFINED) set to `ASCII\0\0\0Screenshot`,
which is the form iOS and macOS write into screenshots. It contains no image
content and no other metadata. Regenerate it with:

```python
import struct, zlib
comment = b'ASCII\x00\x00\x00' + b'Screenshot'
tiff = bytearray(b'MM\x00\x2a' + struct.pack('>I', 8))
exif_ifd_off = 8 + 2 + 12 + 4
tiff += struct.pack('>H', 1) + struct.pack('>HHII', 0x8769, 4, 1, exif_ifd_off) + struct.pack('>I', 0)
value_off = exif_ifd_off + 2 + 12 + 4
tiff += struct.pack('>H', 1) + struct.pack('>HHII', 0x9286, 7, len(comment), value_off) + struct.pack('>I', 0)
tiff += comment
def chunk(t, body):
    return struct.pack('>I', len(body)) + t + body + struct.pack('>I', zlib.crc32(t + body) & 0xffffffff)
ihdr = struct.pack('>IIBBBBB', 2, 2, 8, 2, 0, 0, 0)
raw = b''.join(b'\x00' + b'\x80\x80\x80' * 2 for _ in range(2))
png = (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'eXIf', bytes(tiff))
       + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))
open('screenshot_marker.png', 'wb').write(png)
```

The output is byte-identical to the committed file with zlib's default
compression level, which the checksum above confirms.

The images themselves are coloured ribbons against a blurred background, one
Lorem ipsum text card, and one photograph of the Earth from space. No people,
brands or identifiable places, and no EXIF artist, copyright, camera or GPS
fields. The `cloud.jpg` pair carry `Software: Adobe Photoshop 21.1 (Macintosh)`
and 2005/2020 timestamps, which name a tool rather than a person.
