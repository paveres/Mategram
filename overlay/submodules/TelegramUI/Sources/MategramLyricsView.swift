import Foundation
import UIKit
import AVFoundation
import MategramCore

private final class MategramLyricCell: UITableViewCell {
    static let identifier = "MategramLyricCell"

    let lineLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.selectionStyle = .none
        self.lineLabel.numberOfLines = 0
        self.lineLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.lineLabel)
        NSLayoutConstraint.activate([
            self.lineLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 24.0),
            self.lineLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -24.0),
            self.lineLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 11.0),
            self.lineLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -11.0)
        ])
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }
}

final class MategramLyricsView: UIView, UITableViewDataSource, UITableViewDelegate {
    private static let scaleKey = "mategram.lyrics.fontScale"

    var onClose: (() -> Void)?
    var onSeek: ((Double) -> Void)?
    var timeProvider: (() -> Double)?
    var durationProvider: (() -> Double)?

    private let isRussian: Bool
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let dimView = UIView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let sizeButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let messageLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    private var lyrics: MategramLyrics?
    private var rows: [String] = []
    private var isSynced = false
    private var activeIndex: Int?
    private var lastSpoken = -1
    private var displayLink: CADisplayLink?
    private var fontScale: CGFloat
    private var isLoading = false
    private var hasLoaded = false

    init(isRussian: Bool) {
        self.isRussian = isRussian
        let stored = UserDefaults.standard.double(forKey: MategramLyricsView.scaleKey)
        self.fontScale = stored > 0.0 ? CGFloat(stored) : 1.0
        super.init(frame: .zero)

        self.addSubview(self.blurView)
        self.dimView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        self.addSubview(self.dimView)

        self.titleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        self.titleLabel.textColor = .white
        self.artistLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        self.artistLabel.textColor = UIColor(white: 1.0, alpha: 0.7)
        self.addSubview(self.titleLabel)
        self.addSubview(self.artistLabel)

        let config = UIImage.SymbolConfiguration(pointSize: 17.0, weight: .semibold)
        self.closeButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: config), for: .normal)
        self.closeButton.tintColor = .white
        self.closeButton.addTarget(self, action: #selector(self.closePressed), for: .touchUpInside)
        self.addSubview(self.closeButton)

        self.sizeButton.setImage(UIImage(systemName: "textformat.size", withConfiguration: config), for: .normal)
        self.sizeButton.tintColor = .white
        self.sizeButton.showsMenuAsPrimaryAction = true
        self.addSubview(self.sizeButton)
        self.rebuildSizeMenu()

        self.tableView.backgroundColor = .clear
        self.tableView.separatorStyle = .none
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 48.0
        self.tableView.register(MategramLyricCell.self, forCellReuseIdentifier: MategramLyricCell.identifier)
        self.addSubview(self.tableView)

        self.messageLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        self.messageLabel.textColor = UIColor(white: 1.0, alpha: 0.6)
        self.messageLabel.textAlignment = .center
        self.messageLabel.numberOfLines = 0
        self.addSubview(self.messageLabel)

        self.spinner.color = .white
        self.spinner.hidesWhenStopped = true
        self.addSubview(self.spinner)
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    deinit {
        self.displayLink?.invalidate()
    }

    private func text(_ ru: String, _ en: String) -> String {
        return self.isRussian ? ru : en
    }

    private func rebuildSizeMenu() {
        let options: [(String, CGFloat)] = [
            (self.text("Мелкий", "Small"), 0.85),
            (self.text("Обычный", "Regular"), 1.0),
            (self.text("Крупный", "Large"), 1.2),
            (self.text("Очень крупный", "Huge"), 1.4)
        ]
        let actions = options.map { option -> UIAction in
            let action = UIAction(title: option.0, state: abs(self.fontScale - option.1) < 0.01 ? .on : .off) { [weak self] _ in
                self?.setScale(option.1)
            }
            return action
        }
        self.sizeButton.menu = UIMenu(title: self.text("Размер текста", "Text size"), children: actions)
    }

    private func setScale(_ value: CGFloat) {
        self.fontScale = value
        UserDefaults.standard.set(Double(value), forKey: MategramLyricsView.scaleKey)
        self.rebuildSizeMenu()
        self.tableView.reloadData()
        self.scrollToActive(animated: false)
    }

    func setTrack(title: String, artist: String) {
        self.titleLabel.text = title
        self.artistLabel.text = artist
    }

    func setLoading() {
        self.lyrics = nil
        self.rows = []
        self.isSynced = false
        self.activeIndex = nil
        self.lastSpoken = -1
        self.isLoading = true
        self.hasLoaded = false
        self.tableView.reloadData()
        self.refreshState()
    }

    func setLyrics(_ lyrics: MategramLyrics?) {
        self.lyrics = lyrics
        self.isLoading = false
        self.hasLoaded = true
        self.activeIndex = nil
        self.lastSpoken = -1
        if let lyrics {
            if lyrics.isSynced {
                self.isSynced = true
                self.rows = lyrics.lines.map { $0.text.isEmpty ? "♪" : $0.text }
            } else {
                self.isSynced = false
                self.rows = (lyrics.plain ?? "").components(separatedBy: "\n")
            }
        } else {
            self.isSynced = false
            self.rows = []
        }
        self.tableView.reloadData()
        self.refreshState()
        self.tick()
        self.scrollToActive(animated: false)
    }

    private func refreshState() {
        if self.isLoading {
            self.spinner.startAnimating()
            self.messageLabel.isHidden = true
        } else {
            self.spinner.stopAnimating()
            self.messageLabel.isHidden = !self.rows.isEmpty
            self.messageLabel.text = self.hasLoaded ? self.text("Текст песни не найден", "Lyrics not found") : ""
        }
        self.tableView.isHidden = self.rows.isEmpty
    }

    func start() {
        if self.displayLink == nil {
            let link = CADisplayLink(target: self, selector: #selector(self.tick))
            link.preferredFramesPerSecond = 30
            link.add(to: .main, forMode: .common)
            self.displayLink = link
        }
        self.scrollToActive(animated: false)
    }

    func stop() {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }

    func updateLayout(size: CGSize, topInset: CGFloat, bottomInset: CGFloat) {
        self.blurView.frame = CGRect(origin: .zero, size: size)
        self.dimView.frame = CGRect(origin: .zero, size: size)
        let headerTop = topInset + 8.0
        self.closeButton.frame = CGRect(x: size.width - 16.0 - 44.0, y: headerTop, width: 44.0, height: 44.0)
        self.sizeButton.frame = CGRect(x: size.width - 16.0 - 44.0 - 44.0, y: headerTop, width: 44.0, height: 44.0)
        let labelWidth = max(0.0, size.width - 24.0 - 100.0)
        self.titleLabel.frame = CGRect(x: 24.0, y: headerTop + 2.0, width: labelWidth, height: 22.0)
        self.artistLabel.frame = CGRect(x: 24.0, y: headerTop + 24.0, width: labelWidth, height: 18.0)
        let tableTop = headerTop + 52.0
        self.tableView.frame = CGRect(x: 0.0, y: tableTop, width: size.width, height: max(0.0, size.height - tableTop))
        self.tableView.contentInset = UIEdgeInsets(top: 12.0, left: 0.0, bottom: max(bottomInset, 0.0) + 220.0, right: 0.0)
        self.messageLabel.frame = CGRect(x: 24.0, y: 0.0, width: size.width - 48.0, height: size.height)
        self.spinner.center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
    }

    @objc private func closePressed() {
        self.onClose?()
    }

    private var leadOffset: Double {
        if self.lyrics?.isApproximate ?? false {
            return 0.15
        }
        let session = AVAudioSession.sharedInstance()
        let latency = session.outputLatency + session.ioBufferDuration
        return min(max(latency + 0.25, 0.25), 0.65)
    }

    @objc private func tick() {
        guard self.isSynced, let lyrics = self.lyrics, let time = self.timeProvider?() else {
            return
        }
        let adjusted = time + self.leadOffset
        let index = lyrics.activeIndex(at: adjusted)
        if index != self.activeIndex {
            let previous = self.activeIndex
            self.activeIndex = index
            self.lastSpoken = -1
            var paths: [IndexPath] = []
            if let previous, previous < self.rows.count {
                paths.append(IndexPath(row: previous, section: 0))
            }
            if let index, index < self.rows.count {
                paths.append(IndexPath(row: index, section: 0))
            }
            UIView.performWithoutAnimation {
                self.tableView.reloadRows(at: paths, with: .none)
            }
            var jumped = false
            if let previous, let index {
                jumped = abs(index - previous) > 3
            }
            self.scrollToActive(animated: !jumped)
        }
        if let index, !lyrics.isApproximate, index < self.rows.count {
            let duration = self.durationProvider?() ?? 0.0
            let words = max(1, self.rows[index].split(separator: " ").count)
            let fraction = lyrics.spokenFraction(lineIndex: index, at: adjusted, duration: duration)
            let spoken = Int((fraction * Double(words)).rounded(.down))
            if spoken != self.lastSpoken {
                self.lastSpoken = spoken
                if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? MategramLyricCell {
                    cell.lineLabel.attributedText = self.activeText(self.rows[index], spoken: spoken)
                }
            }
        }
    }

    private func scrollToActive(animated: Bool) {
        guard let index = self.activeIndex, index < self.rows.count else {
            return
        }
        self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: animated)
    }

    private func activeText(_ text: String, spoken: Int) -> NSAttributedString {
        let font = UIFont.systemFont(ofSize: 26.0 * self.fontScale, weight: .bold)
        let result = NSMutableAttributedString()
        let words = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        for (index, word) in words.enumerated() {
            let color = UIColor(white: 1.0, alpha: index < spoken || (self.lyrics?.isApproximate ?? false) ? 1.0 : 0.32)
            result.append(NSAttributedString(string: word + (index + 1 < words.count ? " " : ""), attributes: [.font: font, .foregroundColor: color]))
        }
        return result
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MategramLyricCell.identifier, for: indexPath) as! MategramLyricCell
        let text = self.rows[indexPath.row]
        if self.isSynced {
            if self.activeIndex == indexPath.row {
                let words = max(1, text.split(separator: " ").count)
                let spoken = self.lyrics?.isApproximate == true ? words : max(0, self.lastSpoken)
                cell.lineLabel.attributedText = self.activeText(text, spoken: spoken)
            } else {
                let isPast = self.activeIndex.map { indexPath.row < $0 } ?? false
                cell.lineLabel.attributedText = NSAttributedString(string: text, attributes: [
                    .font: UIFont.systemFont(ofSize: 21.0 * self.fontScale, weight: .semibold),
                    .foregroundColor: UIColor(white: 1.0, alpha: isPast ? 0.26 : 0.42)
                ])
            }
        } else {
            cell.lineLabel.attributedText = NSAttributedString(string: text.isEmpty ? " " : text, attributes: [
                .font: UIFont.systemFont(ofSize: 17.0 * self.fontScale, weight: .regular),
                .foregroundColor: UIColor(white: 1.0, alpha: 0.88)
            ])
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard self.isSynced, let lyrics = self.lyrics, indexPath.row < lyrics.lines.count else {
            return
        }
        self.onSeek?(lyrics.lines[indexPath.row].timestamp)
    }
}
