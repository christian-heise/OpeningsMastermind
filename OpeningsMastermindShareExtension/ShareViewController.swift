import UIKit
import Social
import UniformTypeIdentifiers
import SwiftUI

@objc(ShareNavigationController)
class ShareNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        retrieveSharedURL { [weak self] url in
            guard let url = url else {
                let error = NSError(domain: "gleissnerchristian.ChessOpeningTrainer", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve the url"])
                self?.extensionContext?.cancelRequest(withError: error)
                return
            }

            guard var components = URLComponents(string: "openingsmastermind://share_extension") else {
                let error = NSError(domain: "gleissnerchristian.ChessOpeningTrainer", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create the components"])
                self?.extensionContext?.cancelRequest(withError: error)
                return

            }
            
            components.queryItems = [URLQueryItem(name: "share_url", value: url.absoluteString)]
            guard let deepLinkURL = components.url else {
                let error = NSError(domain: "gleissnerchristian.ChessOpeningTrainer", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create the deep-link url"])
                self?.extensionContext?.cancelRequest(withError: error)
                return

            }
            
            _ = self?.openURL(deepLinkURL)
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    func retrieveSharedURL(_ completion: @escaping (URL?) -> ()) {
        let attachment = (extensionContext?.inputItems as? [NSExtensionItem])?
            .reduce([], { $0 + ($1.attachments ?? []) })
            .first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) })
        
        if let attachment = attachment {
            attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (item, _) in
                completion(item as? URL)
            }
        }
    }
    
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
}
