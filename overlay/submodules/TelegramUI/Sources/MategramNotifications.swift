import Foundation
import TelegramCore
import MategramCore

func mategramSkipsNotification(_ message: EngineMessage) -> Bool {
    let settings = MategramSettings.shared
    if settings.bool(.muteMentionNotifications), message.attributes.contains(where: { $0 is ConsumablePersonalMentionMessageAttribute }) {
        return true
    }
    if settings.bool(.mutePinnedNotifications) {
        for media in message.media {
            if let action = media as? TelegramMediaAction, case .pinnedMessageUpdated = action.action {
                return true
            }
        }
    }
    return false
}
