import Foundation
import UIKit
import Display
import AttachmentUI
import TelegramCore
import TelegramPresentationData
import MategramCore

func mategramAttachKey(_ button: AttachmentButtonType) -> String {
    switch button {
    case .gallery:
        return "gallery"
    case .file:
        return "file"
    case .money:
        return "money"
    case .location:
        return "location"
    case .todo:
        return "todo"
    case .quickReply:
        return "quickReply"
    case .contact:
        return "contact"
    case .poll:
        return "poll"
    case let .app(bot):
        return "app\(bot.peer.id.toInt64())"
    case .gift:
        return "gift"
    case .sticker:
        return "sticker"
    case .emoji:
        return "emoji"
    case .audio:
        return "audio"
    case .link:
        return "link"
    case .richText:
        return "richText"
    case .standalone:
        return "standalone"
    }
}

extension ChatControllerImpl {
    func mategramPresentAttachMenu(sourceView: UIView, buttons: [AttachmentButtonType]) {
        let strings = self.presentationData.strings
        let isRussian = strings.baseLanguageCode.hasPrefix("ru")
        let mainOrder: [(String, String, String, UIColor)] = [
            ("gallery", strings.Attachment_Gallery, "photo.on.rectangle", UIColor(rgb: 0xf2405b)),
            ("richText", isRussian ? "Статья" : "Article", "doc.richtext", UIColor(rgb: 0x8e8e93)),
            ("gift", strings.Attachment_Gift, "gift.fill", UIColor(rgb: 0xf2405b)),
            ("file", strings.Attachment_File, "doc.fill", UIColor(rgb: 0x2f8cf5)),
            ("location", strings.Attachment_Location, "mappin.circle.fill", UIColor(rgb: 0x34c759)),
            ("todo", strings.Attachment_Todo, "checklist", UIColor(rgb: 0xf5c400)),
            ("audio", strings.Attachment_Audio, "play.circle.fill", UIColor(rgb: 0xf2405b)),
            ("contact", strings.Attachment_Contact, "person.crop.circle.fill", UIColor(rgb: 0xf39a1f))
        ]
        var available: [String: AttachmentButtonType] = [:]
        for button in buttons {
            available[mategramAttachKey(button)] = button
        }
        let canGift: Bool
        if let user = self.presentationInterfaceState.renderedPeer?.peer as? TelegramUser, user.id != self.context.account.peerId, user.botInfo == nil {
            canGift = true
        } else {
            canGift = false
        }

        let open: (String) -> Void = { [weak self] key in
            guard let self else {
                return
            }
            if key == "gift" && available["gift"] == nil {
                MategramAttach.forced = "gift"
                self.presentAttachmentMenu(subject: .gift)
                return
            }
            MategramAttach.forced = key
            self.presentAttachmentMenu(subject: .default)
        }

        var items: [MategramAttachPanelItem] = []
        var keys: [String] = []
        var used = Set<String>()
        for (key, title, symbol, color) in mainOrder {
            if available[key] == nil && !(key == "gift" && canGift) {
                continue
            }
            used.insert(key)
            keys.append(key)
            items.append(MategramAttachPanelItem(title: title, symbol: symbol, color: color))
        }
        for button in buttons {
            let key = mategramAttachKey(button)
            if used.contains(key) {
                continue
            }
            let title: String
            let symbol: String
            let color: UIColor
            switch button {
            case .poll:
                title = strings.Attachment_Poll
                symbol = "chart.bar.fill"
                color = UIColor(rgb: 0xf5c400)
            case .money:
                title = strings.Attachment_Money
                symbol = "creditcard.fill"
                color = UIColor(rgb: 0x34c759)
            case .quickReply:
                title = strings.Attachment_Reply
                symbol = "arrowshape.turn.up.left.fill"
                color = UIColor(rgb: 0x2f8cf5)
            case let .app(bot):
                title = bot.shortName
                symbol = "square.grid.2x2.fill"
                color = UIColor(rgb: 0x5e5ce6)
            default:
                continue
            }
            used.insert(key)
            keys.append(key)
            items.append(MategramAttachPanelItem(title: title, symbol: symbol, color: color))
        }
        if items.isEmpty {
            MategramAttach.forced = "gallery"
            self.presentAttachmentMenu(subject: .default)
            return
        }
        self.chatDisplayNode.dismissInput()
        let container: UIView = self.view.window ?? self.view
        let panel = MategramAttachPanel(items: items, isDark: self.presentationData.theme.overallDarkAppearance, select: { index in
            open(keys[index])
        })
        panel.show(in: container, anchor: sourceView.convert(sourceView.bounds, to: container))
    }
}
