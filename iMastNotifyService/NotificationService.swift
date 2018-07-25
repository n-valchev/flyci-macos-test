//
//  NotificationService.swift
//  iMastNotifyService
//
//  Created by user on 2018/07/24.
//  Copyright © 2018年 rinsuki. All rights reserved.
//

import UserNotifications
import Hydra

enum NotificationServiceError: Error {
    case imageDataIsNil
}

class NotificationService: UNNotificationServiceExtension {

    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    func fetchFromInternet(url: URL) -> Promise<URL> {
        return Promise<URL>(in: .background) { resolve, reject, _ in
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.urlCache = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
            let session = URLSession(configuration: sessionConfig)
            let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("imageCache")
            if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
                try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: false, attributes: nil)
            }
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 1.0)
            let urlHashed = url.absoluteString.sha256
            var pathExt = url.pathExtension
            if pathExt != "" {
                pathExt = "." + pathExt
            }
            let copyDest = cacheDirectory.appendingPathComponent(urlHashed! + pathExt)
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    return reject(error)
                }
                do {
                    guard let data = data else {
                        return reject(NotificationServiceError.imageDataIsNil)
                    }
                    try data.write(to: copyDest)
                    resolve(copyDest)
                } catch {
                    reject(error)
                }
            }
            task.resume()
        }
    }
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        // Modify the notification content here...
        let promise = async { _ in
//            self.bestAttemptContent?.title = "\(self.bestAttemptContent!.title) [modified]"
            if let images = request.content.userInfo["images"] as? [String] {
                let imageUrls = try await(all(images.map { self.fetchFromInternet(url: URL(string: $0)!) }))
                for imageUrl in imageUrls {
                    self.bestAttemptContent?.attachments.append(try UNNotificationAttachment(identifier: imageUrl.path, url: imageUrl, options: nil))
                }
            }
        }
        
        promise.catch { error in
            self.bestAttemptContent?.title = "Notification Service Error"
            self.bestAttemptContent?.subtitle = ""
            self.bestAttemptContent?.body = "\(error)"
        }.always {
            if let bestAttemptContent = self.bestAttemptContent {
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        print("timeout")
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
