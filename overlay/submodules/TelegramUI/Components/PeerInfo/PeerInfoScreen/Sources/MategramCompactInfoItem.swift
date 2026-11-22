import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
import AccountContext

struct MategramCompactInfoRow {
    let label: String
    let value: String
    let action: ((ASDisplayNode) -> Void)?
}

final class MategramCompactInfoItem: PeerInfoScreenItem {
    let id: AnyHashable
    let rows: [MategramCompactInfoRow]

    init(id: AnyHashable, rows: [MategramCompactInfoRow]) {
        self.id = id
        self.rows = rows
    }

    func node() -> PeerInfoScreenItemNode {
        return MategramCompactInfoItemNode()
    }
}

private final class MategramCompactInfoItemNode: PeerInfoScreenItemNode {
    private var labelNodes: [ImmediateTextNode] = []
    private var valueNodes: [ImmediateTextNode] = []
    private var buttons: [HighlightTrackingButtonNode] = []
    private var item: MategramCompactInfoItem?

    override func update(context: AccountContext, width: CGFloat, safeInsets: UIEdgeInsets, presentationData: PresentationData, item: PeerInfoScreenItem, topItem: PeerInfoScreenItem?, bottomItem: PeerInfoScreenItem?, hasCorners: Bool, transition: ContainedViewLayoutTransition) -> CGFloat {
        guard let item = item as? MategramCompactInfoItem else {
            return 10.0
        }
        self.item = item
        while self.labelNodes.count < item.rows.count {
            let labelNode = ImmediateTextNode()
            labelNode.displaysAsynchronously = false
            let valueNode = ImmediateTextNode()
            valueNode.displaysAsynchronously = false
            let button = HighlightTrackingButtonNode()
            button.addTarget(self, action: #selector(self.rowPressed(_:)), forControlEvents: .touchUpInside)
            self.addSubnode(labelNode)
            self.addSubnode(valueNode)
            self.addSubnode(button)
            self.labelNodes.append(labelNode)
            self.valueNodes.append(valueNode)
            self.buttons.append(button)
        }
        while self.labelNodes.count > item.rows.count {
            self.labelNodes.removeLast().removeFromSupernode()
            self.valueNodes.removeLast().removeFromSupernode()
            self.buttons.removeLast().removeFromSupernode()
        }

        let sideInset: CGFloat = 16.0 + safeInsets.left
        let rowHeight: CGFloat = 26.0
        let verticalInset: CGFloat = 9.0
        let availableWidth = max(1.0, width - safeInsets.left - safeInsets.right - 32.0)
        for (index, row) in item.rows.enumerated() {
            let labelNode = self.labelNodes[index]
            let valueNode = self.valueNodes[index]
            labelNode.attributedText = NSAttributedString(string: row.label + ":", font: Font.regular(14.0), textColor: presentationData.theme.list.itemSecondaryTextColor)
            valueNode.attributedText = NSAttributedString(string: row.value, font: Font.medium(14.0), textColor: presentationData.theme.list.itemPrimaryTextColor)
            let labelSize = labelNode.updateLayout(CGSize(width: availableWidth * 0.5, height: rowHeight))
            let valueSize = valueNode.updateLayout(CGSize(width: max(1.0, availableWidth - labelSize.width - 6.0), height: rowHeight))
            let y = verticalInset + CGFloat(index) * rowHeight
            labelNode.frame = CGRect(origin: CGPoint(x: sideInset, y: y + floorToScreenPixels((rowHeight - labelSize.height) / 2.0)), size: labelSize)
            valueNode.frame = CGRect(origin: CGPoint(x: sideInset + labelSize.width + 6.0, y: y + floorToScreenPixels((rowHeight - valueSize.height) / 2.0)), size: valueSize)
            self.buttons[index].view.tag = index
            self.buttons[index].frame = CGRect(x: safeInsets.left, y: y, width: width - safeInsets.left - safeInsets.right, height: rowHeight)
        }
        return verticalInset * 2.0 + CGFloat(item.rows.count) * rowHeight
    }

    @objc private func rowPressed(_ sender: ASButtonNode) {
        guard let item = self.item else {
            return
        }
        let index = sender.view.tag
        if index >= 0 && index < item.rows.count {
            item.rows[index].action?(self)
        }
    }
}

func mategramCompactInfo(_ items: [PeerInfoScreenItem]) -> [PeerInfoScreenItem] {
    var rows: [MategramCompactInfoRow] = []
    var rest: [PeerInfoScreenItem] = []
    for item in items {
        if let labeled = item as? PeerInfoScreenLabeledValueItem {
            let action = labeled.action
            rows.append(MategramCompactInfoRow(label: labeled.label, value: labeled.text, action: action.map { action in
                return { node in
                    action(node, nil)
                }
            }))
        } else {
            rest.append(item)
        }
    }
    if rows.isEmpty {
        return rest
    }
    return [MategramCompactInfoItem(id: 9000, rows: rows)] + rest
}
