# Third-party notices

Origin Lens is licensed under GPL-3.0, see `LICENSE`. This file lists third-party components whose license requires a notice in redistributed binaries and that are not otherwise attributed in this repository.

## OpenSSL

The app's verification core links a static build of OpenSSL, compiled from source through the `openssl-src` crate when c2pa-rs is built with its `openssl` feature. OpenSSL provides the cryptographic primitives that verify the COSE signatures on C2PA manifests.

| | |
|---|---|
| Component | OpenSSL |
| Version | 3.6.3, via `openssl-src` 300.6.1+3.6.3 (see `src/rust_builder/rust/Cargo.lock`) |
| Copyright | Copyright 1995-2026 The OpenSSL Project Authors. All Rights Reserved. |
| License | Apache License 2.0 |
| Source | https://github.com/openssl/openssl |
| License text | https://www.openssl.org/source/license.html and `LICENSE.txt` in the OpenSSL source distribution |

This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (https://www.openssl.org/).

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this component except in compliance with the License. You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

The Apache License 2.0 is compatible with GPL-3.0.
