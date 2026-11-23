import Foundation
import UIKit
import AVFoundation
import AVKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramCore
import AccountContext
import TelegramPresentationData
import TelegramUIPreferences
import UniversalMediaPlayer
import PhotoResources
import AppBundle
import MategramCore

final class MategramPlayerPage: UIView {
    var requestDismiss: (() -> Void)?
    var requestShare: (() -> Void)?
    var requestArtist: ((String) -> Void)?
    var requestSetSaved: ((FileMediaReference, Bool) -> Void)?
    var control: ((SharedMediaPlayerControlAction) -> Void)?

    private let context: AccountContext
    private var presentationData: PresentationData
    private let isRussian: Bool

    private let blurCoverNode = TransformImageNode()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let dimView = UIView()
    private let coverClip = UIView()
    private let coverNode = TransformImageNode()
    private let coverFade = CAGradientLayer()
    private let bottomShade = CAGradientLayer()
    private let dragView = UIView()

    private let closeButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let artistButton = UIButton(type: .system)
    private let profileButton = UIButton(type: .system)

    private let scrubberNode: MediaPlayerScrubbingNode
    private let leftTimeNode: MediaPlayerTimeTextNode
    private let rightTimeNode: MediaPlayerTimeTextNode

    private let previousButton = UIButton(type: .system)
    private let playPauseButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)

    private let lyricsButton = UIButton(type: .system)
    private let routeView = AVRoutePickerView()
    private let repeatButton = UIButton(type: .system)
    private let playlistButton = UIButton(type: .system)

    private let lyricsView: MategramLyricsView
    private let returnButton = UIButton(type: .system)

    private var statusDisposable: Disposable?
    private var lyricsTask: URLSessionDataTask?
    private var latestStatus: MediaPlayerStatus?
    private var currentItemId: SharedMediaPlaylistItemId?
    private var currentFile: FileMediaReference?
    private var currentTitle = ""
    private var currentArtist = ""
    private var currentDuration = 0.0
    private var isPlaying = false
    private var looping: MusicPlaybackSettingsLooping = .none
    private var rate: AudioPlaybackRate = .x1
    private var isSaved: Bool?
    private var lyricsKey = ""
    private var lyricsOpen = false
    private var playlistOpen = false
    private var validSize = CGSize()
    private var playlistToolbarHeight: CGFloat = 0.0
    private var lastCoverKey = ""

    var isCovering: Bool {
        return !self.isHidden && self.alpha > 0.5
    }

    init(context: AccountContext, presentationData: PresentationData, status: Signal<(Account, SharedMediaPlayerItemPlaybackStateOrLoading, MediaManagerPlayerType)?, NoError>) {
        self.context = context
        self.presentationData = presentationData
        self.isRussian = presentationData.strings.baseLanguageCode == "ru"

        self.scrubberNode = MediaPlayerScrubbingNode(content: .standard(lineHeight: 6.0, lineCap: .round, scrubberHandle: .none, backgroundColor: UIColor(white: 1.0, alpha: 0.28), foregroundColor: .white, bufferingColor: UIColor(white: 1.0, alpha: 0.4), chapters: []))
        self.leftTimeNode = MediaPlayerTimeTextNode(textColor: UIColor(white: 1.0, alpha: 0.7), textFont: UIFont.monospacedDigitSystemFont(ofSize: 12.0, weight: .medium))
        self.rightTimeNode = MediaPlayerTimeTextNode(textColor: UIColor(white: 1.0, alpha: 0.7), textFont: UIFont.monospacedDigitSystemFont(ofSize: 12.0, weight: .medium))
        self.lyricsView = MategramLyricsView(isRussian: presentationData.strings.baseLanguageCode == "ru")

        super.init(frame: .zero)

        self.backgroundColor = .black
        self.clipsToBounds = true

        self.addSubview(self.blurCoverNode.view)
        self.addSubview(self.blurEffectView)
        self.dimView.backgroundColor = UIColor(white: 0.0, alpha: 0.38)
        self.addSubview(self.dimView)

        self.bottomShade.colors = [UIColor(white: 0.0, alpha: 0.0).cgColor, UIColor(white: 0.0, alpha: 0.5).cgColor]
        self.bottomShade.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.bottomShade.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.layer.addSublayer(self.bottomShade)

        self.coverClip.clipsToBounds = true
        self.coverClip.isUserInteractionEnabled = false
        self.coverClip.addSubview(self.coverNode.view)
        self.coverFade.colors = [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        self.coverFade.locations = [0.0, 0.8, 1.0]
        self.coverFade.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.coverFade.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.coverClip.layer.mask = self.coverFade
        self.addSubview(self.coverClip)

        self.addSubview(self.dragView)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.dragPanned(_:)))
        self.dragView.addGestureRecognizer(pan)

        let symbol = UIImage.SymbolConfiguration(pointSize: 18.0, weight: .semibold)
        self.closeButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: symbol), for: .normal)
        self.closeButton.tintColor = UIColor(white: 1.0, alpha: 0.75)
        self.closeButton.addTarget(self, action: #selector(self.closePressed), for: .touchUpInside)
        self.addSubview(self.closeButton)

        self.moreButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: symbol), for: .normal)
        self.moreButton.tintColor = UIColor(white: 1.0, alpha: 0.75)
        self.moreButton.showsMenuAsPrimaryAction = true
        self.addSubview(self.moreButton)

        self.titleLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .bold)
        self.titleLabel.textColor = .white
        self.titleLabel.adjustsFontSizeToFitWidth = true
        self.titleLabel.minimumScaleFactor = 0.75
        self.addSubview(self.titleLabel)

        self.artistButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        self.artistButton.setTitleColor(UIColor(white: 1.0, alpha: 0.78), for: .normal)
        self.artistButton.contentHorizontalAlignment = .leading
        self.artistButton.addTarget(self, action: #selector(self.artistPressed), for: .touchUpInside)
        self.addSubview(self.artistButton)

        self.profileButton.addTarget(self, action: #selector(self.profilePressed), for: .touchUpInside)
        self.profileButton.isHidden = true
        self.addSubview(self.profileButton)

        self.addSubview(self.scrubberNode.view)
        self.rightTimeNode.mode = .reversed
        self.rightTimeNode.alignment = .right
        self.leftTimeNode.keepPreviousValueOnEmptyState = true
        self.rightTimeNode.keepPreviousValueOnEmptyState = true
        self.addSubview(self.leftTimeNode.view)
        self.addSubview(self.rightTimeNode.view)

        self.previousButton.setImage(generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/Previous"), color: .white), for: .normal)
        self.previousButton.addTarget(self, action: #selector(self.previousPressed), for: .touchUpInside)
        self.playPauseButton.setImage(generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/Play"), color: .white), for: .normal)
        self.playPauseButton.addTarget(self, action: #selector(self.playPausePressed), for: .touchUpInside)
        self.nextButton.setImage(generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/Next"), color: .white), for: .normal)
        self.nextButton.addTarget(self, action: #selector(self.nextPressed), for: .touchUpInside)
        self.addSubview(self.previousButton)
        self.addSubview(self.playPauseButton)
        self.addSubview(self.nextButton)

        let rowSymbol = UIImage.SymbolConfiguration(pointSize: 19.0, weight: .semibold)
        self.lyricsButton.setImage(UIImage(systemName: "text.alignleft", withConfiguration: rowSymbol), for: .normal)
        self.lyricsButton.tintColor = UIColor(white: 1.0, alpha: 0.78)
        self.lyricsButton.addTarget(self, action: #selector(self.lyricsPressed), for: .touchUpInside)
        self.routeView.tintColor = UIColor(white: 1.0, alpha: 0.78)
        self.routeView.activeTintColor = presentationData.theme.list.itemAccentColor
        self.routeView.prioritizesVideoDevices = false
        self.repeatButton.addTarget(self, action: #selector(self.repeatPressed), for: .touchUpInside)
        self.playlistButton.setImage(UIImage(systemName: "list.bullet", withConfiguration: rowSymbol), for: .normal)
        self.playlistButton.tintColor = UIColor(white: 1.0, alpha: 0.78)
        self.playlistButton.addTarget(self, action: #selector(self.playlistPressed), for: .touchUpInside)
        self.addSubview(self.lyricsButton)
        self.addSubview(self.routeView)
        self.addSubview(self.repeatButton)
        self.addSubview(self.playlistButton)

        self.lyricsView.alpha = 0.0
        self.lyricsView.isHidden = true
        self.lyricsView.onClose = { [weak self] in
            self?.setLyricsOpen(false)
        }
        self.lyricsView.onSeek = { [weak self] time in
            self?.control?(.seek(time))
        }
        self.lyricsView.timeProvider = { [weak self] in
            return self?.currentPlaybackTime() ?? 0.0
        }
        self.lyricsView.durationProvider = { [weak self] in
            return self?.currentDuration ?? 0.0
        }
        self.addSubview(self.lyricsView)

        var returnConfig = UIButton.Configuration.filled()
        returnConfig.baseBackgroundColor = UIColor(white: 0.1, alpha: 0.88)
        returnConfig.baseForegroundColor = .white
        returnConfig.cornerStyle = .capsule
        returnConfig.image = UIImage(systemName: "music.note")
        returnConfig.imagePadding = 6.0
        returnConfig.title = self.text("Плеер", "Player")
        returnConfig.contentInsets = NSDirectionalEdgeInsets(top: 9.0, leading: 16.0, bottom: 9.0, trailing: 18.0)
        self.returnButton.configuration = returnConfig
        self.returnButton.alpha = 0.0
        self.returnButton.isHidden = true
        self.returnButton.addTarget(self, action: #selector(self.returnPressed), for: .touchUpInside)

        self.updateRepeatIcon()
        self.rebuildMenu()

        let mapped = combineLatest(status, self.scrubberNode.scrubbingTimestamp)
        |> map { value, scrubbingTimestamp -> MediaPlayerStatus in
            if let (_, valueOrLoading, _) = value, case let .state(state) = valueOrLoading {
                return MediaPlayerStatus(generationTimestamp: scrubbingTimestamp != nil ? 0 : state.status.generationTimestamp, duration: state.status.duration, dimensions: state.status.dimensions, timestamp: scrubbingTimestamp ?? state.status.timestamp, baseRate: state.status.baseRate, seekId: state.status.seekId, status: state.status.status, soundEnabled: state.status.soundEnabled)
            } else {
                return MediaPlayerStatus(generationTimestamp: 0.0, duration: 0.0, dimensions: CGSize(), timestamp: 0.0, baseRate: 1.0, seekId: 0, status: .paused, soundEnabled: true)
            }
        }
        self.scrubberNode.status = mapped
        self.leftTimeNode.status = mapped
        self.rightTimeNode.status = mapped
        self.scrubberNode.seek = { [weak self] value in
            self?.control?(.seek(value))
        }

        self.statusDisposable = (status
        |> deliverOnMainQueue).startStrict(next: { [weak self] value in
            self?.apply(value)
        })
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    deinit {
        self.statusDisposable?.dispose()
        self.lyricsTask?.cancel()
        self.returnButton.removeFromSuperview()
    }

    private func text(_ ru: String, _ en: String) -> String {
        return self.isRussian ? ru : en
    }

    private func currentPlaybackTime() -> Double {
        guard let status = self.latestStatus else {
            return 0.0
        }
        var time = status.timestamp
        if case .playing = status.status {
            time += (CACurrentMediaTime() - status.generationTimestamp) * status.baseRate
        }
        return max(0.0, time)
    }

    private func apply(_ value: (Account, SharedMediaPlayerItemPlaybackStateOrLoading, MediaManagerPlayerType)?) {
        guard let (_, valueOrLoading, _) = value, case let .state(state) = valueOrLoading else {
            return
        }
        self.latestStatus = state.status
        self.currentDuration = state.status.duration

        var playing = false
        switch state.status.status {
        case .playing:
            playing = true
        case .paused:
            playing = false
        case let .buffering(_, whilePlaying, _, _):
            playing = whilePlaying
        }
        if playing != self.isPlaying {
            self.isPlaying = playing
            let name = playing ? "GlobalMusicPlayer/Pause" : "GlobalMusicPlayer/Play"
            self.playPauseButton.setImage(generateTintedImage(image: UIImage(bundleImageName: name), color: .white), for: .normal)
        }
        if state.looping != self.looping {
            self.looping = state.looping
            self.updateRepeatIcon()
        }
        let newRate = AudioPlaybackRate(state.status.baseRate)
        if newRate != self.rate {
            self.rate = newRate
            self.rebuildMenu()
        }

        var fileReference: FileMediaReference?
        if let source = state.item.playbackData?.source {
            switch source {
            case let .telegramFile(reference, _, _):
                fileReference = reference
            }
        }
        self.currentFile = fileReference

        if !areSharedMediaPlaylistItemIdsEqual(state.item.id, self.currentItemId) {
            self.currentItemId = state.item.id
            self.lyricsKey = ""
            var title = ""
            var artist = ""
            var albumArt: SharedMediaPlaybackAlbumArt?
            if let displayData = state.item.displayData, case let .music(trackTitle, performer, art, _, _) = displayData {
                title = trackTitle ?? self.text("Неизвестный трек", "Unknown track")
                artist = performer ?? self.text("Неизвестный исполнитель", "Unknown artist")
                albumArt = art
            }
            self.currentTitle = title
            self.currentArtist = artist
            self.titleLabel.text = title
            self.artistButton.setTitle(artist, for: .normal)
            self.lyricsView.setTrack(title: title, artist: artist)
            self.setCover(fileReference: fileReference, albumArt: albumArt)
            self.rebuildMenu()
        }
        self.requestLyricsIfNeeded()
    }

    private func setCover(fileReference: FileMediaReference?, albumArt: SharedMediaPlaybackAlbumArt?) {
        let signal = playerAlbumArt(engine: self.context.engine, fileReference: fileReference, albumArt: albumArt, thumbnail: false)
        self.coverNode.setSignal(signal)
        self.blurCoverNode.setSignal(signal)
        self.applyCoverLayout()
    }

    private func applyCoverLayout() {
        let coverSide = self.coverNode.view.bounds.size
        if coverSide.width > 1.0 {
            let make = self.coverNode.asyncLayout()
            let apply = make(TransformImageArguments(corners: ImageCorners(), imageSize: coverSide, boundingSize: coverSide, intrinsicInsets: UIEdgeInsets()))
            apply()
        }
        let blurSize = self.blurCoverNode.view.bounds.size
        if blurSize.width > 1.0 {
            let make = self.blurCoverNode.asyncLayout()
            let apply = make(TransformImageArguments(corners: ImageCorners(), imageSize: blurSize, boundingSize: blurSize, intrinsicInsets: UIEdgeInsets()))
            apply()
        }
    }

    private func requestLyricsIfNeeded() {
        guard !self.currentTitle.isEmpty, self.currentDuration > 1.0 else {
            return
        }
        let key = "\(self.currentTitle)|\(self.currentArtist)"
        if key == self.lyricsKey {
            return
        }
        self.lyricsKey = key
        self.lyricsTask?.cancel()
        self.lyricsView.setLoading()
        self.lyricsTask = MategramLyricsService.fetch(title: self.currentTitle, artist: self.currentArtist, duration: self.currentDuration, completion: { [weak self] lyrics in
            guard let self, self.lyricsKey == key else {
                return
            }
            self.lyricsView.setLyrics(lyrics)
        })
    }

    private func updateRepeatIcon() {
        let accent = self.presentationData.theme.list.itemAccentColor
        switch self.looping {
        case .none:
            self.repeatButton.setImage(generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/Repeat"), color: UIColor(white: 1.0, alpha: 0.6)), for: .normal)
        case .item:
            self.repeatButton.setImage(generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/RepeatOne"), color: accent), for: .normal)
        case .all:
            self.repeatButton.setImage(generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/Repeat"), color: accent), for: .normal)
        }
    }

    private func updateProfileIcon() {
        guard let isSaved = self.isSaved else {
            self.profileButton.isHidden = true
            return
        }
        self.profileButton.isHidden = false
        let color = isSaved ? self.presentationData.theme.list.itemAccentColor : UIColor(white: 1.0, alpha: 0.85)
        self.profileButton.setImage(generateTintedImage(image: UIImage(bundleImageName: "Peer Info/SavedMusic"), color: color), for: .normal)
    }

    private func rebuildMenu() {
        let rates: [(String, AudioPlaybackRate)] = [("0.5x", .x0_5), ("1x", .x1), ("1.5x", .x1_5), ("2x", .x2)]
        let rateActions = rates.map { item -> UIAction in
            return UIAction(title: item.0, state: self.rate == item.1 ? .on : .off) { [weak self] _ in
                self?.control?(.setBaseRate(item.1))
            }
        }
        var children: [UIMenuElement] = [
            UIMenu(title: self.text("Скорость", "Speed"), image: UIImage(systemName: "speedometer"), children: rateActions)
        ]
        if let isSaved = self.isSaved {
            let title = isSaved ? self.text("Удалить из профиля", "Remove from profile") : self.text("Добавить в профиль", "Add to profile")
            let icon = UIImage(systemName: isSaved ? "person.crop.circle.badge.minus" : "person.crop.circle.badge.plus")
            children.append(UIAction(title: title, image: icon) { [weak self] _ in
                self?.toggleSaved()
            })
        }
        children.append(UIAction(title: self.text("Плейлист", "Playlist"), image: UIImage(systemName: "list.bullet")) { [weak self] _ in
            self?.setPlaylistOpen(true)
        })
        children.append(UIAction(title: self.text("Поделиться", "Share"), image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            self?.requestShare?()
        })
        self.moreButton.menu = UIMenu(children: children)
    }

    private func toggleSaved() {
        guard let file = self.currentFile, let isSaved = self.isSaved else {
            return
        }
        self.requestSetSaved?(file, !isSaved)
    }

    @objc private func closePressed() {
        self.requestDismiss?()
    }

    @objc private func artistPressed() {
        if !self.currentArtist.isEmpty {
            self.requestArtist?(self.currentArtist)
        }
    }

    @objc private func profilePressed() {
        self.toggleSaved()
    }

    @objc private func previousPressed() {
        self.control?(.previous)
    }

    @objc private func nextPressed() {
        self.control?(.next)
    }

    @objc private func playPausePressed() {
        self.control?(.playback(.togglePlayPause))
    }

    @objc private func repeatPressed() {
        let next: MusicPlaybackSettingsLooping
        switch self.looping {
        case .none:
            next = .item
        case .item:
            next = .all
        case .all:
            next = .none
        }
        let _ = updateMusicPlaybackSettingsInteractively(accountManager: self.context.sharedContext.accountManager, {
            return $0.withUpdatedLooping(next)
        }).startStandalone()
        self.control?(.setLooping(next))
    }

    @objc private func lyricsPressed() {
        self.setLyricsOpen(true)
    }

    @objc private func playlistPressed() {
        self.setPlaylistOpen(true)
    }

    @objc private func returnPressed() {
        self.setPlaylistOpen(false)
    }

    @objc private func dragPanned(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .ended {
            let translation = recognizer.translation(in: self)
            let velocity = recognizer.velocity(in: self)
            if translation.y > 110.0 || velocity.y > 900.0 {
                self.requestDismiss?()
            }
        }
    }

    private func setLyricsOpen(_ open: Bool) {
        if self.lyricsOpen == open {
            return
        }
        self.lyricsOpen = open
        if open {
            self.lyricsView.isHidden = false
            self.lyricsView.transform = CGAffineTransform(translationX: 0.0, y: 36.0)
            self.lyricsView.start()
            UIView.animate(withDuration: 0.38, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: [.curveEaseOut], animations: {
                self.lyricsView.alpha = 1.0
                self.lyricsView.transform = .identity
            })
        } else {
            self.lyricsView.stop()
            UIView.animate(withDuration: 0.26, delay: 0.0, options: [.curveEaseIn], animations: {
                self.lyricsView.alpha = 0.0
                self.lyricsView.transform = CGAffineTransform(translationX: 0.0, y: 36.0)
            }, completion: { _ in
                if !self.lyricsOpen {
                    self.lyricsView.isHidden = true
                    self.lyricsView.transform = .identity
                }
            })
        }
    }

    private func setPlaylistOpen(_ open: Bool) {
        if self.playlistOpen == open {
            return
        }
        self.playlistOpen = open
        if open {
            if self.lyricsOpen {
                self.setLyricsOpen(false)
            }
            self.returnButton.isHidden = false
            UIView.animate(withDuration: 0.34, delay: 0.0, options: [.curveEaseInOut], animations: {
                self.alpha = 0.0
                self.transform = CGAffineTransform(translationX: 0.0, y: 24.0)
                self.returnButton.alpha = 1.0
            }, completion: { _ in
                if self.playlistOpen {
                    self.isHidden = true
                }
            })
        } else {
            self.isHidden = false
            UIView.animate(withDuration: 0.34, delay: 0.0, options: [.curveEaseInOut], animations: {
                self.alpha = 1.0
                self.transform = .identity
                self.returnButton.alpha = 0.0
            }, completion: { _ in
                if !self.playlistOpen {
                    self.returnButton.isHidden = true
                }
            })
        }
    }

    func update(size: CGSize, topInset: CGFloat, bottomInset: CGFloat, isSaved: Bool?, playlistToolbarHeight: CGFloat) {
        if self.isSaved != isSaved {
            self.isSaved = isSaved
            self.updateProfileIcon()
            self.rebuildMenu()
        }
        self.playlistToolbarHeight = playlistToolbarHeight
        if let host = self.superview, self.returnButton.superview == nil {
            host.addSubview(self.returnButton)
        }
        let returnSize = self.returnButton.sizeThatFits(CGSize(width: 200.0, height: 40.0))
        self.returnButton.frame = CGRect(x: floor((size.width - returnSize.width) / 2.0), y: size.height - playlistToolbarHeight - returnSize.height - 12.0, width: returnSize.width, height: returnSize.height)

        if self.validSize == size && self.coverNode.view.bounds.width > 1.0 {
            self.lyricsView.updateLayout(size: size, topInset: topInset, bottomInset: bottomInset)
            return
        }
        self.validSize = size

        let width = size.width
        let height = size.height
        let side: CGFloat = 24.0
        self.blurCoverNode.view.frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        self.blurEffectView.frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        self.dimView.frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        self.bottomShade.frame = CGRect(x: 0.0, y: height * 0.45, width: width, height: height * 0.55)

        let coverHeight = height * 0.56
        let coverSquare = max(width, coverHeight)
        self.coverClip.frame = CGRect(x: 0.0, y: 0.0, width: width, height: coverHeight)
        self.coverFade.frame = CGRect(x: 0.0, y: 0.0, width: width, height: coverHeight)
        self.coverNode.view.frame = CGRect(x: floor((width - coverSquare) / 2.0), y: 0.0, width: coverSquare, height: coverSquare)

        let top = topInset + 6.0
        self.closeButton.frame = CGRect(x: 12.0, y: top, width: 44.0, height: 44.0)
        self.moreButton.frame = CGRect(x: width - 12.0 - 44.0, y: top, width: 44.0, height: 44.0)
        self.dragView.frame = CGRect(x: 0.0, y: top, width: width, height: coverHeight - top)

        let bottomRowY = height - max(bottomInset, 14.0) - 54.0
        let controlsY = bottomRowY - 26.0 - 64.0
        let labelsY = controlsY - 14.0 - 16.0
        let scrubY = labelsY - 4.0 - 22.0
        let titleY = scrubY - 20.0 - 58.0

        let heartWidth: CGFloat = 44.0
        self.titleLabel.frame = CGRect(x: side, y: titleY, width: width - side * 2.0 - heartWidth, height: 30.0)
        self.artistButton.frame = CGRect(x: side, y: titleY + 32.0, width: width - side * 2.0 - heartWidth, height: 26.0)
        self.profileButton.frame = CGRect(x: width - side - heartWidth + 8.0, y: titleY + 8.0, width: heartWidth, height: 44.0)

        self.scrubberNode.frame = CGRect(x: side, y: scrubY, width: width - side * 2.0, height: 22.0)
        self.leftTimeNode.view.frame = CGRect(x: side, y: labelsY, width: 80.0, height: 16.0)
        self.rightTimeNode.view.frame = CGRect(x: width - side - 80.0, y: labelsY, width: 80.0, height: 16.0)

        let center = width / 2.0
        self.playPauseButton.frame = CGRect(x: center - 32.0, y: controlsY, width: 64.0, height: 64.0)
        self.previousButton.frame = CGRect(x: center - 32.0 - 36.0 - 56.0, y: controlsY + 4.0, width: 56.0, height: 56.0)
        self.nextButton.frame = CGRect(x: center + 32.0 + 36.0, y: controlsY + 4.0, width: 56.0, height: 56.0)

        let rowWidth = width - 24.0
        let cell = rowWidth / 4.0
        let buttons: [UIView] = [self.lyricsButton, self.routeView, self.repeatButton, self.playlistButton]
        for (index, button) in buttons.enumerated() {
            let cx = 12.0 + cell * (CGFloat(index) + 0.5)
            button.frame = CGRect(x: cx - 22.0, y: bottomRowY, width: 44.0, height: 44.0)
        }

        self.lyricsView.frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        self.lyricsView.updateLayout(size: size, topInset: topInset, bottomInset: bottomInset)
        self.applyCoverLayout()
    }
}
