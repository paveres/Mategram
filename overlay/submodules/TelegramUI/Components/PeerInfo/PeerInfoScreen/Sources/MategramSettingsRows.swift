import Foundation
import MategramCore

private func mategramRemove(_ items: inout [SettingsSection: [PeerInfoScreenItem]], _ section: SettingsSection, _ ids: [Int]) {
    items[section]?.removeAll(where: { item in
        if let id = item.id as? Int {
            return ids.contains(id)
        }
        return false
    })
}

func mategramHideSettingsRows(_ items: inout [SettingsSection: [PeerInfoScreenItem]]) {
    let settings = MategramSettings.shared
    let rules: [(MategramKey, SettingsSection, [Int]?)] = [
        (.hideMyProfileRow, .myProfile, [0]),
        (.hideWalletRow, .wallet, nil),
        (.hideProxyRow, .proxy, nil),
        (.hideAppsRow, .apps, nil),
        (.hideSavedRow, .shortcuts, [1]),
        (.hideRecentCallsRow, .shortcuts, [2]),
        (.hideContactsRow, .shortcuts, [21]),
        (.hideDevicesRow, .shortcuts, [3]),
        (.hideFoldersRow, .shortcuts, [4]),
        (.hideNotificationsRow, .advanced, [0]),
        (.hidePrivacyRow, .advanced, [1]),
        (.hideDataRow, .advanced, [2]),
        (.hideAppearanceRow, .advanced, [3]),
        (.hidePowerSavingRow, .advanced, [6]),
        (.hideLanguageRow, .advanced, [4]),
        (.hidePremiumRow, .payment, [100]),
        (.hideStarsRow, .payment, [102]),
        (.hideTonRow, .payment, [103]),
        (.hideBusinessRow, .payment, [104]),
        (.hideGiftRow, .payment, [105]),
        (.hidePassportRow, .extra, [0]),
        (.hideWatchRow, .extra, [1]),
        (.hideSupportRow, .support, [0]),
        (.hideFaqRow, .support, [1]),
        (.hideTipsRow, .support, [2])
    ]
    for (key, section, ids) in rules where settings.bool(key) {
        if let ids {
            mategramRemove(&items, section, ids)
        } else {
            items[section] = []
        }
    }
}
