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

    init(toggle: @escaping (MategramKey, Bool) -> Void, openSection: @escaping (MategramSection) -> Void) {
        self.toggle = toggle
        self.openSection = openSection
    }
}

private enum MategramSettingsEntry: ItemListNodeEntry {
    case header(section: Int32, version: String)
    case sectionRow(index: Int32, section: Int32, kind: MategramSection, title: String, subtitle: String)
    case toggle(index: Int32, section: Int32, key: MategramKey, title: String, value: Bool)
    case footer(index: Int32, section: Int32, text: String)

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
    return entries
}

private func mategramSectionEntries(section: MategramSection, language: MategramLanguage) -> [MategramSettingsEntry] {
    let settings = MategramSettings.shared
    var entries: [MategramSettingsEntry] = []
    var index: Int32 = 0
    var sectionId: Int32 = 0
    for option in MategramCatalog.options(in: section) {
        sectionId += 1
        index += 1
        entries.append(.toggle(index: index, section: sectionId, key: option.key, title: option.title(language), value: settings.bool(option.key)))
        index += 1
        entries.append(.footer(index: index, section: sectionId, text: option.footer(language)))
    }
    return entries
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
    let arguments = MategramSettingsArguments(toggle: { key, value in
        MategramSettings.shared.set(value, for: key)
        counter += 1
        refresh.set(counter)
    }, openSection: { _ in
    })
    return ItemListController(context: context, state: mategramSettingsSignal(context: context, refresh: refresh, arguments: arguments, section: section))
}

public func mategramSettingsController(context: AccountContext) -> ViewController {
    let refresh = ValuePromise<Int>(0, ignoreRepeated: false)
    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = MategramSettingsArguments(toggle: { _, _ in
    }, openSection: { section in
        pushControllerImpl?(mategramSectionController(context: context, section: section))
    })

    let controller = ItemListController(context: context, state: mategramSettingsSignal(context: context, refresh: refresh, arguments: arguments, section: nil))
    pushControllerImpl = { [weak controller] next in
        controller?.push(next)
    }
    return controller
}
