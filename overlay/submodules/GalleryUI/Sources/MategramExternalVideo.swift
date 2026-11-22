import Foundation
import UIKit
import TelegramCore
import AccountContext

func mategramOpenVideoExternally(context: AccountContext, message: EngineMessage, from controller: UIViewController?) {
    guard let controller, let file = message.media.first(where: { $0 is TelegramMediaFile }) as? TelegramMediaFile, let path = context.engine.resources.completedResourcePath(id: EngineMediaResource.Id(file.resource.id)) else {
        return
    }
    var ext = "mp4"
    if let fileName = file.fileName {
        let value = (fileName as NSString).pathExtension
        if !value.isEmpty {
            ext = value
        }
    }
    let target = NSTemporaryDirectory() + "mategram-video." + ext
    try? FileManager.default.removeItem(atPath: target)
    do {
        try FileManager.default.copyItem(atPath: path, toPath: target)
    } catch {
        return
    }
    let activity = UIActivityViewController(activityItems: [URL(fileURLWithPath: target)], applicationActivities: nil)
    activity.popoverPresentationController?.sourceView = controller.view
    controller.present(activity, animated: true)
}
