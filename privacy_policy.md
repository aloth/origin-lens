# Privacy Policy for Origin Lens

**Effective Date:** December 16, 2025

At Origin Lens ("we," "us," or "our"), operated by Alexander Loth and Dominique Conceicao Rosario, we are committed to protecting your privacy. This Privacy Policy explains our practices regarding the collection, use, and disclosure of information when you use our mobile application, Origin Lens ("App"). Our policy is simple because our App is designed from the ground up to protect your privacy.

We comply with applicable privacy laws and regulations including the General Data Protection Regulation (GDPR) and the California Consumer Privacy Act (CCPA).

## 1. Our Guiding Principle: We Don't Collect Your Data

Origin Lens is a privacy-first media verification utility. We do not collect, store, track, or share any personal data from you. The App's core functions – analyzing images for C2PA Content Credentials and EXIF metadata – run entirely on your device, and we have no access to your photos or the images you analyze.

### Optional Features Using External Services

Origin Lens includes an optional **Reverse Image Search** feature that, when activated by you, uploads images to third-party search services (such as SerpAPI, which uses Google, Bing, and Yandex) to find where images have appeared online. This feature:

- **Requires explicit user action** – You must tap "Search Image Context" to use it
- **Shows a clear privacy warning** – Before any upload, a notice explains that images will be sent to external services
- **Is completely optional** – Core C2PA and EXIF verification works without it
- **Supports user-provided API keys** – You can use your own API keys for enhanced privacy control

## 2. Information We Do Not Collect

Since our App processes all image analysis locally on your device, we do not collect, store, or have access to:

- **Images or Photos:** We do not upload, store, or transmit any images you analyze. All images remain on your device.
- **C2PA Credentials:** We do not record the C2PA Content Credentials or verification results.
- **EXIF Metadata:** We do not collect or store EXIF metadata extracted from your images.
- **Personal Information:** We do not collect names, email addresses, phone numbers, or any other personal identifiers.
- **Usage Analytics:** We do not collect analytics data on how you use the App (e.g., number of images analyzed, verification results, or taps in the App).
- **Location Data:** We do not collect or track your physical location.
- **Device Information:** We do not collect information about your device such as identifiers, operating system version, or hardware models.

## 3. How the App Works

### Core Verification (On-Device)

Origin Lens performs C2PA verification and EXIF metadata parsing entirely on your device. When you select an image from your gallery, files, or a URL, all cryptographic verification occurs locally using native Rust libraries. No information about these analyses is sent to our servers or to any third party.

### Reverse Image Search (Optional, Uses External Services)

If you choose to use the Reverse Image Search feature, the App will upload your image to third-party search services to find where it has appeared online. Specifically:

- **SerpAPI** (serpapi.com) – A search API service that queries Google, Bing, and Yandex image search
- **imgbb** (imgbb.com) – A temporary image hosting service used to provide a URL for local images

These services have their own privacy policies:
- SerpAPI: https://serpapi.com/privacy-policy
- imgbb: https://imgbb.com/privacy

Images uploaded for reverse search are:
- Uploaded only when you explicitly request a context search
- Used solely to perform the reverse image search
- Subject to the third-party services' data retention policies

You can use your own API keys for these services in the App's Settings, giving you direct control over your relationship with these providers.

## 4. Third-Party Services

### Services Used by the App

Origin Lens integrates with the following third-party services for the optional Reverse Image Search feature:

- **SerpAPI** (serpapi.com) – Provides reverse image search results from Google, Bing, and Yandex
- **imgbb** (imgbb.com) – Provides temporary image hosting for local images during reverse search

These services are only contacted when you explicitly use the Reverse Image Search feature. The App includes default API keys to enable this functionality, but you can provide your own API keys in Settings for greater privacy control.

### No Analytics or Advertising

We do not integrate with any analytics, advertising, or tracking services. There are no embedded SDKs from companies like Google Analytics, Facebook, or any ad networks.

### URL Image Downloads

If you choose to analyze an image from a URL, the App will download the image directly to your device for local analysis only. The image is not permanently stored or sent to any of our servers.

## 5. Permissions Required

To function properly, Origin Lens may request certain system permissions. These permissions are used solely for the intended functionality and do not result in data collection:

- **Photo Library Access:** To analyze images from your gallery, the App requests read-only access to your photo library. We only access images you explicitly select for analysis.
- **File System Access:** To analyze images from files, the App uses the standard iOS file picker. We only access files you explicitly select.
- **Network Access:** To download images from URLs you provide, the App requires internet access. Downloads are temporary and for local analysis only.

We only request permissions that are necessary for the App's functionality, and we do not use those permissions to collect or transmit data.

## 6. Children's Privacy

Our App is not intended for children under the age of 16 (or a higher age threshold if stipulated by local law). We do not knowingly collect any data from anyone, including children.

## 7. Your Privacy Rights

Your privacy rights are fully respected because your data stays with you.
- **Access, Correction, Deletion:** All image analysis results are displayed in the App interface only and are not stored. Deleting the App from your device will remove all its associated data, including any temporarily cached images.

## 8. Data Retention

The App does not retain any images or analysis results. All processing is ephemeral and occurs in memory during active use. Any temporary files (such as images downloaded from URLs) are managed by iOS and can be cleared through standard system cache management or by uninstalling the App.

## 9. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. The updated policy will be posted in the App and/or on our website, and the "Effective Date" at the top will be revised. We encourage you to review this policy periodically.

## 10. Contact Us

If you have any questions or concerns regarding this Privacy Policy, please contact:

- **Alexander Loth**
  - By email: [support+originlens@alexloth.com](mailto:support+originlens@alexloth.com)
  - By visiting the GitHub page: [https://github.com/aloth/origin-lens](https://github.com/aloth/origin-lens)

By using Origin Lens, you acknowledge that you have read and understood this Privacy Policy.
