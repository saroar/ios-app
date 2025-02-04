import Foundation
import UIKit
import MixinServices

class AttachmentUploadJob: UploadOrDownloadJob {

    private var stream: InputStream?

    var attachResponse: AttachmentResponse?
    
    var fileUrl: URL? {
        guard let mediaUrl = message.mediaUrl, !mediaUrl.isEmpty else {
            return nil
        }
        return AttachmentContainer.url(for: .photos, filename: mediaUrl)
    }
    
    class func jobId(messageId: String) -> String {
        return "attachment-upload-\(messageId)"
    }
    
    override func getJobId() -> String {
        return Self.jobId(messageId: message.messageId)
    }
    
    override func execute() -> Bool {
        guard !self.message.messageId.isEmpty, !isCancelled else {
            removeJob()
            return false
        }
        repeat {
            switch MessageAPI.requestAttachment() {
            case let .success(attachResponse):
                self.attachResponse = attachResponse
                guard uploadAttachment(attachResponse: attachResponse) else {
                    removeJob()
                    return false
                }
                return true
            case let .failure(error):
                if error.worthRetrying {
                    checkNetworkAndWebSocket()
                } else {
                    return false
                }
            }
        } while LoginManager.shared.isLoggedIn && !isCancelled
        return false
    }
    
    private func uploadAttachment(attachResponse: AttachmentResponse) -> Bool {
        guard let uploadUrl = attachResponse.uploadUrl, !uploadUrl.isEmpty, var request = try? URLRequest(url: uploadUrl, method: .put) else {
            return false
        }
        guard let fileUrl = fileUrl else {
            MessageDAO.shared.deleteMessage(id: messageId)
            return false
        }
        
        let needsEncryption = message.category.hasPrefix("SIGNAL_")
        let contentLength: Int
        do {
            if needsEncryption {
                if let inputStream = AttachmentEncryptingInputStream(url: fileUrl) {
                    contentLength = inputStream.contentLength
                    stream = inputStream
                } else {
                    let attrs = try FileManager.default.attributesOfItem(atPath: fileUrl.path)
                    let error = MixinServicesError.initInputStream(url: fileUrl,
                                                                   isEncrypted: needsEncryption,
                                                                   fileAttributes: attrs,
                                                                   error: nil)
                    reporter.report(error: error)
                    return false
                }
            } else {
                stream = InputStream(url: fileUrl)
                contentLength = Int(FileManager.default.fileSize(fileUrl.path))
                if stream == nil || contentLength <= 0 {
                    let attrs = try FileManager.default.attributesOfItem(atPath: fileUrl.path)
                    let error = MixinServicesError.initInputStream(url: fileUrl,
                                                                   isEncrypted: needsEncryption,
                                                                   fileAttributes: attrs,
                                                                   error: nil)
                    reporter.report(error: error)
                    return false
                }
            }
        } catch let underlying {
            let error = MixinServicesError.initInputStream(url: fileUrl,
                                                           isEncrypted: needsEncryption,
                                                           fileAttributes: nil,
                                                           error: underlying)
            reporter.report(error: error)
            return false
        }
        
        guard let inputStream = stream, contentLength > 0 else {
            return false
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        request.setValue("public-read", forHTTPHeaderField: "x-amz-acl")
        request.setValue("Connection", forHTTPHeaderField: "close")
        request.cachePolicy = .reloadIgnoringCacheData
        request.httpBodyStream = inputStream
        
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        task = session.dataTask(with: request, completionHandler: completionHandler)
        task?.resume()
        session.finishTasksAndInvalidate()
        return true
    }
    
    override func taskFinished() {
        guard let attachResponse = self.attachResponse else {
            return
        }
        let key = (stream as? AttachmentEncryptingInputStream)?.key
        let digest = (stream as? AttachmentEncryptingInputStream)?.digest
        let content = getMediaDataText(attachmentId: attachResponse.attachmentId, key: key, digest: digest)
        message.content = content
        MessageDAO.shared.updateMessageContentAndMediaStatus(content: content, mediaStatus: .DONE, messageId: message.messageId, conversationId: message.conversationId)
        
        SendMessageService.shared.sendMessage(message: message, data: content)
        removeJob()
    }
    
    func getMediaDataText(attachmentId: String, key: Data?, digest: Data?) -> String {
        let transferMediaData = TransferAttachmentData(key: key, digest: digest, attachmentId: attachmentId, mimeType: message.mediaMimeType ?? "", width: message.mediaWidth, height: message.mediaHeight, size:message.mediaSize ?? 0, thumbnail: message.thumbImage, name: message.name, duration: message.mediaDuration, waveform: message.mediaWaveform)
        return (try? JSONEncoder.default.encode(transferMediaData).base64EncodedString()) ?? ""
    }
    
}

extension AttachmentUploadJob: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        let change = ConversationChange(conversationId: message.conversationId,
                                        action: .updateUploadProgress(messageId: message.messageId, progress: progress))
        NotificationCenter.default.postOnMain(name: .ConversationDidChange, object: change)
    }
    
}
