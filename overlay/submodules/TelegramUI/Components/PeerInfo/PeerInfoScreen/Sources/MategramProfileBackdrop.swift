import Foundation
import UIKit
import CoreImage
import ObjectiveC
import SwiftSignalKit
import TelegramCore
import AccountContext
import AvatarNode
import ComponentFlow
import GlassBackgroundComponent

private let mategramGlassTag = 0x6d676c

private func mategramBlurred(_ image: UIImage) -> UIImage? {
    guard let cgImage = image.cgImage else {
        return nil
    }
    let input = CIImage(cgImage: cgImage)
    guard let filter = CIFilter(name: "CIGaussianBlur") else {
        return nil
    }
    filter.setValue(input.clampedToExtent(), forKey: kCIInputImageKey)
    filter.setValue(28.0, forKey: kCIInputRadiusKey)
    guard let output = filter.outputImage?.cropped(to: input.extent) else {
        return nil
    }
    let context = CIContext(options: nil)
    guard let result = context.createCGImage(output, from: input.extent) else {
        return nil
    }
    return UIImage(cgImage: result)
}

private func mategramSameColor(_ lhs: CGColor?, _ rhs: UIColor) -> Bool {
    guard let lhs, lhs.alpha > 0.01 else {
        return false
    }
    var r1: CGFloat = 0.0, g1: CGFloat = 0.0, b1: CGFloat = 0.0, a1: CGFloat = 0.0
    var r2: CGFloat = 0.0, g2: CGFloat = 0.0, b2: CGFloat = 0.0, a2: CGFloat = 0.0
    guard UIColor(cgColor: lhs).getRed(&r1, green: &g1, blue: &b1, alpha: &a1), rhs.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else {
        return false
    }
    return abs(r1 - r2) < 0.02 && abs(g1 - g2) < 0.02 && abs(b1 - b2) < 0.02 && abs(a1 - a2) < 0.05
}

final class MategramProfileBackdrop: NSObject {
    let imageView = UIImageView()
    let dimView = UIView()
    private let disposable = MetaDisposable()
    private var currentPeerId: EnginePeer.Id?
    private var currentRepresentation: TelegramMediaImageRepresentation?
    private weak var rootView: UIView?
    private var timer: Timer?
    private var clearColors: [UIColor] = []
    private var itemColor: UIColor?
    private var isDark = true

    override init() {
        super.init()
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.imageView.isUserInteractionEnabled = false
        self.dimView.isUserInteractionEnabled = false
        self.dimView.backgroundColor = UIColor(white: 0.0, alpha: 0.22)
        self.dimView.alpha = 0.0
    }

    deinit {
        self.disposable.dispose()
        self.timer?.invalidate()
    }

    func attach(to view: UIView) {
        if self.imageView.superview !== view {
            view.insertSubview(self.imageView, at: 0)
            view.insertSubview(self.dimView, aboveSubview: self.imageView)
        }
        self.rootView = view
        if self.timer == nil {
            let timer = Timer(timeInterval: 0.4, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
    }

    func layout(size: CGSize) {
        let frame = CGRect(origin: CGPoint(), size: size)
        self.imageView.frame = frame
        self.dimView.frame = frame
        self.sweep()
    }

    @objc private func timerFired() {
        self.sweep()
    }

    private func sweep() {
        guard let rootView = self.rootView else {
            self.timer?.invalidate()
            self.timer = nil
            return
        }
        guard rootView.window != nil, self.imageView.image != nil, !self.clearColors.isEmpty else {
            return
        }
        var budget = 6000
        self.visit(rootView, budget: &budget)
    }

    private func visit(_ view: UIView, budget: inout Int) {
        if budget <= 0 || view.isHidden || view === self.imageView || view === self.dimView || view is GlassBackgroundView {
            return
        }
        budget -= 1
        let color = view.backgroundColor?.cgColor
        if self.clearColors.contains(where: { mategramSameColor(color, $0) }) {
            view.backgroundColor = .clear
        } else if let itemColor = self.itemColor, mategramSameColor(color, itemColor), view.bounds.width > 40.0, view.bounds.height > 40.0, view.bounds.width < 600.0 {
            view.backgroundColor = .clear
            self.addGlass(to: view)
        } else if view.viewWithTag(mategramGlassTag)?.superview === view {
            self.addGlass(to: view)
        }
        if let sublayers = view.layer.sublayers {
            for layer in sublayers where layer.delegate == nil {
                if self.clearColors.contains(where: { mategramSameColor(layer.backgroundColor, $0) }) {
                    layer.backgroundColor = UIColor.clear.cgColor
                } else if let itemColor = self.itemColor, mategramSameColor(layer.backgroundColor, itemColor) {
                    layer.backgroundColor = UIColor(white: self.isDark ? 1.0 : 0.0, alpha: self.isDark ? 0.1 : 0.06).cgColor
                }
            }
        }
        for subview in view.subviews {
            self.visit(subview, budget: &budget)
        }
    }

    private func addGlass(to view: UIView) {
        let glass: GlassBackgroundView
        if let current = view.viewWithTag(mategramGlassTag) as? GlassBackgroundView, current.superview === view {
            glass = current
        } else {
            glass = GlassBackgroundView()
            glass.tag = mategramGlassTag
            glass.isUserInteractionEnabled = false
            view.insertSubview(glass, at: 0)
        }
        let size = view.bounds.size
        if glass.frame.size != size {
            glass.frame = CGRect(origin: CGPoint(), size: size)
            let radius = view.layer.cornerRadius > 0.0 ? view.layer.cornerRadius : min(20.0, min(size.width, size.height) * 0.5)
            glass.update(size: size, cornerRadius: radius, isDark: self.isDark, tintColor: .init(kind: .clear), transition: .immediate)
        }
    }

    func update(context: AccountContext, peer: EnginePeer?) {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let theme = presentationData.theme
        self.isDark = theme.overallDarkAppearance
        self.clearColors = [theme.list.blocksBackgroundColor, theme.list.plainBackgroundColor]
        self.itemColor = theme.list.itemBlocksBackgroundColor
        guard let peer, let representation = peer.smallProfileImage else {
            self.currentPeerId = nil
            self.currentRepresentation = nil
            self.disposable.set(nil)
            self.imageView.image = nil
            self.dimView.alpha = 0.0
            return
        }
        if self.currentPeerId == peer.id, let currentRepresentation = self.currentRepresentation, currentRepresentation == representation {
            return
        }
        self.currentPeerId = peer.id
        self.currentRepresentation = representation
        self.disposable.set((peerAvatarCompleteImage(account: context.account, peer: peer, size: CGSize(width: 240.0, height: 240.0), round: false, drawLetters: false, blurred: false)
        |> mapToQueue { image -> Signal<UIImage?, NoError> in
            guard let image else {
                return .single(nil)
            }
            return Signal { subscriber in
                subscriber.putNext(mategramBlurred(image) ?? image)
                subscriber.putCompletion()
                return EmptyDisposable
            } |> runOn(Queue.concurrentDefaultQueue())
        }
        |> deliverOnMainQueue).startStrict(next: { [weak self] image in
            guard let self else {
                return
            }
            self.imageView.image = image
            self.dimView.alpha = image == nil ? 0.0 : 1.0
            self.sweep()
        }))
    }
}

private let mategramBackdropKey = UnsafeRawPointer(bitPattern: 0x6d617465)!

extension PeerInfoScreenNode {
    var mategramBackdrop: MategramProfileBackdrop {
        if let current = objc_getAssociatedObject(self, mategramBackdropKey) as? MategramProfileBackdrop {
            return current
        }
        let backdrop = MategramProfileBackdrop()
        objc_setAssociatedObject(self, mategramBackdropKey, backdrop, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return backdrop
    }
}
