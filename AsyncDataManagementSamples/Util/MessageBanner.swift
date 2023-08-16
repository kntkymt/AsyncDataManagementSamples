import SwiftEntryKit
import UIKit

enum MessageBanner {

    // MARK: - Public

    static func showError(_ title: String, with message: String? = nil) {
        let attribute = createBannerAttribute(name: "Error", color: .init(named: "error")!, feedBack: .error, duration: 3.0)

        var title = title
        if let message = message {
            title = "\(title)\n\(message)"
        }

        let label = EKProperty.LabelContent(text: title, style: .init(font: UIFont.systemFont(ofSize: 15), color: .white, alignment: .center))
        let note = EKNoteMessageView(with: label)

        SwiftEntryKit.display(entry: note, using: attribute)
    }

    // MARK: - Private

    private static func createBannerAttribute(name: String, color: UIColor, feedBack: EKAttributes.NotificationHapticFeedback, duration: Double) -> EKAttributes {
        var attribute = EKAttributes.topToast
        attribute.displayMode = .inferred
        attribute.name = name
        attribute.displayDuration = duration
        attribute.hapticFeedbackType = feedBack
        attribute.popBehavior = .animated(animation: .translation)
        attribute.entryBackground = .color(color: EKColor.init(color))

        return attribute
    }
}
