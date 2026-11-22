import Foundation
import UIKit
import ComponentFlow
import GlassBackgroundComponent

struct MategramAttachPanelItem {
    let title: String
    let symbol: String
    let color: UIColor
}

final class MategramAttachPanel: UIView, UIScrollViewDelegate {
    private let items: [MategramAttachPanelItem]
    private let select: (Int) -> Void
    private let isDark: Bool

    private let dimView = UIView()
    private let panel = UIView()
    private let glassView = GlassBackgroundView()
    private let grabber = UIView()
    private let grabberArea = UIView()
    private let scrollView = UIScrollView()
    private var rows: [MategramAttachPanelRow] = []

    private let rowHeight: CGFloat = 50.0
    private let headerHeight: CGFloat = 18.0
    private let bottomInset: CGFloat = 8.0
    private let panelWidth: CGFloat = 250.0
    private var anchor: CGRect = .zero
    private var isDismissing = false
    private var panelHeight: CGFloat = 0.0
    private var minPanelHeight: CGFloat = 0.0
    private var maxPanelHeight: CGFloat = 0.0
    private var panStartHeight: CGFloat = 0.0

    init(items: [MategramAttachPanelItem], isDark: Bool, select: @escaping (Int) -> Void) {
        self.items = items
        self.select = select
        self.isDark = isDark
        super.init(frame: .zero)
        self.overrideUserInterfaceStyle = isDark ? .dark : .light

        self.dimView.backgroundColor = UIColor(white: 0.0, alpha: 0.08)
        self.dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dimTapped)))
        self.addSubview(self.dimView)

        self.panel.layer.shadowColor = UIColor.black.cgColor
        self.panel.layer.shadowOpacity = isDark ? 0.35 : 0.14
        self.panel.layer.shadowRadius = 22.0
        self.panel.layer.shadowOffset = CGSize(width: 0.0, height: 8.0)
        self.addSubview(self.panel)

        self.glassView.isUserInteractionEnabled = false
        self.panel.addSubview(self.glassView)

        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.delegate = self
        self.scrollView.contentInsetAdjustmentBehavior = .never
        self.scrollView.clipsToBounds = true
        self.panel.addSubview(self.scrollView)

        self.grabber.backgroundColor = isDark ? UIColor(white: 1.0, alpha: 0.35) : UIColor(white: 0.0, alpha: 0.25)
        self.grabber.layer.cornerRadius = 2.5
        self.grabber.isUserInteractionEnabled = false
        self.grabberArea.addSubview(self.grabber)
        self.grabberArea.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.grabberPan(_:))))
        self.panel.addSubview(self.grabberArea)

        for (index, item) in items.enumerated() {
            let row = MategramAttachPanelRow(item: item, isDark: isDark)
            row.tag = index
            row.addTarget(self, action: #selector(self.rowTapped(_:)), for: .touchUpInside)
            self.rows.append(row)
            self.scrollView.addSubview(row)
        }
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    func show(in container: UIView, anchor: CGRect) {
        self.anchor = anchor
        self.frame = container.bounds
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(self)
        self.layoutPanel()

        self.dimView.alpha = 0.0
        self.panel.alpha = 0.0
        let panelFrame = self.panel.frame
        self.panel.transform = CGAffineTransform(translationX: -panelFrame.width * 0.35, y: panelFrame.height * 0.35).scaledBy(x: 0.3, y: 0.3)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.animate(withDuration: 0.42, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [.allowUserInteraction], animations: {
            self.panel.transform = .identity
            self.panel.alpha = 1.0
            self.dimView.alpha = 1.0
        })
    }

    func dismiss(completion: (() -> Void)? = nil) {
        guard !self.isDismissing else {
            return
        }
        self.isDismissing = true
        let panelFrame = self.panel.frame
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseIn], animations: {
            self.panel.transform = CGAffineTransform(translationX: -panelFrame.width * 0.3, y: panelFrame.height * 0.3).scaledBy(x: 0.4, y: 0.4)
            self.panel.alpha = 0.0
            self.dimView.alpha = 0.0
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }

    private func layoutPanel() {
        let bounds = self.bounds
        self.dimView.frame = bounds
        let width = min(self.panelWidth, bounds.width - 32.0)
        let topLimit = self.safeAreaInsets.top + 12.0
        let bottom = self.anchor.minY - 8.0
        let listHeight = CGFloat(self.rows.count) * self.rowHeight
        let contentHeight = self.headerHeight + listHeight + self.bottomInset
        self.maxPanelHeight = max(self.headerHeight + self.rowHeight, min(contentHeight, bottom - topLimit))
        self.minPanelHeight = min(self.maxPanelHeight, self.headerHeight + self.rowHeight * CGFloat(min(4, self.rows.count)) + self.bottomInset)
        if self.panelHeight == 0.0 {
            self.panelHeight = self.minPanelHeight
        }
        let height = self.panelHeight

        let transform = self.panel.transform
        self.panel.transform = .identity
        self.panel.frame = CGRect(x: 12.0, y: bottom - height, width: width, height: height)
        self.panel.transform = transform
        self.panel.layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: CGSize(width: width, height: height)), cornerRadius: 26.0).cgPath

        let size = CGSize(width: width, height: height)
        self.glassView.frame = CGRect(origin: .zero, size: size)
        self.glassView.update(size: size, cornerRadius: 26.0, isDark: self.isDark, tintColor: .init(kind: .clear), transition: .immediate)

        self.grabberArea.frame = CGRect(x: 0.0, y: 0.0, width: width, height: self.headerHeight + 6.0)
        self.grabber.frame = CGRect(x: floor((width - 36.0) / 2.0), y: 7.0, width: 36.0, height: 5.0)

        self.scrollView.frame = CGRect(x: 0.0, y: self.headerHeight, width: width, height: max(0.0, height - self.headerHeight))
        self.scrollView.layer.cornerRadius = 0.0
        self.scrollView.contentSize = CGSize(width: width, height: listHeight + self.bottomInset)
        for (index, row) in self.rows.enumerated() {
            row.frame = CGRect(x: 0.0, y: CGFloat(index) * self.rowHeight, width: width, height: self.rowHeight)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !self.isDismissing {
            self.layoutPanel()
        }
    }

    private func snap(velocity: CGFloat) {
        let target: CGFloat
        if velocity < -300.0 {
            target = self.maxPanelHeight
        } else if velocity > 300.0 {
            target = self.minPanelHeight
        } else {
            target = (self.panelHeight - self.minPanelHeight) > (self.maxPanelHeight - self.minPanelHeight) * 0.5 ? self.maxPanelHeight : self.minPanelHeight
        }
        self.panelHeight = target
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.0, options: [.allowUserInteraction], animations: {
            self.layoutPanel()
        })
    }

    @objc private func grabberPan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            self.panStartHeight = self.panelHeight
        case .changed:
            let translation = recognizer.translation(in: self).y
            let proposed = self.panStartHeight - translation
            if proposed < self.minPanelHeight {
                self.panelHeight = self.minPanelHeight
                let pull = self.minPanelHeight - proposed
                self.panel.transform = CGAffineTransform(translationX: 0.0, y: pull * 0.6)
            } else {
                self.panel.transform = .identity
                self.panelHeight = min(self.maxPanelHeight, proposed)
            }
            self.layoutPanel()
        case .ended, .cancelled:
            let velocity = recognizer.velocity(in: self).y
            let translation = recognizer.translation(in: self).y
            if self.panStartHeight - translation < self.minPanelHeight - 50.0 || (self.panelHeight <= self.minPanelHeight + 1.0 && velocity > 900.0) {
                self.dismiss()
                return
            }
            UIView.animate(withDuration: 0.2, animations: {
                self.panel.transform = .identity
            })
            self.snap(velocity: velocity)
        default:
            break
        }
    }

    @objc private func dimTapped() {
        self.dismiss()
    }

    @objc private func rowTapped(_ sender: UIControl) {
        let index = sender.tag
        UISelectionFeedbackGenerator().selectionChanged()
        let select = self.select
        self.dismiss(completion: {
            select(index)
        })
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isDragging else {
            return
        }
        let offset = scrollView.contentOffset.y
        if offset > 0.0 && self.panelHeight < self.maxPanelHeight {
            let grow = min(offset, self.maxPanelHeight - self.panelHeight)
            self.panelHeight += grow
            scrollView.contentOffset.y = offset - grow
            self.layoutPanel()
        } else if offset < 0.0 && self.panelHeight > self.minPanelHeight {
            let shrink = min(-offset, self.panelHeight - self.minPanelHeight)
            self.panelHeight -= shrink
            scrollView.contentOffset.y = offset + shrink
            self.layoutPanel()
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView.contentOffset.y < -60.0 && self.panelHeight <= self.minPanelHeight + 1.0 {
            self.dismiss()
            return
        }
        if self.panelHeight > self.minPanelHeight && self.panelHeight < self.maxPanelHeight {
            self.snap(velocity: -velocity.y * 1000.0)
        }
    }
}

private final class MategramAttachPanelRow: UIControl {
    private let circle = UIView()
    private let icon = UIImageView()
    private let label = UILabel()
    private let isDark: Bool

    init(item: MategramAttachPanelItem, isDark: Bool) {
        self.isDark = isDark
        super.init(frame: .zero)

        self.circle.backgroundColor = item.color
        self.circle.layer.cornerRadius = 16.0
        self.circle.isUserInteractionEnabled = false
        self.addSubview(self.circle)

        self.icon.image = UIImage(systemName: item.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14.0, weight: .semibold))
        self.icon.tintColor = .white
        self.icon.contentMode = .center
        self.circle.addSubview(self.icon)

        self.label.text = item.title
        self.label.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        self.label.textColor = isDark ? .white : .black
        self.label.lineBreakMode = .byTruncatingTail
        self.label.isUserInteractionEnabled = false
        self.addSubview(self.label)
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: self.isHighlighted ? 0.08 : 0.2, animations: {
                self.backgroundColor = self.isHighlighted ? (self.isDark ? UIColor(white: 1.0, alpha: 0.1) : UIColor(white: 0.0, alpha: 0.06)) : .clear
                self.circle.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
            })
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = self.bounds.size
        self.circle.transform = .identity
        self.circle.frame = CGRect(x: 14.0, y: floor((size.height - 32.0) / 2.0), width: 32.0, height: 32.0)
        self.icon.frame = self.circle.bounds
        let labelX: CGFloat = 58.0
        let labelSize = self.label.sizeThatFits(CGSize(width: size.width - labelX - 14.0, height: size.height))
        self.label.frame = CGRect(x: labelX, y: floor((size.height - labelSize.height) / 2.0), width: min(labelSize.width, size.width - labelX - 14.0), height: labelSize.height)
    }
}
