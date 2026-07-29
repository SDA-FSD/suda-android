import Foundation
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        guard let imageUrl = imageUrl(from: request.content.userInfo),
              let url = URL(string: imageUrl) else {
            contentHandler(bestAttemptContent)
            return
        }

        downloadAttachment(from: url) { [weak self] attachment in
            if let attachment {
                bestAttemptContent.attachments = [attachment]
            }
            self?.contentHandler?(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        guard let contentHandler, let bestAttemptContent else {
            return
        }
        contentHandler(bestAttemptContent)
    }

    private func imageUrl(from userInfo: [AnyHashable: Any]) -> String? {
        if let imageUrl = (userInfo["fcm_options"] as? [String: Any])?["image"] as? String {
            return imageUrl
        }
        if let imageUrl = userInfo["image"] as? String {
            return imageUrl
        }
        return nil
    }

    private func downloadAttachment(
        from url: URL,
        completion: @escaping (UNNotificationAttachment?) -> Void
    ) {
        let task = URLSession.shared.downloadTask(with: url) { tempUrl, _, _ in
            guard let tempUrl else {
                completion(nil)
                return
            }

            let fileManager = FileManager.default
            let extensionHint = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
            let targetUrl = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(extensionHint)

            do {
                if fileManager.fileExists(atPath: targetUrl.path) {
                    try fileManager.removeItem(at: targetUrl)
                }
                try fileManager.moveItem(at: tempUrl, to: targetUrl)
                let attachment = try UNNotificationAttachment(
                    identifier: UUID().uuidString,
                    url: targetUrl
                )
                completion(attachment)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
}
