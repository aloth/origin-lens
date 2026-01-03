import UIKit
import Social
import MobileCoreServices
import Photos
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    
    // IMPORTANT: Change this to your actual bundle identifier
    let hostAppBundleIdentifier = "com.example.originLens"
    let sharedKey = "ShareKey"
    var sharedMedia: [SharedMediaFile] = []
    var sharedText: [String] = []
    let imageContentType = UTType.image.identifier
    let videoContentType = UTType.movie.identifier
    let textContentType = UTType.text.identifier
    let urlContentType = UTType.url.identifier
    let fileURLType = UTType.fileURL.identifier
    
    override func isContentValid() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let content = extensionContext?.inputItems.first as? NSExtensionItem {
            if let contents = content.attachments {
                for (index, attachment) in contents.enumerated() {
                    if attachment.hasItemConformingToTypeIdentifier(imageContentType) {
                        handleImages(content: content, attachment: attachment, index: index)
                    } else if attachment.hasItemConformingToTypeIdentifier(textContentType) {
                        handleText(content: content, attachment: attachment, index: index)
                    } else if attachment.hasItemConformingToTypeIdentifier(fileURLType) {
                        handleFiles(content: content, attachment: attachment, index: index)
                    } else if attachment.hasItemConformingToTypeIdentifier(urlContentType) {
                        handleUrl(content: content, attachment: attachment, index: index)
                    } else if attachment.hasItemConformingToTypeIdentifier(videoContentType) {
                        handleVideos(content: content, attachment: attachment, index: index)
                    }
                }
            }
        }
    }
    
    override func didSelectPost() {
        print("didSelectPost")
    }
    
    override func configurationItems() -> [Any]! {
        return []
    }
    
    private func handleText(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: textContentType, options: nil) { [weak self] data, error in
            if error == nil, let item = data as? String, let this = self {
                this.sharedText.append(item)
                if index == (content.attachments?.count ?? 0) - 1 {
                    this.saveSharedText()
                }
            } else {
                self?.dismissWithError()
            }
        }
    }
    
    private func handleUrl(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: urlContentType, options: nil) { [weak self] data, error in
            if error == nil, let item = data as? URL, let this = self {
                this.sharedText.append(item.absoluteString)
                if index == (content.attachments?.count ?? 0) - 1 {
                    this.saveSharedText()
                }
            } else {
                self?.dismissWithError()
            }
        }
    }
    
    private func handleImages(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: imageContentType, options: nil) { [weak self] data, error in
            if error == nil, let this = self {
                var url: URL?
                
                if let dataURL = data as? URL {
                    url = dataURL
                } else if let imageData = data as? Data {
                    url = this.saveImageData(imageData)
                } else if let image = data as? UIImage {
                    url = this.saveImage(image)
                }
                
                if let finalURL = url {
                    let newPath = this.copyFileToSharedContainer(url: finalURL)
                    this.sharedMedia.append(SharedMediaFile(path: newPath ?? finalURL.absoluteString, thumbnail: nil, duration: nil, type: .image))
                }
                
                if index == (content.attachments?.count ?? 0) - 1 {
                    this.saveSharedMedia()
                }
            } else {
                self?.dismissWithError()
            }
        }
    }
    
    private func handleVideos(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: videoContentType, options: nil) { [weak self] data, error in
            if error == nil, let url = data as? URL, let this = self {
                let newPath = this.copyFileToSharedContainer(url: url)
                this.sharedMedia.append(SharedMediaFile(path: newPath ?? url.absoluteString, thumbnail: nil, duration: nil, type: .video))
                if index == (content.attachments?.count ?? 0) - 1 {
                    this.saveSharedMedia()
                }
            } else {
                self?.dismissWithError()
            }
        }
    }
    
    private func handleFiles(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: fileURLType, options: nil) { [weak self] data, error in
            if error == nil, let url = data as? URL, let this = self {
                let newPath = this.copyFileToSharedContainer(url: url)
                this.sharedMedia.append(SharedMediaFile(path: newPath ?? url.absoluteString, thumbnail: nil, duration: nil, type: .file))
                if index == (content.attachments?.count ?? 0) - 1 {
                    this.saveSharedMedia()
                }
            } else {
                self?.dismissWithError()
            }
        }
    }
    
    private func saveImageData(_ data: Data) -> URL? {
        let tempPath = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".png"
        let filePath = tempPath.appendingPathComponent(fileName)
        do {
            try data.write(to: filePath)
            return filePath
        } catch {
            return nil
        }
    }
    
    private func saveImage(_ image: UIImage) -> URL? {
        let tempPath = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".png"
        let filePath = tempPath.appendingPathComponent(fileName)
        if let data = image.pngData() {
            do {
                try data.write(to: filePath)
                return filePath
            } catch {
                return nil
            }
        }
        return nil
    }
    
    private func copyFileToSharedContainer(url: URL) -> String? {
        guard let groupContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.\(hostAppBundleIdentifier)") else {
            return url.absoluteString
        }
        
        let uniqueFileName = UUID().uuidString + "_" + url.lastPathComponent
        let destinationURL = groupContainerURL.appendingPathComponent(uniqueFileName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            return destinationURL.absoluteString
        } catch {
            return url.absoluteString
        }
    }
    
    private func saveSharedMedia() {
        let userDefaults = UserDefaults(suiteName: "group.\(hostAppBundleIdentifier)")
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(sharedMedia) {
            userDefaults?.set(encoded, forKey: sharedKey)
            userDefaults?.synchronize()
        }
        redirectToHostApp(type: .media)
    }
    
    private func saveSharedText() {
        let userDefaults = UserDefaults(suiteName: "group.\(hostAppBundleIdentifier)")
        userDefaults?.set(sharedText, forKey: sharedKey)
        userDefaults?.synchronize()
        redirectToHostApp(type: .text)
    }
    
    private func redirectToHostApp(type: RedirectType) {
        let url = URL(string: "ShareMedia://dataUrl=\(sharedKey)#\(type)")
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")
        
        while responder != nil {
            if responder?.responds(to: selectorOpenURL) == true {
                responder?.perform(selectorOpenURL, with: url)
            }
            responder = responder?.next
        }
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func dismissWithError() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    enum RedirectType {
        case media
        case text
        case file
    }
}

class SharedMediaFile: Codable {
    var path: String
    var thumbnail: String?
    var duration: Double?
    var type: SharedMediaType
    
    init(path: String, thumbnail: String?, duration: Double?, type: SharedMediaType) {
        self.path = path
        self.thumbnail = thumbnail
        self.duration = duration
        self.type = type
    }
}

enum SharedMediaType: Int, Codable {
    case image
    case video
    case file
}
