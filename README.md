# Origin Lens – Verify Image Authenticity with C2PA Content Credentials

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Paper](https://img.shields.io/badge/Paper-arXiv:2602.03423-B31B1B.svg)](https://arxiv.org/abs/2602.03423)
[![Mastodon](https://img.shields.io/badge/Mastodon-@xlth-6364FF?logo=mastodon&logoColor=white)](https://mastodon.social/@xlth)

<p align="center">
  <img src="figures/origin-lens-c2pa-image-verification-privacy-ai-detection-wide.png" alt="Origin Lens — AI-powered image verification and content authenticity on mobile" width="700">
</p>

**Combat fake news and misinformation by verifying the authenticity of images with cryptographic provenance data.**

Origin Lens analyzes images for C2PA (Coalition for Content Provenance and Authenticity) Content Credentials, EXIF metadata and SynthID to detect AI-generated content, verify digital signatures, and reveal the complete edit history of any image. Core verification happens on your device. An optional reverse image search feature uses external services to help detect out-of-context images.

---

## 📲 Download

Get Origin Lens on your iPhone or iPad to start verifying image authenticity today:

[![Download on the App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/us/app/origin-lens/id6756628121?platform=iphone)

---

## ✨ What Makes Origin Lens Different?

Origin Lens goes beyond simple metadata viewing. It performs cryptographic verification of Content Credentials, detects AI-generated content from multiple sources, and provides comprehensive provenance analysis. All verification happens locally on your device.

### C2PA Content Credentials Verification

Cryptographically verify the authenticity of images.

- **Digital signature validation** – Verify cryptographic signatures on embedded C2PA manifests
- **Certificate chain verification** – Check if signers are trusted and certificates are valid
- **Tamper detection** – Identify if content has been modified since signing
- **Signer information** – View organization, issuer, and timestamp details
- **Multiple verification states** – Verified, Invalid Signature, Expired Certificate, Untrusted, or No Manifest

### 🤖 AI Generation Detection

Identify AI-generated content from multiple sources.

- **C2PA assertions analysis** – Detect AI generators from standard Content Credentials
- **EXIF metadata parsing** – Find AI signatures in image metadata
- **Multi-source detection** – Combines C2PA, EXIF, and SynthID for comprehensive coverage
- **50+ AI generators detected** – Midjourney, DALL-E, Stable Diffusion, Adobe Firefly, and more
- **Detection source transparency** – Shows whether AI was detected via C2PA, EXIF, or SynthID

### 📜 Complete Edit History Timeline

See every action performed on an image.

- **Action-by-action timeline** – View capture, edit, and publish events
- **Software agent tracking** – Identify tools used to create and modify content
- **Timestamp information** – When each action occurred
- **Digital source type** – Understand the origin (camera capture, screen capture, AI generation, etc.)

### EXIF Metadata Analysis

Access detailed image metadata.

- **Camera information** – Make, model, and settings
- **Software details** – Applications used to create or edit the image
- **Artist and copyright** – Creator attribution
- **Date and time** – When the photo was taken
- **AI detection markers** – Prompt parameters, generation settings, and AI tool signatures

### 🔎 Reverse Image Search (Optional)

Find where images have appeared online.

- **Multi-engine search** – Searches across Bing, Yandex, and Google
- **Context verification** – Detect out-of-context or misattributed images
- **Smart filtering** – Removes irrelevant results like login pages
- **Privacy notice** – Clear warning before uploading to external services
- **Bring your own keys** – Use your own API keys for enhanced privacy

> **Note:** This optional feature uploads images to external search services. A clear privacy note is shown before use.

### 📤 Multiple Input Sources

Analyze images from anywhere.

- **Photo Library** – Select from your gallery
- **Files App** – Access iCloud Drive and local files
- **URL Analysis** – Paste image URLs for remote verification

---

## 📱 Key Features

### 🔍 Image Analysis
Select images from your photo library, files, or paste a URL to analyze any image for Content Credentials and metadata.

### ✅ Verification Status
Clear visual indicators show whether content is verified, has signature issues, expired certificates, or no C2PA data.

### 🤖 AI Detection Badge
Prominently displays when content is detected as AI-generated, showing the generator name and detection method.

### 📊 Detailed Provenance Information
View signer details, complete edit history, EXIF metadata, and raw manifest data all in one comprehensive interface.

### 🌐 URL Support
Analyze images directly from the web without downloading them first.

---

## 🔒 Privacy You Can Trust

**Core verification happens on your device. Optional features use external services with clear disclosure.**

- ✅ **On-device verification** – All C2PA and EXIF analysis runs locally
- ✅ **Zero data collection** – No analytics, no tracking, no servers
- ✅ **No account required** – Works immediately after install
- ✅ **Transparent remote features** – Reverse image search clearly warns before uploading
- ✅ **Bring your own API keys** – Use personal keys for external services
- ✅ **Privacy first** – Read our [Privacy Policy](https://github.com/aloth/origin-lens/blob/main/privacy_policy.md)

---

## Open Source

Origin Lens is open source software, licensed under the [GNU General Public License v3.0](LICENSE).

**Want to contribute or build from source?** See the [Build Instructions](src/README.md) for development setup, architecture details, and contribution guidelines.

---

## Support & Feedback

Help make Origin Lens better:

- 🐛 [Report a Bug](https://github.com/aloth/origin-lens/issues/new?template=bug-report.md)
- 💡 [Request a Feature](https://github.com/aloth/origin-lens/issues/new?template=feature_request.md)
- 📧 [Contact Support](mailto:support@alexloth.com)

---

## Related Research

Origin Lens is part of a broader research initiative investigating the intersection of generative AI and misinformation. We invite researchers, practitioners, and policymakers to explore our related work and contribute to advancing this critical field.

### How to Cite

If you use Origin Lens or its underlying research in your work, please cite our paper:

> **Origin Lens: Reclaiming Trust on the AI-Mediated Web Through On-Device Image Provenance Verification**  
> Alexander Loth, Dominique Conceicao Rosario, Peter Ebinger, Martin Kappes, Marc-Oliver Pahl  
> 18th ACM Web Science Conference (WebSci Companion '26), Braunschweig, Germany  
> [doi:10.1145/3795513.3806658](https://doi.org/10.1145/3795513.3806658)

```bibtex
@inproceedings{loth2026originlenswebsci,
  author    = {Loth, Alexander and Rosario, Dominique Conceicao and Ebinger, Peter and Kappes, Martin and Pahl, Marc-Oliver},
  title     = {Origin Lens: Reclaiming Trust on the {AI}-Mediated Web Through On-Device Image Provenance Verification},
  booktitle = {18th ACM Web Science Conference (WebSci Companion '26)},
  year      = {2026},
  month     = may,
  publisher = {ACM},
  address   = {New York, NY, USA},
  location  = {Braunschweig, Germany},
  pages     = {1--5},
  doi       = {10.1145/3795513.3806658}
}

@misc{loth2026originlens,
  author        = {Loth, Alexander and Rosario, Dominique Conceicao and Ebinger, Peter and Kappes, Martin and Pahl, Marc-Oliver},
  title         = {Origin Lens: {A} Privacy-First Mobile Framework for Cryptographic Image Provenance and {AI} Detection},
  year          = {2026},
  eprint        = {2602.03423},
  archivePrefix = {arXiv},
  primaryClass  = {cs.CR},
  note          = {Accepted at the FIIR workshop, The Web Conference 2026; the workshop was subsequently cancelled}
}
```

### Related Projects

Origin Lens is one strand of a wider research program on generated disinformation:

| Project | Description |
|:---|:---|
| [JudgeGPT](https://github.com/aloth/JudgeGPT) | Empirical platform for evaluating AI-generated news authenticity |
| [RogueGPT](https://github.com/aloth/RogueGPT) | Controlled stimulus generator for AI news authenticity research |
| [CRED-1](https://github.com/aloth/cred-1) | Open multi-signal domain credibility dataset (2,673 domains) |
| [verification-crisis](https://github.com/aloth/verification-crisis) | Expert survey on GenAI disinformation threats and countermeasures |
| [provenance-linkage](https://github.com/aloth/provenance-linkage) | Reproducibility bundle for a benchmark audit of AI-text detection |

### Related Publication

Our survey on the dual nature of generative AI in the context of fake news:

> **Blessing or Curse? A Survey on the Impact of Generative AI on Fake News**  
> Alexander Loth, Martin Kappes, Marc-Oliver Pahl (2024)  
> arXiv:2404.03021 [cs.CL]

```bibtex
@misc{loth2024blessing,
  author        = {Loth, Alexander and Kappes, Martin and Pahl, Marc-Oliver},
  title         = {Blessing or Curse? {A} Survey on the Impact of Generative {AI} on Fake News},
  year          = {2024},
  doi           = {10.48550/arXiv.2404.03021},
  eprint        = {2404.03021},
  archivePrefix = {arXiv},
  primaryClass  = {cs.CL}
}
```

### Call for Participation

We are conducting an expert survey to gather insights on generative-AI–driven disinformation. Your expertise would be invaluable to this academic research effort.

**[Participate in the Expert Survey](https://forms.gle/EUdbkEtZpEuPbVVz5)**

This survey explores expert perceptions of generative-AI–driven disinformation and aims to inform future countermeasures and policy recommendations.

---

## Learn More

- [C2PA Coalition](https://c2pa.org/) – Learn about Content Credentials technology
- [Content Authenticity Initiative](https://contentauthenticity.org/) – Adobe's initiative for content provenance
- [Verify Tool](https://contentcredentials.org/verify) – Official C2PA verification tool

---

## Keywords

C2PA verification, Content Credentials, image authenticity, AI detection, EXIF metadata, digital provenance, fake news detection, misinformation prevention, cryptographic verification, AI-generated content, image forensics, media verification, trust and safety, content authenticity, iOS privacy app

---

**Verify image authenticity. Combat misinformation.**
