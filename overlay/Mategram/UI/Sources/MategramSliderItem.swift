import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import ComponentFlow
import SliderComponent

final class MategramSliderItem: ListViewItem, ItemListItem {
    let theme: PresentationTheme
    let title: String
    let value: Int
    let minValue: Int
    let maxValue: Int
    let format: (Int) -> String
    let sectionId: ItemListSectionId
    let updated: (Int) -> Void

    init(theme: PresentationTheme, title: String, value: Int, minValue: Int, maxValue: Int, format: @escaping (Int) -> String, sectionId: ItemListSectionId, updated: @escaping (Int) -> Void) {
        self.theme = theme
        self.title = title
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.format = format
        self.sectionId = sectionId
        self.updated = updated
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, neighbors: ListViewItemNeighbors, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = MategramSliderItemNode()
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
            if let nodeValue = node() as? MategramSliderItemNode {
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
}

final class MategramSliderItemNode: ListViewItemNode {
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode
    private let titleNode: ImmediateTextNode
    private let valueNode: ImmediateTextNode
    private let slider = ComponentView<Empty>()

    private var item: MategramSliderItem?
    private var layoutParams: ListViewItemLayoutParams?
    private var currentValue: Int = 0

    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        self.maskNode = ASImageNode()
        self.titleNode = ImmediateTextNode()
        self.valueNode = ImmediateTextNode()
        super.init(layerBacked: false)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.valueNode)
    }

    private func layoutValueLabel() {
        guard let item = self.item, let params = self.layoutParams else {
            return
        }
        self.valueNode.attributedText = NSAttributedString(string: item.format(self.currentValue), font: Font.regular(17.0), textColor: item.theme.list.itemSecondaryTextColor)
        let size = self.valueNode.updateLayout(CGSize(width: 160.0, height: 30.0))
        self.valueNode.frame = CGRect(origin: CGPoint(x: params.width - params.rightInset - 16.0 - size.width, y: 15.0), size: size)
    }

    func asyncLayout() -> (_ item: MategramSliderItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        return { [weak self] item, params, neighbors in
            let separatorHeight = UIScreenPixel
            let contentSize = CGSize(width: params.width, height: 96.0)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size

            return (layout, { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.item = item
                strongSelf.layoutParams = params
                strongSelf.currentValue = item.value

                strongSelf.backgroundNode.backgroundColor = item.theme.list.itemBlocksBackgroundColor
                strongSelf.topStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                strongSelf.bottomStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                if strongSelf.backgroundNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                }
                if strongSelf.topStripeNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.topStripeNode, at: 1)
                }
                if strongSelf.bottomStripeNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.bottomStripeNode, at: 2)
                }
                if strongSelf.maskNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.maskNode, at: 3)
                }

                let hasCorners = itemListHasRoundedBlockLayout(params)
                var hasTopCorners = false
                var hasBottomCorners = false
                switch neighbors.top {
                case .sameSection(false):
                    strongSelf.topStripeNode.isHidden = true
                default:
                    hasTopCorners = true
                    strongSelf.topStripeNode.isHidden = hasCorners
                }
                let bottomStripeInset: CGFloat
                let bottomStripeOffset: CGFloat
                switch neighbors.bottom {
                case .sameSection(false):
                    bottomStripeInset = params.leftInset + 16.0
                    bottomStripeOffset = -separatorHeight
                    strongSelf.bottomStripeNode.isHidden = false
                default:
                    bottomStripeInset = 0.0
                    bottomStripeOffset = 0.0
                    hasBottomCorners = true
                    strongSelf.bottomStripeNode.isHidden = hasCorners
                }

                strongSelf.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(item.theme, top: hasTopCorners, bottom: hasBottomCorners, glass: true) : nil
                strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))
                strongSelf.maskNode.frame = strongSelf.backgroundNode.frame.inset(by: UIEdgeInsets(top: 0.0, left: params.leftInset, bottom: 0.0, right: params.rightInset))
                strongSelf.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight))
                strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layoutSize.width - bottomStripeInset - params.rightInset - 16.0, height: separatorHeight))

                strongSelf.titleNode.attributedText = NSAttributedString(string: item.title, font: Font.regular(17.0), textColor: item.theme.list.itemPrimaryTextColor)
                let titleSize = strongSelf.titleNode.updateLayout(CGSize(width: params.width - params.leftInset - params.rightInset - 160.0, height: 30.0))
                strongSelf.titleNode.frame = CGRect(origin: CGPoint(x: params.leftInset + 16.0, y: 15.0), size: titleSize)
                strongSelf.layoutValueLabel()

                let range = CGFloat(max(1, item.maxValue - item.minValue))
                let sliderValue = max(0.0, min(1.0, CGFloat(item.value - item.minValue) / range))
                let sliderSize = strongSelf.slider.update(
                    transition: .immediate,
                    component: AnyComponent(
                        SliderComponent(
                            content: .continuous(.init(
                                value: sliderValue,
                                minValue: nil,
                                valueUpdated: { [weak self] value in
                                    guard let self, let item = self.item else {
                                        return
                                    }
                                    let resolved = item.minValue + Int((value * CGFloat(item.maxValue - item.minValue)).rounded())
                                    if resolved != self.currentValue {
                                        self.currentValue = resolved
                                        self.layoutValueLabel()
                                        item.updated(resolved)
                                    }
                                }
                            )),
                            useNative: true,
                            trackBackgroundColor: item.theme.list.itemSwitchColors.frameColor,
                            trackForegroundColor: item.theme.list.itemAccentColor,
                            accessibilityLabel: item.title,
                            accessibilityValue: item.format(item.value)
                        )
                    ),
                    environment: {},
                    containerSize: CGSize(width: params.width - params.leftInset - params.rightInset - 15.0 * 2.0, height: 44.0)
                )
                if let sliderView = strongSelf.slider.view {
                    if sliderView.superview == nil {
                        strongSelf.view.addSubview(sliderView)
                    }
                    sliderView.frame = CGRect(origin: CGPoint(x: params.leftInset + 15.0, y: 46.0), size: sliderSize)
                }
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
