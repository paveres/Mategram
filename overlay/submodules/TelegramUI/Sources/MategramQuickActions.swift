import Foundation
import UIKit
import AsyncDisplayKit
import Display
import ContextUI
import TelegramPresentationData

private final class MategramQuickActionButton: UIControl {
    let iconView = UIImageView()
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.iconView.contentMode = .center
        self.label.textAlignment = .center
        self.label.adjustsFontSizeToFitWidth = true
        self.label.minimumScaleFactor = 0.8
        self.addSubview(self.iconView)
        self.addSubview(self.label)
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    override var isHighlighted: Bool {
        didSet {
            self.alpha = self.isHighlighted ? 0.5 : 1.0
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = self.bounds.size
        self.iconView.frame = CGRect(x: 0.0, y: 10.0, width: size.width, height: 32.0)
        self.label.frame = CGRect(x: 4.0, y: 46.0, width: max(0.0, size.width - 8.0), height: 18.0)
    }
}

final class MategramQuickActionsItem: ContextMenuCustomItem {
    let items: [ContextMenuActionItem]
    let symbols: [String]

    init(items: [ContextMenuActionItem], symbols: [String]) {
        self.items = items
        self.symbols = symbols
    }

    func node(presentationData: PresentationData, getController: @escaping () -> ContextControllerProtocol?, actionSelected: @escaping (ContextMenuActionResult) -> Void) -> ContextMenuCustomNode {
        return MategramQuickActionsNode(presentationData: presentationData, items: self.items, symbols: self.symbols, getController: getController, actionSelected: actionSelected)
    }
}

private final class MategramQuickActionsNode: ASDisplayNode, ContextMenuCustomNode {
    private let items: [ContextMenuActionItem]
    private let symbols: [String]
    private let getController: () -> ContextControllerProtocol?
    private let actionSelected: (ContextMenuActionResult) -> Void
    private var presentationData: PresentationData
    private var buttons: [MategramQuickActionButton] = []

    var needsSeparator: Bool {
        return true
    }

    var needsPadding: Bool {
        return false
    }

    init(presentationData: PresentationData, items: [ContextMenuActionItem], symbols: [String], getController: @escaping () -> ContextControllerProtocol?, actionSelected: @escaping (ContextMenuActionResult) -> Void) {
        self.presentationData = presentationData
        self.items = items
        self.symbols = symbols
        self.getController = getController
        self.actionSelected = actionSelected
        super.init()
    }

    override func didLoad() {
        super.didLoad()
        for index in 0 ..< self.items.count {
            let button = MategramQuickActionButton(frame: CGRect())
            button.tag = index
            button.addTarget(self, action: #selector(self.buttonPressed(_:)), for: .touchUpInside)
            self.view.addSubview(button)
            self.buttons.append(button)
        }
        self.applyTheme()
    }

    private func applyTheme() {
        for (index, button) in self.buttons.enumerated() {
            let item = self.items[index]
            let color: UIColor
            if case .destructive = item.textColor {
                color = self.presentationData.theme.contextMenu.destructiveColor
            } else {
                color = self.presentationData.theme.contextMenu.primaryColor
            }
            if index < self.symbols.count, let symbolImage = UIImage(systemName: self.symbols[index], withConfiguration: UIImage.SymbolConfiguration(pointSize: 24.0, weight: .medium)) {
                button.iconView.image = symbolImage.withRenderingMode(.alwaysTemplate)
            } else {
                button.iconView.image = item.icon(self.presentationData.theme)?.withRenderingMode(.alwaysTemplate)
            }
            button.iconView.tintColor = color
            button.label.text = item.text
            button.label.font = Font.regular(12.0)
            button.label.textColor = color
        }
    }

    @objc private func buttonPressed(_ sender: UIControl) {
        let item = self.items[sender.tag]
        let actionSelected = self.actionSelected
        item.action?(ContextMenuActionItem.Action(controller: self.getController(), dismissWithResult: { result in
            actionSelected(result)
        }, updateAction: { _, _ in
        }))
    }

    func updateLayout(constrainedWidth: CGFloat, constrainedHeight: CGFloat) -> (CGSize, (CGSize, ContainedViewLayoutTransition) -> Void) {
        let width = max(constrainedWidth, 220.0)
        let size = CGSize(width: min(width, 280.0), height: 72.0)
        return (size, { [weak self] size, _ in
            guard let self else {
                return
            }
            let count = max(1, self.buttons.count)
            let buttonWidth = floor((size.width - 8.0) / CGFloat(count))
            for (index, button) in self.buttons.enumerated() {
                button.frame = CGRect(x: 4.0 + CGFloat(index) * buttonWidth, y: 0.0, width: buttonWidth, height: size.height)
            }
        })
    }

    func updateTheme(presentationData: PresentationData) {
        self.presentationData = presentationData
        self.applyTheme()
    }

    func canBeHighlighted() -> Bool {
        return false
    }

    func updateIsHighlighted(isHighlighted: Bool) {
    }

    func performAction() {
    }
}

func mategramQuickActions(_ actions: [ContextMenuItem], strings: PresentationStrings) -> [ContextMenuItem] {
    let order = [strings.Conversation_ContextMenuSelect, strings.Conversation_ContextMenuCopy, strings.Conversation_ContextMenuDelete]
    var found: [String: ContextMenuActionItem] = [:]
    var rest: [ContextMenuItem] = []
    for item in actions {
        if case let .action(action) = item, order.contains(action.text), found[action.text] == nil {
            found[action.text] = action
        } else {
            rest.append(item)
        }
    }
    let symbolByText: [String: String] = [
        strings.Conversation_ContextMenuSelect: "checkmark.circle.fill",
        strings.Conversation_ContextMenuCopy: "doc.on.doc.fill",
        strings.Conversation_ContextMenuDelete: "trash.fill"
    ]
    let quick = order.compactMap { found[$0] }
    let symbols = quick.map { symbolByText[$0.text] ?? "circle.fill" }
    if quick.isEmpty {
        return actions
    }
    while let first = rest.first, case .separator = first {
        rest.removeFirst()
    }
    return [.custom(MategramQuickActionsItem(items: quick, symbols: symbols), false)] + rest
}
