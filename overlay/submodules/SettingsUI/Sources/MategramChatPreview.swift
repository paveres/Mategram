import Foundation
import UIKit
import Display
import TelegramCore
import TelegramPresentationData
import ItemListUI
import AccountContext

public func mategramChatPreviewItem(context: AccountContext, presentationData: PresentationData, sectionId: ItemListSectionId) -> ListViewItem {
    let strings = presentationData.strings
    let items = [
        ChatPreviewMessageItem(outgoing: false, reply: (strings.Appearance_PreviewReplyAuthor, strings.Appearance_PreviewReplyText), text: strings.Appearance_PreviewIncomingText, nameColor: .preset(.blue), backgroundEmojiId: nil),
        ChatPreviewMessageItem(outgoing: true, reply: nil, text: strings.Appearance_PreviewOutgoingText, nameColor: .preset(.blue), backgroundEmojiId: nil)
    ]
    return ThemeSettingsChatPreviewItem(context: context, systemStyle: .glass, theme: presentationData.theme, componentTheme: presentationData.theme, strings: strings, sectionId: sectionId, fontSize: presentationData.chatFontSize, chatBubbleCorners: presentationData.chatBubbleCorners, wallpaper: presentationData.chatWallpaper, dateTimeFormat: presentationData.dateTimeFormat, nameDisplayOrder: presentationData.nameDisplayOrder, messageItems: items)
}
