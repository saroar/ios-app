import Foundation
import Starscream

public enum MixinServicesError: Error {
    
    private static var basicUserInfo: [String: Any] {
        var userInfo = reporter.basicUserInfo
        userInfo["didLogin"] = LoginManager.shared.isLoggedIn
        userInfo["isAppExtension"] = isAppExtension
        return userInfo
    }
    
    case saveIdentity
    case encryptGroupMessageData(SignalError)
    case extractEncryptedPin
    case duplicatedMessage
    case nilMimeType([String: Any])
    case duplicatedJob
    case sendMessage([String: Any])
    case refreshOneTimePreKeys(error: SignalError, identityCount: Int)
    case initEncryptingInputStream(size: Int64, name: String)
    case initInputStream
    case initDecryptingOutputStream
    case initOutputStream
    case decryptMessage([String: Any])
    case badMessageData(id: String, status: String, from: String)
    case logout(isAsyncRequest: Bool)
    case badParticipantSession
    case websocketDidDisconnect(error: WSError)
    
}

extension MixinServicesError: CustomNSError {
    
    public static var errorDomain: String {
        return "MixinServicesError"
    }
    
    public var errorCode: Int {
        switch self {
        case .saveIdentity:
            return 0
        case .encryptGroupMessageData:
            return 1
        case .extractEncryptedPin:
            return 2
        case .duplicatedMessage:
            return 3
        case .nilMimeType:
            return 4
        case .duplicatedJob:
            return 5
        case .sendMessage:
            return 6
        case .refreshOneTimePreKeys:
            return 7
        case .initEncryptingInputStream:
            return 8
        case .initInputStream:
            return 9
        case .initDecryptingOutputStream:
            return 10
        case .initOutputStream:
            return 11
        case .decryptMessage:
            return 12
        case .badMessageData:
            return 13
        case .logout:
            return 14
        case .badParticipantSession:
            return 15
        case .websocketDidDisconnect:
            return 16
        }
    }
    
    public var errorUserInfo: [String : Any] {
        var userInfo: [String : Any]
        switch self {
        case let .encryptGroupMessageData(error):
            userInfo = Self.basicUserInfo
            userInfo["signalCode"] = error.rawValue
        case let .nilMimeType(info):
            userInfo = info
        case .duplicatedJob:
            userInfo = Self.basicUserInfo
        case let .sendMessage(info):
            userInfo = info
        case let .refreshOneTimePreKeys(error, identityCount):
            userInfo = Self.basicUserInfo
            userInfo["signalCode"] = error.rawValue
            userInfo["identityCount"] = identityCount
        case let .initEncryptingInputStream(size, name):
            userInfo = ["size": size, "name": name]
        case let .decryptMessage(info):
            userInfo = Self.basicUserInfo
            for (key, value) in info {
                userInfo[key] = value
            }
        case let .badMessageData(id, status, from):
            userInfo = ["messageId": id,
                        "status" : status,
                        "from": from]
        case let .logout(isAsyncRequest):
            return ["isAsyncRequest": isAsyncRequest]
        case let .websocketDidDisconnect(error):
            userInfo = Self.basicUserInfo
            userInfo["errorMessage"] = error.message
            switch error.type {
            case .outputStreamWriteError:
                userInfo["errorType"] = "outputStreamWriteError"
            case .compressionError:
                userInfo["errorType"] = "compressionError"
            case .invalidSSLError:
                userInfo["errorType"] = "invalidSSLError"
            case .writeTimeoutError:
                userInfo["errorType"] = "writeTimeoutError"
            case .protocolError:
                userInfo["errorType"] = "protocolError"
            case .upgradeError:
                userInfo["errorType"] = "upgradeError"
            case .closeError:
                userInfo["errorType"] = "closeError"
            }
        default:
            userInfo = [:]
        }
        return userInfo
    }
    
}
