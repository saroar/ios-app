import UIKit
import MixinServices

class ChangeNumberVerificationCodeViewController: VerificationCodeViewController {
    
    var context: ChangeNumberContext!
    
    deinit {
        ReCaptchaManager.shared.clean()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = Localized.NAVIGATION_TITLE_ENTER_VERIFICATION_CODE(mobileNumber: context.newNumberRepresentation)
    }
    
    override func verificationCodeFieldEditingChanged(_ sender: Any) {
        let code = verificationCodeField.text
        let codeCountMeetsRequirement = code.count == verificationCodeField.numberOfDigits
        continueButton.isHidden = !codeCountMeetsRequirement
        if !isBusy && codeCountMeetsRequirement {
            changePhoneNumber()
        }
    }
    
    override func continueAction(_ sender: Any) {
        changePhoneNumber()
    }
    
    private func changePhoneNumber() {
        let code = verificationCodeField.text
        let context = self.context!
        isBusy = true
        let request = AccountRequest(code: code, registrationId: nil, pin: context.pin, sessionSecret: nil)
        AccountAPI.changePhoneNumber(verificationId: context.verificationId, accountRequest: request, completion: { [weak self] (result) in
            guard let weakSelf = self else {
                return
            }
            switch result {
            case .success(let account):
                LoginManager.shared.setAccount(account)
                weakSelf.verificationCodeField.resignFirstResponder()
                weakSelf.alert(nil, message: Localized.PROFILE_CHANGE_NUMBER_SUCCEEDED, handler: { (_) in
                    weakSelf.navigationController?.dismiss(animated: true, completion: nil)
                })
            case let .failure(error):
                weakSelf.isBusy = false
                weakSelf.verificationCodeField.clear()
                PINVerificationFailureHandler.handle(error: error) { [weak self] (description) in
                    self?.alert(description)
                }
            }
        })
    }
    
    override func requestVerificationCode(reCaptchaToken token: String?) {
        AccountAPI.sendCode(to: context.newNumber, reCaptchaToken: token, purpose: .phone) { [weak self] (result) in
            guard let weakSelf = self else {
                return
            }
            switch result {
            case .success(let verification):
                weakSelf.context.verificationId = verification.id
                weakSelf.resendButton.isBusy = false
                weakSelf.resendButton.beginCountDown(weakSelf.resendInterval)
            case let.failure(error):
                switch error {
                case .requiresReCaptcha:
                    ReCaptchaManager.shared.validate(onViewController: weakSelf) { (result) in
                        switch result {
                        case .success(let token):
                            self?.requestVerificationCode(reCaptchaToken: token)
                        default:
                            self?.resendButton.isBusy = false
                        }
                    }
                default:
                    weakSelf.alert(error.localizedDescription)
                    weakSelf.resendButton.isBusy = false
                }
            }
        }
    }
    
}
