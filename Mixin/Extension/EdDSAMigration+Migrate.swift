import Foundation
import MixinCrypto
import MixinServices

extension EdDSAMigration {
    
    static func migrate() {
        guard AppGroupKeychain.sessionSecret == nil || AppGroupKeychain.pinToken == nil else {
            return
        }
        let key = Ed25519PrivateKey()
        let sessionSecret = key.publicKey.rawRepresentation.base64EncodedString()

        repeat {
            guard LoginManager.shared.isLoggedIn else {
                return
            }
            let result = AccountAPI.update(sessionSecret: sessionSecret)
            switch result {
            case .success(let response):
                guard let remotePublicKey = Data(base64Encoded: response.pinToken), let pinToken = AgreementCalculator.agreement(fromPublicKeyData: remotePublicKey, privateKeyData: key.x25519Representation) else {
                    reporter.report(error: MixinAPIError.invalidServerPinToken)
                    return
                }
                AppGroupUserDefaults.Account.sessionSecret = nil
                AppGroupUserDefaults.Account.pinToken = nil
                AppGroupKeychain.sessionSecret = key.rfc8032Representation
                AppGroupKeychain.pinToken = pinToken
                return
            case .failure(.unauthorized):
                return
            case .failure(.forbidden):
                return
            case let .failure(error) where error.worthRetrying:
                reporter.report(error: error)
                Thread.sleep(forTimeInterval: 2)
            case let .failure(error):
                reporter.report(error: error)
                return
            }
        } while true
    }
    
}
