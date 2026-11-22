import Foundation
import UIKit
import ComponentFlow
import GlassBackgroundComponent

private final class MategramFadeMaskLayer: CAGradientLayer {
}

func mategramApplyBottomFade(to view: UIView, enabled: Bool) {
    if !enabled {
        if view.layer.mask is MategramFadeMaskLayer {
            view.layer.mask = nil
        }
        return
    }
    let mask: MategramFadeMaskLayer
    if let current = view.layer.mask as? MategramFadeMaskLayer {
        mask = current
    } else {
        mask = MategramFadeMaskLayer()
        mask.colors = [UIColor.white.cgColor, UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.0).cgColor]
        mask.locations = [0.0, 0.72, 1.0]
        mask.startPoint = CGPoint(x: 0.5, y: 0.0)
        mask.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.mask = mask
    }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    mask.frame = view.bounds
    CATransaction.commit()
}

private let mategramFieldsGlassTag = 0x6d6766

func mategramUpdateFieldsGlass(container: UIView, frame: CGRect?, isDark: Bool) {
    let existing = container.viewWithTag(mategramFieldsGlassTag) as? GlassBackgroundView
    guard let frame, frame.height > 1.0 else {
        existing?.removeFromSuperview()
        return
    }
    let glass: GlassBackgroundView
    if let existing {
        glass = existing
    } else {
        glass = GlassBackgroundView()
        glass.tag = mategramFieldsGlassTag
        glass.isUserInteractionEnabled = false
        container.insertSubview(glass, at: 0)
    }
    glass.frame = frame
    glass.update(size: frame.size, cornerRadius: min(26.0, frame.height * 0.5), isDark: isDark, tintColor: .init(kind: .clear), transition: .immediate)
}
