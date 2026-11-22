import Foundation
import UIKit
import AsyncDisplayKit
import Display
import ComponentFlow
import TelegramCore
import TelegramPresentationData
import AccountContext
import EmojiStatusComponent
import MategramCore

final class MategramRoleItem: PeerInfoScreenItem {
    let id: AnyHashable
    let role: MategramRole

    init(id: AnyHashable, role: MategramRole) {
        self.id = id
        self.role = role
    }

    func node() -> PeerInfoScreenItemNode {
        return MategramRoleItemNode()
    }
}

private final class MategramRoleItemNode: PeerInfoScreenItemNode {
    private let textNode = ImmediateTextNode()
    private let captionNode = ImmediateTextNode()
    private let iconView = ComponentView<Empty>()

    override init() {
        super.init()
        self.textNode.displaysAsynchronously = false
        self.textNode.maximumNumberOfLines = 2
        self.captionNode.displaysAsynchronously = false
        self.addSubnode(self.textNode)
        self.addSubnode(self.captionNode)
    }

    override func update(context: AccountContext, width: CGFloat, safeInsets: UIEdgeInsets, presentationData: PresentationData, item: PeerInfoScreenItem, topItem: PeerInfoScreenItem?, bottomItem: PeerInfoScreenItem?, hasCorners: Bool, transition: ContainedViewLayoutTransition) -> CGFloat {
        guard let item = item as? MategramRoleItem else {
            return 10.0
        }
        let theme = presentationData.theme
        let sideInset: CGFloat = 16.0 + safeInsets.left
        let iconSize: CGFloat = 30.0
        let spacing: CGFloat = 12.0
        let russian = presentationData.strings.baseLanguageCode.hasPrefix("ru")
        var textX = sideInset
        if let emojiId = item.role.emojiId {
            let size = self.iconView.update(
                transition: .immediate,
                component: AnyComponent(EmojiStatusComponent(
                    context: context,
                    animationCache: context.animationCache,
                    animationRenderer: context.animationRenderer,
                    content: .animation(content: .customEmoji(fileId: emojiId), size: CGSize(width: 64.0, height: 64.0), placeholderColor: theme.list.mediaPlaceholderColor, themeColor: theme.list.itemAccentColor, loopMode: .forever),
                    isVisibleForAnimations: true,
                    action: nil
                )),
                environment: {},
                containerSize: CGSize(width: iconSize, height: iconSize)
            )
            if let view = self.iconView.view {
                if view.superview == nil {
                    self.view.addSubview(view)
                }
                view.isHidden = false
                view.frame = CGRect(origin: CGPoint(x: sideInset, y: 0.0), size: size)
            }
            textX = sideInset + iconSize + spacing
        } else {
            self.iconView.view?.isHidden = true
        }
        let textWidth = max(1.0, width - textX - 16.0 - safeInsets.right)
        self.textNode.attributedText = NSAttributedString(string: item.role.text, font: Font.semibold(16.0), textColor: theme.list.itemPrimaryTextColor)
        self.captionNode.attributedText = NSAttributedString(string: russian ? "статус MateGram" : "MateGram status", font: Font.regular(13.0), textColor: theme.list.itemSecondaryTextColor)
        let textSize = self.textNode.updateLayout(CGSize(width: textWidth, height: 100.0))
        let captionSize = self.captionNode.updateLayout(CGSize(width: textWidth, height: 40.0))
        let verticalInset: CGFloat = 11.0
        let contentHeight = textSize.height + 2.0 + captionSize.height
        let height = max(iconSize, contentHeight) + verticalInset * 2.0
        let textY = floorToScreenPixels((height - contentHeight) / 2.0)
        self.textNode.frame = CGRect(origin: CGPoint(x: textX, y: textY), size: textSize)
        self.captionNode.frame = CGRect(origin: CGPoint(x: textX, y: textY + textSize.height + 2.0), size: captionSize)
        if let view = self.iconView.view {
            view.frame = CGRect(origin: CGPoint(x: sideInset, y: floorToScreenPixels((height - iconSize) / 2.0)), size: CGSize(width: iconSize, height: iconSize))
        }
        return height
    }
}

func mategramRoleItems(data: PeerInfoScreenData, presentationData: PresentationData) -> [PeerInfoScreenItem] {
    guard let peer = data.peer, case .user = peer else {
        return []
    }
    let russian = presentationData.strings.baseLanguageCode.hasPrefix("ru")
    guard let role = MategramBadges.role(userId: peer.id.id._internalGetInt64Value(), russian: russian) else {
        return []
    }
    return [MategramRoleItem(id: 9100, role: role)]
}
