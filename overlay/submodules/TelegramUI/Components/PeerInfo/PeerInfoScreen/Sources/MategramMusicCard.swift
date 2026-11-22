import Foundation
import UIKit
import Display
import ComponentFlow
import TelegramCore
import AccountContext
import PhotoResources
import MusicAlbumArtResources

final class MategramEmptyComponent: Component {
    init() {
    }

    static func ==(lhs: MategramEmptyComponent, rhs: MategramEmptyComponent) -> Bool {
        return true
    }

    final class View: UIView {
    }

    func makeView() -> View {
        return View()
    }

    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return CGSize(width: 0.0, height: 0.0)
    }
}

final class MategramMusicCardComponent: Component {
    let context: AccountContext
    let file: TelegramMediaFile
    let title: String
    let artist: String
    let width: CGFloat

    init(context: AccountContext, file: TelegramMediaFile, title: String, artist: String, width: CGFloat) {
        self.context = context
        self.file = file
        self.title = title
        self.artist = artist
        self.width = width
    }

    static func ==(lhs: MategramMusicCardComponent, rhs: MategramMusicCardComponent) -> Bool {
        return lhs.file.fileId.id == rhs.file.fileId.id && lhs.title == rhs.title && lhs.artist == rhs.artist && lhs.width == rhs.width
    }

    final class View: UIView {
        private let backgroundNode = TransformImageNode()
        private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        private let dimView = UIView()
        private let coverNode = TransformImageNode()
        private let titleLabel = UILabel()
        private let artistLabel = UILabel()
        private var currentFileId: Int64?

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.isUserInteractionEnabled = false
            self.clipsToBounds = true
            self.layer.cornerRadius = 18.0
            self.layer.cornerCurve = .continuous
            self.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
            self.backgroundNode.contentAnimations = [.firstUpdate]
            self.addSubview(self.backgroundNode.view)
            self.addSubview(self.blurView)
            self.dimView.backgroundColor = UIColor(white: 0.0, alpha: 0.25)
            self.addSubview(self.dimView)
            self.coverNode.contentAnimations = [.firstUpdate]
            self.addSubview(self.coverNode.view)
            self.titleLabel.font = Font.semibold(17.0)
            self.titleLabel.textColor = .white
            self.artistLabel.font = Font.regular(15.0)
            self.artistLabel.textColor = UIColor(white: 1.0, alpha: 0.7)
            self.addSubview(self.titleLabel)
            self.addSubview(self.artistLabel)
        }

        required init?(coder: NSCoder) {
            preconditionFailure()
        }

        func update(component: MategramMusicCardComponent, availableSize: CGSize) -> CGSize {
            let size = CGSize(width: component.width, height: 68.0)
            if self.currentFileId != component.file.fileId.id {
                self.currentFileId = component.file.fileId.id
                let reference: FileMediaReference = .standalone(media: component.file)
                let albumArt = SharedMediaPlaybackAlbumArt(thumbnailResource: ExternalMusicAlbumArtResource(file: reference, title: component.title, performer: component.artist, isThumbnail: true), fullSizeResource: ExternalMusicAlbumArtResource(file: reference, title: component.title, performer: component.artist, isThumbnail: false))
                self.coverNode.setSignal(playerAlbumArt(engine: component.context.engine, fileReference: reference, albumArt: albumArt, thumbnail: false))
                self.backgroundNode.setSignal(playerAlbumArt(engine: component.context.engine, fileReference: reference, albumArt: albumArt, thumbnail: true))
            }
            let backgroundFrame = CGRect(x: -20.0, y: -size.width * 0.5 + size.height * 0.5, width: size.width + 40.0, height: size.width + 40.0)
            self.backgroundNode.frame = backgroundFrame
            self.backgroundNode.asyncLayout()(TransformImageArguments(corners: ImageCorners(radius: 0.0), imageSize: backgroundFrame.size, boundingSize: backgroundFrame.size, intrinsicInsets: .zero))()
            self.blurView.frame = CGRect(origin: CGPoint(), size: size)
            self.dimView.frame = CGRect(origin: CGPoint(), size: size)

            let coverSize = CGSize(width: 52.0, height: 52.0)
            let coverFrame = CGRect(origin: CGPoint(x: 8.0, y: floor((size.height - coverSize.height) / 2.0)), size: coverSize)
            self.coverNode.frame = coverFrame
            self.coverNode.asyncLayout()(TransformImageArguments(corners: ImageCorners(radius: 10.0), imageSize: coverSize, boundingSize: coverSize, intrinsicInsets: .zero))()

            self.titleLabel.text = component.title
            self.artistLabel.text = component.artist
            let textX = coverFrame.maxX + 14.0
            let textWidth = max(1.0, size.width - textX - 14.0)
            self.titleLabel.frame = CGRect(x: textX, y: floor(size.height / 2.0) - 21.0, width: textWidth, height: 21.0)
            self.artistLabel.frame = CGRect(x: textX, y: floor(size.height / 2.0) + 1.0, width: textWidth, height: 19.0)
            return size
        }
    }

    func makeView() -> View {
        return View(frame: CGRect())
    }

    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize)
    }
}
