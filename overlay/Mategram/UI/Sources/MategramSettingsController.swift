import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import MategramCore

private final class MategramSettingsArguments {
    let toggle: (MategramKey, Bool) -> Void

    init(toggle: @escaping (MategramKey, Bool) -> Void) {
        self.toggle = toggle
    }
}

private enum MategramSettingsEntry: ItemListNodeEntry {
    case header(index: Int32, section: Int32, text: String)
    case toggle(index: Int32, section: Int32, key: MategramKey, title: String, value: Bool)
    case footer(index: Int32, section: Int32, text: String)

    var section: ItemListSectionId {
        switch self {
        case let .header(_, section, _):
            return section
        case let .toggle(_, section, _, _, _):
            return section
        case let .footer(_, section, _):
            return section
        }
    }

    var stableId: Int32 {
        switch self {
        case let .header(index, _, _):
            return index
        case let .toggle(index, _, _, _, _):
            return index
        case let .footer(index, _, _):
            return index
        }
    }

    static func <(lhs: MategramSettingsEntry, rhs: MategramSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! MategramSettingsArguments
        switch self {
        case let .header(_, section, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .toggle(_, section, key, title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: section, style: .blocks, updated: { value in
                arguments.toggle(key, value)
            })
        case let .footer(_, section, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
        }
    }
}

private func mategramSettingsEntries(language: MategramLanguage) -> [MategramSettingsEntry] {
    let settings = MategramSettings.shared
    var entries: [MategramSettingsEntry] = []
    var index: Int32 = 0

    func nextIndex() -> Int32 {
        index += 1
        return index
    }

    entries.append(.header(index: nextIndex(), section: 1, text: MategramText.sectionProfile.string(language).uppercased()))
    entries.append(.toggle(index: nextIndex(), section: 1, key: .showProfileId, title: MategramText.profileId.string(language), value: settings.bool(.showProfileId)))
    entries.append(.toggle(index: nextIndex(), section: 1, key: .showDataCenter, title: MategramText.dataCenter.string(language), value: settings.bool(.showDataCenter)))
    entries.append(.toggle(index: nextIndex(), section: 1, key: .showMutualContact, title: MategramText.mutualContact.string(language), value: settings.bool(.showMutualContact)))
    entries.append(.toggle(index: nextIndex(), section: 1, key: .showRegistrationDate, title: MategramText.registrationDate.string(language), value: settings.bool(.showRegistrationDate)))
    entries.append(.footer(index: nextIndex(), section: 1, text: MategramText.sectionProfileFooter.string(language)))

    entries.append(.header(index: nextIndex(), section: 2, text: MategramText.sectionStatus.string(language).uppercased()))
    entries.append(.toggle(index: nextIndex(), section: 2, key: .preciseLastSeen, title: MategramText.preciseLastSeen.string(language), value: settings.bool(.preciseLastSeen)))
    entries.append(.footer(index: nextIndex(), section: 2, text: MategramText.preciseLastSeenFooter.string(language)))

    return entries
}

public func mategramSettingsController(context: AccountContext) -> ViewController {
    let refresh = ValuePromise<Int>(0, ignoreRepeated: false)
    var counter = 0

    let arguments = MategramSettingsArguments(toggle: { key, value in
        MategramSettings.shared.set(value, for: key)
        counter += 1
        refresh.set(counter)
    })

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        refresh.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let language = MategramLanguage(code: presentationData.strings.baseLanguageCode)
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(MategramText.settingsTitle.string(language)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: mategramSettingsEntries(language: language), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
