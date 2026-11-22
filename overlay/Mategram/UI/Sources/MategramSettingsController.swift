import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import MategramCore
import UndoUI
import SettingsUI

private final class MategramHeaderItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    let version: String
    let sectionId: ItemListSectionId
    let isAlwaysPlain: Bool = true
    let tag: ItemListItemTag? = nil

    init(presentationData: ItemListPresentationData, version: String, sectionId: ItemListSectionId) {
        self.presentationData = presentationData
        self.version = version
        self.sectionId = sectionId
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, neighbors: ListViewItemNeighbors, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = MategramHeaderNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topFacet: neighbors.previous?.base(ItemListNeighborFacet.self), bottomFacet: neighbors.next?.base(ItemListNeighborFacet.self)))

            node.contentSize = layout.contentSize
            node.insets = layout.insets

            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }

    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, neighbors: ListViewItemNeighbors, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            guard let nodeValue = node() as? MategramHeaderNode else {
                assertionFailure()
                return
            }

            let makeLayout = nodeValue.asyncLayout()

            async {
                let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topFacet: neighbors.previous?.base(ItemListNeighborFacet.self), bottomFacet: neighbors.next?.base(ItemListNeighborFacet.self)))
                Queue.mainQueue().async {
                    completion(layout, { _ in
                        apply()
                    })
                }
            }
        }
    }
}

private final class MategramHeaderNode: ListViewItemNode, ItemListItemNode {
    private var logoView: UIImageView?
    private var titleLabel: UILabel?
    private var versionLabel: UILabel?

    var tag: ItemListItemTag? {
        return nil
    }

    init() {
        super.init(layerBacked: false)
    }

    private func ensureViews() {
        if self.logoView != nil {
            return
        }
        let logoView = UIImageView()
        let titleLabel = UILabel()
        let versionLabel = UILabel()
        titleLabel.textAlignment = .center
        versionLabel.textAlignment = .center
        self.view.addSubview(logoView)
        self.view.addSubview(titleLabel)
        self.view.addSubview(versionLabel)
        self.logoView = logoView
        self.titleLabel = titleLabel
        self.versionLabel = versionLabel
    }

    func asyncLayout() -> (_ item: MategramHeaderItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        return { [weak self] item, params, neighbors in
            let contentSize = CGSize(width: params.width, height: 250.0)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)

            return (layout, {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.ensureViews()
                let textColor = item.presentationData.theme.list.itemPrimaryTextColor
                let secondaryColor = item.presentationData.theme.list.itemSecondaryTextColor

                let logoSide: CGFloat = 160.0
                strongSelf.logoView?.image = MategramLogo.image(size: CGSize(width: logoSide, height: logoSide), color: textColor, scale: 3.4)
                strongSelf.logoView?.frame = CGRect(x: floor((params.width - logoSide) / 2.0), y: 6.0, width: logoSide, height: logoSide)

                strongSelf.titleLabel?.text = "Mategram"
                strongSelf.titleLabel?.font = Font.bold(34.0)
                strongSelf.titleLabel?.textColor = textColor
                strongSelf.titleLabel?.frame = CGRect(x: 0.0, y: 168.0, width: params.width, height: 42.0)

                strongSelf.versionLabel?.text = item.version
                strongSelf.versionLabel?.font = Font.semibold(20.0)
                strongSelf.versionLabel?.textColor = secondaryColor
                strongSelf.versionLabel?.frame = CGRect(x: 0.0, y: 210.0, width: params.width, height: 28.0)
            })
        }
    }

    override func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }

    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}

private final class MategramSettingsArguments {
    let toggle: (MategramKey, Bool) -> Void
    let openSection: (MategramSection) -> Void
    let updateText: (MategramTextKey, String) -> Void
    let backup: (Bool) -> Void
    var context: AccountContext?
    var openValue: (MategramValueKey) -> Void = { _ in }
    var setValue: (MategramValueKey, Int) -> Void = { _, _ in }
    var setValueSilently: (MategramValueKey, Int) -> Void = { _, _ in }
    var openFont: () -> Void = {}
    var setFont: (String) -> Void = { _ in }

    init(toggle: @escaping (MategramKey, Bool) -> Void, openSection: @escaping (MategramSection) -> Void, updateText: @escaping (MategramTextKey, String) -> Void = { _, _ in }, backup: @escaping (Bool) -> Void = { _ in }) {
        self.toggle = toggle
        self.openSection = openSection
        self.updateText = updateText
        self.backup = backup
    }
}

private enum MategramSettingsEntry: ItemListNodeEntry {
    case header(section: Int32, version: String)
    case sectionRow(index: Int32, section: Int32, kind: MategramSection, title: String, subtitle: String)
    case toggle(index: Int32, section: Int32, key: MategramKey, title: String, value: Bool)
    case footer(index: Int32, section: Int32, text: String)
    case textHeader(index: Int32, section: Int32, text: String)
    case textInput(index: Int32, section: Int32, key: MategramTextKey, placeholder: String, value: String)
    case backupAction(index: Int32, section: Int32, isExport: Bool, title: String)
    case preview(section: Int32, glass: Bool)
    case valueRow(index: Int32, section: Int32, key: MategramValueKey, title: String, value: String)
    case valuePreset(index: Int32, section: Int32, key: MategramValueKey, value: Int, title: String, checked: Bool)
    case valueCustom(index: Int32, section: Int32, key: MategramValueKey, text: String, placeholder: String)
    case fontRow(index: Int32, section: Int32, title: String, value: String)
    case fontOption(index: Int32, section: Int32, family: String, title: String, checked: Bool)
    case infoRow(index: Int32, section: Int32, title: String, value: String)

    var section: ItemListSectionId {
        switch self {
        case let .header(section, _):
            return section
        case let .sectionRow(_, section, _, _, _):
            return section
        case let .toggle(_, section, _, _, _):
            return section
        case let .footer(_, section, _):
            return section
        case let .textHeader(_, section, _):
            return section
        case let .textInput(_, section, _, _, _):
            return section
        case let .backupAction(_, section, _, _):
            return section
        case let .preview(section, _):
            return section
        case let .valueRow(_, section, _, _, _):
            return section
        case let .valuePreset(_, section, _, _, _, _):
            return section
        case let .valueCustom(_, section, _, _, _):
            return section
        case let .fontRow(_, section, _, _):
            return section
        case let .fontOption(_, section, _, _, _):
            return section
        case let .infoRow(_, section, _, _):
            return section
        }
    }

    var stableId: Int32 {
        switch self {
        case .header:
            return 0
        case let .sectionRow(index, _, _, _, _):
            return index
        case let .toggle(index, _, _, _, _):
            return index
        case let .footer(index, _, _):
            return index
        case let .textHeader(index, _, _):
            return index
        case let .textInput(index, _, _, _, _):
            return index
        case let .backupAction(index, _, _, _):
            return index
        case .preview:
            return -1
        case let .valueRow(index, _, _, _, _):
            return index
        case let .valuePreset(index, _, _, _, _, _):
            return index
        case let .valueCustom(index, _, _, _, _):
            return index
        case let .fontRow(index, _, _, _):
            return index
        case let .fontOption(index, _, _, _, _):
            return index
        case let .infoRow(index, _, _, _):
            return index
        }
    }

    static func <(lhs: MategramSettingsEntry, rhs: MategramSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! MategramSettingsArguments
        switch self {
        case let .header(section, version):
            return MategramHeaderItem(presentationData: presentationData, version: version, sectionId: section)
        case let .sectionRow(_, section, kind, title, subtitle):
            let icon = MategramLogo.symbol(kind.symbol, color: presentationData.theme.list.itemPrimaryTextColor)
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: icon, title: title, label: subtitle, labelStyle: .multilineDetailText, sectionId: section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openSection(kind)
            })
        case let .toggle(_, section, key, title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: section, style: .blocks, updated: { value in
                arguments.toggle(key, value)
            })
        case let .footer(_, section, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
        case let .textHeader(_, section, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .textInput(_, section, key, placeholder, value):
            return ItemListMultilineInputItem(presentationData: presentationData, systemStyle: .glass, text: value, placeholder: placeholder, maxLength: nil, sectionId: section, style: .blocks, capitalization: false, autocorrection: false, textUpdated: { text in
                arguments.updateText(key, text)
            })
        case let .backupAction(_, section, isExport, title):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: title, kind: .generic, alignment: .natural, sectionId: section, style: .blocks, action: {
                arguments.backup(isExport)
            })
        case let .preview(section, _):
            if let context = arguments.context {
                return mategramChatPreviewItem(context: context, presentationData: context.sharedContext.currentPresentationData.with { $0 }, sectionId: section)
            }
            return ItemListTextItem(presentationData: presentationData, text: .plain(""), sectionId: section)
        case let .valueRow(_, section, key, title, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: value, sectionId: section, style: .blocks, action: {
                arguments.openValue(key)
            })
        case let .valuePreset(_, section, key, value, title, checked):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: title, style: .left, checked: checked, zeroSeparatorInsets: false, sectionId: section, action: {
                arguments.setValue(key, value)
            })
        case let .valueCustom(_, section, key, text, placeholder):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: NSAttributedString(), text: text, placeholder: placeholder, type: .number, sectionId: section, textUpdated: { value in
                if let number = Int(value.trimmingCharacters(in: .whitespaces)) {
                    arguments.setValueSilently(key, number)
                }
            }, action: {
            })
        case let .fontRow(_, section, title, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: value, sectionId: section, style: .blocks, action: {
                arguments.openFont()
            })
        case let .fontOption(_, section, family, title, checked):
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, title: title, style: .left, checked: checked, zeroSeparatorInsets: false, sectionId: section, action: {
                arguments.setFont(family)
            })
        case let .infoRow(_, section, title, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: value, sectionId: section, style: .blocks, disclosureStyle: .none, action: nil)
        }
    }
}

private func mategramVersionString() -> String {
    let info = Bundle.main.infoDictionary
    let version = (info?["CFBundleShortVersionString"] as? String) ?? ""
    let build = (info?["CFBundleVersion"] as? String) ?? ""
    return build.isEmpty ? version : "\(version) (\(build))"
}

private func mategramMainEntries(language: MategramLanguage) -> [MategramSettingsEntry] {
    var entries: [MategramSettingsEntry] = [.header(section: 0, version: mategramVersionString())]
    var index: Int32 = 0
    for section in MategramSection.allCases {
        index += 1
        entries.append(.sectionRow(index: index, section: 1, kind: section, title: section.title(language), subtitle: section.subtitle(language)))
    }
    entries.append(.backupAction(index: 100, section: 2, isExport: true, title: language == .russian ? "Скопировать настройки" : "Copy settings"))
    entries.append(.backupAction(index: 101, section: 2, isExport: false, title: language == .russian ? "Вставить настройки из буфера" : "Paste settings from clipboard"))
    entries.append(.footer(index: 102, section: 2, text: language == .russian ? "Все переключатели Mategram копируются одной строкой. Вставьте её на другом устройстве или после переустановки." : "All Mategram switches are copied as one line. Paste it on another device or after reinstalling."))
    return entries
}

private func mategramSectionEntries(section: MategramSection, language: MategramLanguage) -> [MategramSettingsEntry] {
    let settings = MategramSettings.shared
    var entries: [MategramSettingsEntry] = []
    var index: Int32 = 0
    var sectionId: Int32 = 0
    if section == .liquidGlass {
        entries.append(.preview(section: 0, glass: MategramSettings.shared.bool(.glassMessages)))
    }
    if section == .ghost {
        let isRussian = language == .russian
        let ghostOn = settings.bool(.ghostMode)
        func state(_ hidden: Bool) -> String {
            if isRussian {
                return hidden ? "Скрыто" : "Видно"
            }
            return hidden ? "Hidden" : "Visible"
        }
        sectionId += 1
        index += 1
        entries.append(.textHeader(index: index, section: sectionId, text: isRussian ? "КАК ВАС ВИДЯТ" : "HOW OTHERS SEE YOU"))
        let rows: [(String, String, Bool)] = [
            ("Прочтение сообщений", "Message reads", ghostOn && settings.bool(.ghostRead)),
            ("«Печатает»", "Typing", ghostOn && (settings.bool(.ghostTyping) || (settings.bool(.ghostOnline) && settings.bool(.ghostTypingFollowsOnline)))),
            ("Онлайн", "Online", ghostOn && settings.bool(.ghostOnline)),
            ("Просмотр историй", "Story views", ghostOn && settings.bool(.ghostStories)),
            ("Прослушивание голосовых", "Voice listened", ghostOn && settings.bool(.ghostContents))
        ]
        for (ru, en, hidden) in rows {
            index += 1
            entries.append(.infoRow(index: index, section: sectionId, title: isRussian ? ru : en, value: state(hidden)))
        }
        index += 1
        entries.append(.footer(index: index, section: sectionId, text: isRussian ? "Так собеседник видит ваши действия при текущих настройках." : "This is what the other side sees with the current settings."))
    }
    if section == .appearance {
        let family = settings.text(.customFont)
        let systemTitle = language == .russian ? "Системный" : "System"
        sectionId += 1
        index += 1
        entries.append(.fontRow(index: index, section: sectionId, title: language == .russian ? "Шрифт" : "Font", value: family.isEmpty ? systemTitle : family))
        index += 1
        entries.append(.footer(index: index, section: sectionId, text: language == .russian ? "Шрифт всего приложения. Применяется после перезапуска." : "Font of the whole app. Applies after a restart."))
    }
    var placedValues = Set<MategramValueKey>()
    for option in MategramCatalog.options(in: section) {
        sectionId += 1
        index += 1
        entries.append(.toggle(index: index, section: sectionId, key: option.key, title: option.title(language), value: settings.bool(option.key)))
        if let valueOption = MategramCatalog.valueOption(for: option.key) {
            placedValues.insert(valueOption.key)
            index += 1
            entries.append(.valueRow(index: index, section: sectionId, key: valueOption.key, title: valueOption.title(language), value: valueOption.key.format(settings.value(valueOption.key), language)))
        }
        var footer = option.footer(language)
        if MategramCatalog.restartKeys.contains(option.key) {
            footer += language == .russian ? " Нужен перезапуск приложения." : " Requires an app restart."
        }
        index += 1
        entries.append(.footer(index: index, section: sectionId, text: footer))
    }
    for option in MategramCatalog.valueOptions(in: section) where !placedValues.contains(option.key) {
        sectionId += 1
        index += 1
        entries.append(.valueRow(index: index, section: sectionId, key: option.key, title: option.title(language), value: option.key.format(settings.value(option.key), language)))
        index += 1
        entries.append(.footer(index: index, section: sectionId, text: option.footer(language)))
    }
    for option in MategramCatalog.textOptions(in: section) {
        sectionId += 1
        index += 1
        entries.append(.textHeader(index: index, section: sectionId, text: option.title(language)))
        index += 1
        entries.append(.textInput(index: index, section: sectionId, key: option.key, placeholder: option.placeholder(language), value: settings.text(option.key)))
    }
    return entries
}

private func mategramValueEntries(key: MategramValueKey, language: MategramLanguage) -> [MategramSettingsEntry] {
    let current = MategramSettings.shared.value(key)
    var entries: [MategramSettingsEntry] = []
    var index: Int32 = 0
    for preset in key.presets {
        index += 1
        entries.append(.valuePreset(index: index, section: 0, key: key, value: preset, title: key.format(preset, language), checked: preset == current))
    }
    index += 1
    entries.append(.textHeader(index: index, section: 1, text: language == .russian ? "СВОЁ ЗНАЧЕНИЕ" : "CUSTOM VALUE"))
    index += 1
    let isSeconds = key == .sendDelay || key == .onlineInterval
    let placeholder = isSeconds ? (language == .russian ? "Секунды" : "Seconds") : (language == .russian ? "Число" : "Number")
    entries.append(.valueCustom(index: index, section: 1, key: key, text: key.presets.contains(current) ? "" : "\(current)", placeholder: placeholder))
    index += 1
    let lower = key.range.lowerBound
    let upper = key.range.upperBound
    entries.append(.footer(index: index, section: 1, text: language == .russian ? "От \(lower) до \(upper)." : "From \(lower) to \(upper)."))
    return entries
}

private func mategramValueController(context: AccountContext, key: MategramValueKey, title: String, changed: @escaping () -> Void) -> ViewController {
    let refresh = ValuePromise<Int>(0, ignoreRepeated: false)
    var counter = 0
    let arguments = MategramSettingsArguments(toggle: { _, _ in
    }, openSection: { _ in
    })
    arguments.setValue = { key, value in
        MategramSettings.shared.setValue(value, for: key)
        counter += 1
        refresh.set(counter)
        changed()
    }
    arguments.setValueSilently = { key, value in
        MategramSettings.shared.setValue(value, for: key)
        changed()
    }
    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, refresh.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let language = MategramLanguage(code: presentationData.strings.baseLanguageCode)
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: mategramValueEntries(key: key, language: language), style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments))
    }
    return ItemListController(context: context, state: signal)
}

private func mategramFontController(context: AccountContext, changed: @escaping () -> Void) -> ViewController {
    let refresh = ValuePromise<Int>(0, ignoreRepeated: false)
    var counter = 0
    let arguments = MategramSettingsArguments(toggle: { _, _ in
    }, openSection: { _ in
    })
    var presentImpl: ((ViewController) -> Void)?
    arguments.setFont = { family in
        MategramSettings.shared.setText(family, for: .customFont)
        counter += 1
        refresh.set(counter)
        changed()
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let isRussian = presentationData.strings.baseLanguageCode.hasPrefix("ru")
        presentImpl?(UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: isRussian ? "Шрифт сменится после перезапуска Mategram." : "The font changes after restarting Mategram.", timeout: nil, customUndoText: nil), elevatedLayout: false, animateInAsReplacement: true, action: { _ in
            return false
        }))
    }
    let families = UIFont.familyNames.sorted()
    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, refresh.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let language = MategramLanguage(code: presentationData.strings.baseLanguageCode)
        let current = MategramSettings.shared.text(.customFont)
        var entries: [MategramSettingsEntry] = []
        var index: Int32 = 0
        index += 1
        entries.append(.fontOption(index: index, section: 0, family: "", title: language == .russian ? "Системный" : "System", checked: current.isEmpty))
        for family in families {
            index += 1
            entries.append(.fontOption(index: index, section: 1, family: family, title: family, checked: family == current))
        }
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(language == .russian ? "Шрифт" : "Font"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments))
    }
    let controller = ItemListController(context: context, state: signal)
    presentImpl = { [weak controller] next in
        controller?.present(next, in: .current)
    }
    return controller
}

private func mategramSettingsSignal(context: AccountContext, refresh: ValuePromise<Int>, arguments: MategramSettingsArguments, section: MategramSection?) -> Signal<(ItemListControllerState, (ItemListNodeState, Any)), NoError> {
    return combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        refresh.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let language = MategramLanguage(code: presentationData.strings.baseLanguageCode)
        let title = section?.title(language) ?? "Mategram"
        let entries: [MategramSettingsEntry]
        if let section {
            entries = mategramSectionEntries(section: section, language: language)
        } else {
            entries = mategramMainEntries(language: language)
        }
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }
}

private func mategramSectionController(context: AccountContext, section: MategramSection) -> ViewController {
    let refresh = ValuePromise<Int>(0, ignoreRepeated: false)
    var counter = 0
    var presentImpl: ((ViewController) -> Void)?
    let arguments = MategramSettingsArguments(toggle: { key, value in
        MategramSettings.shared.set(value, for: key)
        counter += 1
        refresh.set(counter)
        if MategramCatalog.restartKeys.contains(key) {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let isRussian = presentationData.strings.baseLanguageCode.hasPrefix("ru")
            let text = isRussian ? "Перезапустите Mategram, чтобы изменение применилось." : "Restart Mategram to apply this change."
            presentImpl?(UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: text, timeout: nil, customUndoText: nil), elevatedLayout: false, animateInAsReplacement: true, action: { _ in
                return false
            }))
        }
    }, openSection: { _ in
    }, updateText: { key, text in
        MategramSettings.shared.setText(text, for: key)
    })
    arguments.context = context
    var pushImpl: ((ViewController) -> Void)?
    arguments.openValue = { key in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let language = MategramLanguage(code: presentationData.strings.baseLanguageCode)
        let title = MategramCatalog.valueOptions.first(where: { $0.key == key })?.title(language) ?? ""
        pushImpl?(mategramValueController(context: context, key: key, title: title, changed: {
            counter += 1
            refresh.set(counter)
        }))
    }
    arguments.openFont = {
        pushImpl?(mategramFontController(context: context, changed: {
            counter += 1
            refresh.set(counter)
        }))
    }
    let controller = ItemListController(context: context, state: mategramSettingsSignal(context: context, refresh: refresh, arguments: arguments, section: section))
    pushImpl = { [weak controller] next in
        controller?.push(next)
    }
    presentImpl = { [weak controller] next in
        controller?.present(next, in: .current)
    }
    return controller
}

public func mategramSettingsController(context: AccountContext) -> ViewController {
    let refresh = ValuePromise<Int>(0, ignoreRepeated: false)
    var pushControllerImpl: ((ViewController) -> Void)?

    var presentImpl: ((ViewController) -> Void)?
    let arguments = MategramSettingsArguments(toggle: { _, _ in
    }, openSection: { section in
        pushControllerImpl?(mategramSectionController(context: context, section: section))
    }, backup: { isExport in
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let language = MategramLanguage(code: presentationData.strings.baseLanguageCode)
        let text: String
        if isExport {
            UIPasteboard.general.string = MategramBackup.export()
            text = language == .russian ? "Настройки скопированы" : "Settings copied"
        } else if let string = UIPasteboard.general.string, MategramBackup.importSettings(string) {
            text = language == .russian ? "Настройки применены" : "Settings applied"
        } else {
            text = language == .russian ? "В буфере нет настроек Mategram" : "No Mategram settings in clipboard"
        }
        presentImpl?(UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: text, timeout: nil, customUndoText: nil), elevatedLayout: false, animateInAsReplacement: false, action: { _ in
            return false
        }))
    })

    let controller = ItemListController(context: context, state: mategramSettingsSignal(context: context, refresh: refresh, arguments: arguments, section: nil))
    pushControllerImpl = { [weak controller] next in
        controller?.push(next)
    }
    presentImpl = { [weak controller] next in
        controller?.present(next, in: .current)
    }
    return controller
}
