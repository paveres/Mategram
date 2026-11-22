import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import PeerInfoPaneNode

final class MategramMusicCardItem: PeerInfoScreenItem {
    let id: AnyHashable
    let context: AccountContext
    let file: TelegramMediaFile
    let title: String
    let artist: String

    init(id: AnyHashable, context: AccountContext, file: TelegramMediaFile, title: String, artist: String) {
        self.id = id
        self.context = context
        self.file = file
        self.title = title
        self.artist = artist
    }

    func node() -> PeerInfoScreenItemNode {
        return MategramMusicCardItemNode()
    }
}

private final class MategramMusicCardItemNode: PeerInfoScreenItemNode {
    private let cardNode: ASDisplayNode

    override init() {
        self.cardNode = ASDisplayNode(viewBlock: {
            return MategramMusicCardComponent.View(frame: CGRect())
        }, didLoad: nil)
        super.init()
        self.addSubnode(self.cardNode)
    }

    override func didLoad() {
        super.didLoad()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.cardTapped)))
    }

    @objc private func cardTapped() {
        var current: ASDisplayNode? = self.supernode
        while let node = current {
            if let screenNode = node as? PeerInfoScreenNode {
                screenNode.mategramOpenSavedMusic()
                return
            }
            current = node.supernode
        }
    }

    override func update(context: AccountContext, width: CGFloat, safeInsets: UIEdgeInsets, presentationData: PresentationData, item: PeerInfoScreenItem, topItem: PeerInfoScreenItem?, bottomItem: PeerInfoScreenItem?, hasCorners: Bool, transition: ContainedViewLayoutTransition) -> CGFloat {
        guard let item = item as? MategramMusicCardItem else {
            return 10.0
        }
        let height: CGFloat = 72.0
        let cardWidth = max(1.0, width - safeInsets.left - safeInsets.right)
        let frame = CGRect(origin: CGPoint(x: safeInsets.left, y: 0.0), size: CGSize(width: cardWidth, height: height))
        self.clipsToBounds = true
        transition.updateFrame(node: self.cardNode, frame: frame)
        if let view = self.cardNode.view as? MategramMusicCardComponent.View {
            let _ = view.update(component: MategramMusicCardComponent(context: item.context, file: item.file, title: item.title, artist: item.artist, width: cardWidth), availableSize: frame.size)
            view.layer.cornerRadius = min(26.0, height * 0.5)
        }
        return height
    }
}

func mategramMusicItems(data: PeerInfoScreenData, context: AccountContext, presentationData: PresentationData) -> [PeerInfoScreenItem] {
    guard let peer = data.peer, case .user = peer, peer.id != context.account.peerId else {
        return []
    }
    let list = data.savedMusicState.map { state -> (files: [TelegramMediaFile], isLoading: Bool) in
        return (state.files, state.dataState == .loading)
    }
    guard let file = peerInfoProfileMusic(list: list, fullUserMusic: (data.cachedData as? CachedUserData)?.savedMusic) else {
        return []
    }
    var artist = presentationData.strings.MediaPlayer_UnknownArtist
    var title: String?
    for attribute in file.attributes {
        if case let .Audio(_, _, audioTitle, performer, _) = attribute {
            artist = performer ?? artist
            title = audioTitle
            break
        }
    }
    let resolvedTitle = title ?? file.fileName ?? presentationData.strings.MediaPlayer_UnknownTrack
    return [MategramMusicCardItem(id: 9100, context: context, file: file, title: resolvedTitle, artist: artist)]
}
