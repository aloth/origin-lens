# Privacy Policy for Origin Lens

**Effective Date:** December 16, 2025

At Origin Lens ("we," "us," or "our"), operated by Alexander Loth and Dominique Conceicaorosario, we are committed to protecting your privacy. This Privacy Policy explains our practices regarding the collection, use, and disclosure of information when you use our mobile application, Origin Lens ("App"). Our policy is simple because our App is designed from the ground up to protect your privacy.

We comply with applicable privacy laws and regulations including the General Data Protection Regulation (GDPR) and the California Consumer Privacy Act (CCPA).

## 1. Our Guiding Principle: We Don't Collect Your Data

Origin Lens is a privacy-first media verification utility. We do not collect, store, track, or share any personal data, images, or analysis results from you. The App's core function is to analyze images for C2PA Content Credentials and EXIF metadata locally on your device, and we have no access to your photos or the images you analyze.

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

Origin Lens operates entirely on your device. When you select an image from your gallery, files, or a URL, all C2PA verification and EXIF parsing occurs locally using native Rust libraries. No information is sent to our servers or to any third party. We do not operate any backend servers for the purpose of data collection or image processing.

### 2.1. Data You Provide and Store Locally
Any custom tracking parameters you add to the App's blocklist are **stored locally on your device** and are only accessed by the App to perform its function. We do not transmit this list to our servers, and we do not have access to it.

### 2.2. URL Processing
The Trackless Links Safari Extension processes URLs as you browse **entirely on your device**. The content of these URLs is never logged, stored, or transmitted off your device by us. The processing is ephemeral and happens in real-time within the secure, sandboxed environment provided by Apple for Safari Web Extensions.

## 3. How We Use Information

The only information the App uses is the list of tracking parameters (both default and custom) to perform its core function: cleaning URLs.

## 4. Third-Party Services

Our App does not integrate with any third-party analytics, advertising, or tracking services. There are no embedded SDKs from companies like Google Analytics, Facebook, or any ad networks.

If you choose to analyze an image from a URL, the App will download the image directly to your device for local analysis only. The image is not stored permanently or sent to any third-party servers. Any interaction with external URLs is initiated solely by you and processed locally.

If in the future we add optional features (such as sharing verification results or exporting analysis data), those features would use the standard iOS sharing mechanisms, and we still would not collect your data. Any data you choose to share with third-party apps through iOS sharing would be governed by those third parties' privacy policies.

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
