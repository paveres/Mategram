import Foundation
import UIKit
import ObjectiveC
import SwiftSignalKit
import TelegramCore
import AccountContext
import AvatarNode

final class MategramProfileBackdrop {
    let imageView = UIImageView()
    let dimView = UIView()
    private let disposable = MetaDisposable()
    private var currentPeerId: EnginePeer.Id?
    private var currentRepresentation: TelegramMediaImageRepresentation?

    init() {
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.imageView.isUserInteractionEnabled = false
        self.dimView.isUserInteractionEnabled = false
        self.dimView.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
        self.dimView.alpha = 0.0
    }

    deinit {
        self.disposable.dispose()
    }

    func attach(to view: UIView) {
        if self.imageView.superview !== view {
            view.insertSubview(self.imageView, at: 0)
            view.insertSubview(self.dimView, aboveSubview: self.imageView)
        }
    }

    func layout(size: CGSize) {
        let frame = CGRect(origin: CGPoint(), size: size)
        self.imageView.frame = frame
        self.dimView.frame = frame
    }

    func update(context: AccountContext, peer: EnginePeer?) {
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
        self.disposable.set((peerAvatarCompleteImage(account: context.account, peer: peer, size: CGSize(width: 96.0, height: 96.0), round: false, drawLetters: false, blurred: true)
        |> deliverOnMainQueue).startStrict(next: { [weak self] image in
            guard let self else {
                return
            }
            self.imageView.image = image
            self.dimView.alpha = image == nil ? 0.0 : 1.0
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
