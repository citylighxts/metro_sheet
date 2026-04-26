import Foundation
import UIKit
import ObjectiveC.runtime

/// Disables iOS UIFeedbackGenerator haptics app-wide.
enum HapticsDisabler {
  static func disable() {
    swizzle(
      cls: UIFeedbackGenerator.self,
      original: #selector(UIFeedbackGenerator.prepare),
      replacement: #selector(UIFeedbackGenerator.ms_noHaptic_prepare)
    )

    swizzle(
      cls: UIImpactFeedbackGenerator.self,
      original: Selector(("impactOccurred")),
      replacement: #selector(UIImpactFeedbackGenerator.ms_noHaptic_impactOccurred)
    )

    swizzle(
      cls: UIImpactFeedbackGenerator.self,
      original: Selector(("impactOccurredWithIntensity:")),
      replacement: #selector(UIImpactFeedbackGenerator.ms_noHaptic_impactOccurredWithIntensity(_:))
    )

    swizzle(
      cls: UISelectionFeedbackGenerator.self,
      original: #selector(UISelectionFeedbackGenerator.selectionChanged),
      replacement: #selector(UISelectionFeedbackGenerator.ms_noHaptic_selectionChanged)
    )

    swizzle(
      cls: UINotificationFeedbackGenerator.self,
      original: #selector(UINotificationFeedbackGenerator.notificationOccurred(_:)),
      replacement: #selector(UINotificationFeedbackGenerator.ms_noHaptic_notificationOccurred(_:))
    )
  }

  private static func swizzle(cls: AnyClass, original: Selector, replacement: Selector) {
    guard
      let originalMethod = class_getInstanceMethod(cls, original),
      let replacementMethod = class_getInstanceMethod(cls, replacement)
    else {
      return
    }

    method_exchangeImplementations(originalMethod, replacementMethod)
  }
}

private extension UIFeedbackGenerator {
  @objc func ms_noHaptic_prepare() {}
}

private extension UIImpactFeedbackGenerator {
  @objc func ms_noHaptic_impactOccurred() {}

  @objc func ms_noHaptic_impactOccurredWithIntensity(_ intensity: CGFloat) {}
}

private extension UISelectionFeedbackGenerator {
  @objc func ms_noHaptic_selectionChanged() {}
}

private extension UINotificationFeedbackGenerator {
  @objc func ms_noHaptic_notificationOccurred(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {}
}
