import Foundation
import UIKit
import ObjectiveC
import MategramCore

private final class MategramFontState {
    static var family: String?
}

private func mategramResolvedFont(size: CGFloat, weight: UIFont.Weight) -> UIFont? {
    guard let family = MategramFontState.family else {
        return nil
    }
    let traits: [UIFontDescriptor.TraitKey: Any] = [.weight: weight.rawValue]
    let descriptor = UIFontDescriptor(fontAttributes: [.family: family, .traits: traits])
    let font = UIFont(descriptor: descriptor, size: size)
    if font.familyName == family {
        return font
    }
    return nil
}

extension UIFont {
    @objc class func mategram_systemFont(ofSize size: CGFloat) -> UIFont {
        if let font = mategramResolvedFont(size: size, weight: .regular) {
            return font
        }
        return mategram_systemFont(ofSize: size)
    }

    @objc class func mategram_systemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        if let font = mategramResolvedFont(size: size, weight: weight) {
            return font
        }
        return mategram_systemFont(ofSize: size, weight: weight)
    }

    @objc class func mategram_boldSystemFont(ofSize size: CGFloat) -> UIFont {
        if let font = mategramResolvedFont(size: size, weight: .bold) {
            return font
        }
        return mategram_boldSystemFont(ofSize: size)
    }
}

private func mategramSwapClassMethod(_ original: Selector, _ replacement: Selector) {
    guard let meta = object_getClass(UIFont.self), let originalMethod = class_getClassMethod(UIFont.self, original), let replacementMethod = class_getClassMethod(UIFont.self, replacement) else {
        return
    }
    if class_addMethod(meta, original, method_getImplementation(replacementMethod), method_getTypeEncoding(replacementMethod)) {
        class_replaceMethod(meta, replacement, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
    } else {
        method_exchangeImplementations(originalMethod, replacementMethod)
    }
}

func mategramInstallCustomFont() {
    let family = MategramSettings.shared.text(.customFont)
    if family.isEmpty || MategramFontState.family != nil {
        return
    }
    MategramFontState.family = family
    mategramSwapClassMethod(#selector(UIFont.systemFont(ofSize:)), #selector(UIFont.mategram_systemFont(ofSize:)))
    mategramSwapClassMethod(#selector(UIFont.systemFont(ofSize:weight:)), #selector(UIFont.mategram_systemFont(ofSize:weight:)))
    mategramSwapClassMethod(#selector(UIFont.boldSystemFont(ofSize:)), #selector(UIFont.mategram_boldSystemFont(ofSize:)))
}
