# Privacy Policy for Origin Lens

**Effective Date:** September 11, 2026

At Origin Lens ("we," "us," or "our"), operated by Alexander Loth and Dominique Conceicao Rosario, we are committed to protecting your privacy. This Privacy Policy explains our practices regarding the collection, use, and disclosure of information when you use our mobile application, Origin Lens ("App").

We comply with applicable privacy laws and regulations including the General Data Protection Regulation (GDPR) and the California Consumer Privacy Act (CCPA).

## 1. Our Guiding Principle: We Don't Collect Your Data

Origin Lens is a privacy-first media verification utility. We do not collect, store, track, or share any personal data from you, and we operate no servers that receive your images.

The App's core verification – C2PA Content Credentials, cryptographic signature checks, asset-binding checks and EXIF metadata parsing – runs entirely on your device.

Three optional features make a network request, and **each asks for your confirmation first**. They are not alike, and the difference matters:

- **AI assessment** – offered when an image carries no Content Credentials. **Sends the image.**
- **Reverse image search** – offered when you tap "Check Online Context". **Sends the image.**
- **Remote credential fetch** – offered when an image states that its Content Credentials are held at another address. **Does not send the image.** It asks that address for the credentials.

The first two are the only paths on which an image you analyze leaves your device. All three are described in Section 3.

## 2. Information We Do Not Collect

We do not operate servers that receive your data. We do not collect, store, or have access to:

- **Images or Photos:** We never receive images you analyze. Where an image is sent to a third-party service (Section 3), it goes directly from your device to that service, with your confirmation, and not to us.
- **C2PA Credentials:** We do not record Content Credentials or verification results.
- **EXIF Metadata:** We do not collect or store EXIF metadata extracted from your images.
- **Personal Information:** We do not collect names, email addresses, phone numbers, or any other personal identifiers.
- **Usage Analytics:** We do not collect analytics data on how you use the App.
- **Location Data:** We do not collect or track your physical location.
- **Device Information:** We do not collect device identifiers, operating system versions, or hardware models.

## 3. How the App Works

### Core Verification (On-Device)

Origin Lens performs C2PA verification and EXIF metadata parsing entirely on your device. When you select an image from your gallery, files, or a URL, manifest parsing, signature verification, asset-binding checks and metadata extraction occur locally using native Rust libraries. No information about these analyses is sent anywhere.

### AI Assessment (Optional, Uses Google Gemini)

When an image carries **no C2PA Content Credentials**, the App can ask a general-purpose AI model whether the image appears to be AI-generated.

- **What is sent:** the full image, encoded in the request, together with a short text prompt.
- **Where it goes:** the Google Gemini API (`generativelanguage.googleapis.com`), using the Gemini 2.5 Flash model.
- **When:** only after you confirm the upload in a dialog that states what will be sent. You may decline, or choose not to be asked again for future images.
- **Only with a key:** the request is skipped entirely when no API key is configured.
- **What comes back:** the model's written opinion, which the App parses. This is an assessment, not a cryptographic proof.

Google's handling of data sent to this API is governed by Google's own terms: https://ai.google.dev/gemini-api/terms and https://policies.google.com/privacy

### Reverse Image Search (Optional, Uses External Services)

If you tap "Check Online Context", the App can look for earlier appearances of an image online.

- **What is sent:** the image, or a URL to it.
- **Where it goes:** SerpAPI (which queries Google, Bing, and Yandex), or those search engines directly. When a local image needs a public URL first, it is uploaded to imgbb, a temporary image host.
- **When:** only after you confirm the upload in a dialog. You may decline, or choose not to be asked again.
- **Your own keys:** you can supply your own SerpAPI key in the App's settings.

These services have their own privacy policies:
- SerpAPI: https://serpapi.com/privacy-policy
- imgbb: https://imgbb.com/privacy

Images sent for reverse search are used to perform that search and are subject to those services' retention policies. Where the App requests a short expiry for a hosted image, that request is made to the host; we cannot verify deletion on your behalf.

### Remote Credential Fetch (Optional, Address Chosen by the Image)

Some images carry no Content Credentials themselves and instead state, in their metadata, that their credentials are held at a web address. The App can request them from that address. **Your image is not sent on this path.**

- **What is sent:** a request for the credential file at the address named in the image. No part of the image is transmitted, and nothing is uploaded.
- **Where it goes:** to whatever address the image names. We cannot list it in advance, because it is chosen by the image you analyze, not by us. The App shows you the host and asks before making the request.
- **When:** only after you confirm this address in a dialog. You may decline. You may also choose to allow one specific host without being asked again for that host; that choice covers only the host you approved and does not extend to any other address or to the two features above.
- **What is revealed:** your IP address, and the fact that these particular credentials were requested. An address that receives such a request learns that someone at your IP address examined an image referring to it.
- **What comes back:** the credential file. It is then verified on your device against the image you are analyzing. Credentials that do not match the image fail verification rather than being accepted, so an address cannot vouch for an image by serving credentials belonging to a different one.
- **Limits we apply:** the request is made over HTTPS only and is refused for an unencrypted address rather than being silently upgraded, redirects that would downgrade to an unencrypted connection are refused, and the response is subject to a time limit and a size limit.

Earlier versions of the App performed this request automatically, without asking, as part of reading an image. That is no longer the case.

## 4. Third-Party Services

The App contacts these services, and only for the optional features described above:

- **Google Gemini API** (`generativelanguage.googleapis.com`) – AI assessment of images without Content Credentials
- **SerpAPI** (serpapi.com) – reverse image search across Google, Bing, and Yandex
- **imgbb** (imgbb.com) – temporary image hosting, used to give a local image a URL for reverse search
- **Search engines directly** (Google, Bing, Yandex) – reverse image search when SerpAPI is not configured

One destination cannot be listed here: the address contacted by the remote credential fetch described in Section 3. That address is named by the image being analyzed, so it differs from image to image and is not known to us in advance. The App shows you the host and asks for your confirmation before contacting it, which is the only point at which that address can be known. Any such address is a third party whose own privacy practices apply to the request, and we have no relationship with it.

The App ships with default API keys so these features work without setup. You can replace them with your own keys in Settings. Removing a key you supplied returns the App to its default key rather than disabling the feature.

### No Analytics or Advertising

We do not integrate with any analytics, advertising, or tracking services. There are no embedded SDKs from analytics or ad networks.

### URL Image Downloads

If you analyze an image from a URL, the App downloads it to your device for local analysis. That download is a direct request from your device to the address you provided.

## 5. Permissions Required

Origin Lens requests only the permissions its functionality needs:

- **Photo Library Access:** read-only, to analyze images you explicitly select.
- **File System Access:** through the standard iOS file picker, for files you explicitly select.
- **Network Access:** to download images from URLs you provide, and for the optional features in Section 3.

We do not use these permissions to collect or transmit data beyond what Section 3 describes.

## 6. Children's Privacy

Our App is not intended for children under the age of 16 (or a higher age threshold if stipulated by local law). We do not knowingly collect any data from anyone, including children.

## 7. Your Privacy Rights

Your privacy rights are respected because your data stays with you. Analysis results are displayed in the App only and are not stored. Deleting the App removes its associated data, including temporarily cached images.

Images sent to a third-party service under Section 3 are subject to that service's own policy and rights process, linked above.

## 8. Data Retention

The App does not retain images or analysis results. Processing is ephemeral and occurs in memory during active use. Temporary files, such as images downloaded from URLs, are managed by iOS and can be cleared through standard system cache management or by uninstalling the App.

## 9. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. The current version is published in the App's source repository and linked from the App, and the "Effective Date" at the top is revised when it changes. We encourage you to review this policy periodically.

## 10. Contact Us

If you have any questions or concerns regarding this Privacy Policy, please contact:

- **Alexander Loth**
  - By email: [support@alexloth.com](mailto:support@alexloth.com)
  - By visiting the GitHub page: [https://github.com/aloth/origin-lens](https://github.com/aloth/origin-lens)

By using Origin Lens, you acknowledge that you have read and understood this Privacy Policy.
