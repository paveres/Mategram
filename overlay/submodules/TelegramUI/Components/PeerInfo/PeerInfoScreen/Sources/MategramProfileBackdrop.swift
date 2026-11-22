import Foundation
import UIKit
import CoreImage
import ObjectiveC
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
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
    private static let instances = NSHashTable<MategramProfileBackdrop>.weakObjects()
    private static let blurCache = NSCache<NSString, UIImage>()

    static func sweepAll() {
        for instance in instances.allObjects {
            instance.sweep()
            if instance.isActive && instance.displayLink == nil {
                instance.startBurst()
            }
        }
    }

    let imageView = UIImageView()
    let dimView = UIView()
    private let disposable = MetaDisposable()
    private var currentPeerId: EnginePeer.Id?
    private var currentRepresentation: TelegramMediaImageRepresentation?
    private weak var rootView: UIView?
    private var timer: Foundation.Timer?
    private var clearColors: [UIColor] = []
    private var itemColor: UIColor?
    private var cornerImages: [CGImage] = []
    private var isDark = true
    private var isActive = false
    private var lastSweep: Double = 0.0
    private var displayLink: CADisplayLink?
    private var burstUntil: Double = 0.0
    private var lastBurstStart: Double = 0.0

    override init() {
        super.init()
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.imageView.isUserInteractionEnabled = false
        self.dimView.isUserInteractionEnabled = false
        self.dimView.backgroundColor = UIColor(white: 0.0, alpha: 0.22)
        self.dimView.alpha = 0.0
        MategramProfileBackdrop.instances.add(self)
    }

    deinit {
        self.disposable.dispose()
        self.timer?.invalidate()
        self.displayLink?.invalidate()
    }

    func startBurst() {
        self.lastBurstStart = CACurrentMediaTime()
        self.burstUntil = self.lastBurstStart + 2.0
        if self.displayLink == nil {
            let link = CADisplayLink(target: self, selector: #selector(self.displayLinkFired))
            link.add(to: RunLoop.main, forMode: .common)
            self.displayLink = link
        }
    }

    @objc private func displayLinkFired() {
        guard let rootView = self.rootView, self.isActive else {
            self.displayLink?.invalidate()
            self.displayLink = nil
            return
        }
        if rootView.window == nil && CACurrentMediaTime() > self.burstUntil {
            self.displayLink?.invalidate()
            self.displayLink = nil
            return
        }
        self.sweep()
    }

    func attach(to view: UIView) {
        if self.imageView.superview !== view || view.subviews.first !== self.imageView {
            view.insertSubview(self.imageView, at: 0)
            view.insertSubview(self.dimView, aboveSubview: self.imageView)
        }
        self.rootView = view
        if self.timer == nil {
            let timer = Foundation.Timer(timeInterval: 0.25, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
    }

    @objc private func timerFired() {
        self.sweep()
    }

    func layout(size: CGSize) {
        let frame = CGRect(origin: CGPoint(), size: size)
        self.imageView.frame = frame
        self.dimView.frame = frame
        self.sweep()
    }

    func sweepThrottled() {
        self.sweep()
        if self.isActive && self.displayLink == nil {
            self.startBurst()
        }
    }

    func sweep() {
        self.lastSweep = CACurrentMediaTime()
        guard let rootView = self.rootView else {
            self.timer?.invalidate()
            self.timer = nil
            return
        }
        if self.imageView.superview === rootView, rootView.subviews.first !== self.imageView {
            rootView.sendSubviewToBack(self.dimView)
            rootView.sendSubviewToBack(self.imageView)
        }
        if self.isActive, self.imageView.image != nil {
            self.imageView.isHidden = false
            self.imageView.alpha = 1.0
            self.dimView.alpha = 1.0
        }
        guard self.isActive, !self.clearColors.isEmpty else {
            return
        }
        if self.displayLink == nil {
            self.startBurst()
        }
        var budget = 8000
        self.visit(rootView, budget: &budget)
    }

    private func isCornerImage(_ view: UIView) -> Bool {
        guard let contents = view.layer.contents else {
            return false
        }
        let object = contents as AnyObject
        for image in self.cornerImages where object === image {
            return true
        }
        return false
    }

    private func visit(_ view: UIView, budget: inout Int) {
        if budget <= 0 || view === self.imageView || view === self.dimView || view is GlassBackgroundView {
            return
        }
        budget -= 1
        if !self.cornerImages.isEmpty, !view.isHidden, self.isCornerImage(view) {
            view.isHidden = true
            return
        }
        if view.isHidden {
            return
        }
        if let imageView = view as? UIImageView, imageView.image != nil, imageView.image?.renderingMode == .alwaysTemplate, let tint = imageView.tintColor, self.clearColors.contains(where: { mategramSameColor(tint.cgColor, $0) }) {
            imageView.isHidden = true
            return
        }
        let color = view.backgroundColor?.cgColor
        let size = view.bounds.size
        if self.clearColors.contains(where: { mategramSameColor(color, $0) }) {
            view.backgroundColor = .clear
        } else if let itemColor = self.itemColor, mategramSameColor(color, itemColor) {
            view.backgroundColor = .clear
            if size.width > 40.0, size.height > 40.0, size.width < 250.0 {
                self.addGlass(to: view)
            }
        } else if let glass = view.viewWithTag(mategramGlassTag), glass.superview === view {
            self.addGlass(to: view)
        }
        if let sublayers = view.layer.sublayers {
            for layer in sublayers where !(layer.delegate is UIView) {
                self.visitLayer(layer, budget: &budget)
            }
        }
        for subview in view.subviews {
            self.visit(subview, budget: &budget)
        }
    }

    private func visitLayer(_ layer: CALayer, budget: inout Int) {
        if budget <= 0 || layer.isHidden {
            return
        }
        budget -= 1
        if !self.cornerImages.isEmpty, let contents = layer.contents {
            let object = contents as AnyObject
            if self.cornerImages.contains(where: { object === $0 }) {
                layer.isHidden = true
                return
            }
        }
        if self.clearColors.contains(where: { mategramSameColor(layer.backgroundColor, $0) }) {
            layer.backgroundColor = UIColor.clear.cgColor
        } else if let itemColor = self.itemColor, mategramSameColor(layer.backgroundColor, itemColor) {
            if layer.bounds.width >= 250.0 {
                layer.backgroundColor = UIColor.clear.cgColor
            } else {
                layer.backgroundColor = UIColor(white: self.isDark ? 1.0 : 0.0, alpha: self.isDark ? 0.1 : 0.06).cgColor
            }
        }
        if let sublayers = layer.sublayers {
            for sublayer in sublayers where !(sublayer.delegate is UIView) {
                self.visitLayer(sublayer, budget: &budget)
            }
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
        var corners: [CGImage] = []
        for (top, bottom) in [(true, false), (false, true), (true, true)] {
            if let image = PresentationResourcesItemList.cornersImage(theme, top: top, bottom: bottom, glass: true)?.cgImage {
                corners.append(image)
            }
            if let image = PresentationResourcesItemList.cornersImage(theme, top: top, bottom: bottom, glass: false)?.cgImage {
                corners.append(image)
            }
        }
        self.cornerImages = corners
        guard let peer else {
            return
        }
        guard let representation = peer.smallProfileImage else {
            self.isActive = false
            self.currentPeerId = nil
            self.currentRepresentation = nil
            self.disposable.set(nil)
            self.imageView.image = nil
            self.dimView.alpha = 0.0
            return
        }
        self.isActive = true
        self.sweep()
        self.startBurst()
        if self.currentPeerId == peer.id, let currentRepresentation = self.currentRepresentation, currentRepresentation == representation {
            return
        }
        self.currentPeerId = peer.id
        self.currentRepresentation = representation
        let cacheKey = "\(peer.id.toInt64())-\(representation.resource.id.stringRepresentation)" as NSString
        if let cached = MategramProfileBackdrop.blurCache.object(forKey: cacheKey) {
            self.imageView.image = cached
            self.dimView.alpha = 1.0
            self.disposable.set(nil)
            self.sweep()
            return
        }
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
            if let image {
                self.imageView.image = image
                MategramProfileBackdrop.blurCache.setObject(image, forKey: cacheKey)
            }
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
