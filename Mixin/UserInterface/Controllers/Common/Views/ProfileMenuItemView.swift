import UIKit

final class ProfileMenuItemView: UIView, XibDesignable {
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    weak var target: NSObject?
    
    var item: ProfileMenuItem? {
        didSet {
            guard let item = item else {
                return
            }
            label.text = item.title
            label.textColor = item.style.contains(.destructive) ? .mixinRed : .text
            subtitleLabel.text = item.subtitle
        }
    }
    
    var contentEdgeInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 17, bottom: 0, right: 17)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadXib()
        updateButtonBackground()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
        updateButtonBackground()
    }
    
    convenience init() {
        let frame = CGRect(x: 0, y: 0, width: 414, height: 64)
        self.init(frame: frame)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateButtonBackground()
    }
    
    @IBAction func selectAction(_ sender: Any) {
        guard let target = target, let item = item else {
            return
        }
        target.perform(item.action)
    }
    
    private func updateButtonBackground() {
        button.setBackgroundImage(UIColor.inputBackground.image, for: .normal)
        button.setBackgroundImage(UIColor.secondaryBackground.image, for: .highlighted)
    }
    
}
