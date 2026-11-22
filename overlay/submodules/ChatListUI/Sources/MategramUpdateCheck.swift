import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import AlertUI
import PresentationDataUtils
import MategramCore

private final class MategramUpdateState {
    static var checking = false
    static var shownBuild = 0
    static var timer: Foundation.Timer?
    static var observer: NSObjectProtocol?
    static var lastContext: AccountContext?
    static var lastPresent: ((ViewController) -> Void)?
}

private final class MategramUpdateTicker: NSObject {
    static let shared = MategramUpdateTicker()

    @objc func tick() {
        guard let context = MategramUpdateState.lastContext, let present = MategramUpdateState.lastPresent else {
            return
        }
        mategramCheckForUpdate(context: context, present: present)
    }
}

private let mategramUpdateCheckKey = "mategram.update.lastCheck"
private let mategramUpdateSkipKey = "mategram.update.skipped"

func mategramCheckForUpdate(context: AccountContext, present: @escaping (ViewController) -> Void) {
    MategramUpdateState.lastContext = context
    MategramUpdateState.lastPresent = present
    if MategramUpdateState.timer == nil {
        let timer = Foundation.Timer(timeInterval: 60.0, target: MategramUpdateTicker.shared, selector: #selector(MategramUpdateTicker.tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        MategramUpdateState.timer = timer
        MategramUpdateState.observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: { _ in
            MategramUpdateTicker.shared.tick()
        })
    }
    guard MategramSettings.shared.bool(.updateCheck), !MategramUpdateState.checking else {
        return
    }
    let now = Date().timeIntervalSince1970
    let last = UserDefaults.standard.double(forKey: mategramUpdateCheckKey)
    if now - last < 55.0 {
        return
    }
    guard let url = URL(string: "https://get.mates.wtf/latest.json") else {
        return
    }
    MategramUpdateState.checking = true
    var request = URLRequest(url: url)
    request.cachePolicy = .reloadIgnoringLocalCacheData
    request.timeoutInterval = 15.0
    URLSession.shared.dataTask(with: request) { data, response, _ in
        var info: [String: Any]?
        if let data, let http = response as? HTTPURLResponse, http.statusCode == 200 {
            info = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
        Queue.mainQueue().async {
            MategramUpdateState.checking = false
            guard let info else {
                return
            }
            UserDefaults.standard.set(now, forKey: mategramUpdateCheckKey)
            let remoteBuild = (info["build"] as? NSNumber)?.intValue ?? 0
            let localBuild = Int((Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "") ?? 0
            let skipped = UserDefaults.standard.integer(forKey: mategramUpdateSkipKey)
            guard remoteBuild > 0, localBuild > 0, remoteBuild > localBuild, remoteBuild != skipped, remoteBuild != MategramUpdateState.shownBuild else {
                return
            }
            let version = (info["version"] as? String) ?? ""
            let link = ((info["url"] as? String).flatMap { $0.isEmpty ? nil : $0 }) ?? "https://github.com/paveres/Mategram/releases/latest"
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let isRussian = presentationData.strings.baseLanguageCode.hasPrefix("ru")
            let title = isRussian ? "Доступно обновление" : "Update available"
            let text = isRussian ? "Вышел Mategram \(version). Скачайте новую сборку и установите поверх через Sideloadly." : "Mategram \(version) is out. Download the new build and install it over the current one with Sideloadly."
            MategramUpdateState.shownBuild = remoteBuild
            let controller = textAlertController(context: context, title: title, text: text, actions: [
                TextAlertAction(type: .genericAction, title: isRussian ? "Пропустить" : "Skip", action: {
                    UserDefaults.standard.set(remoteBuild, forKey: mategramUpdateSkipKey)
                }),
                TextAlertAction(type: .genericAction, title: isRussian ? "Позже" : "Later", action: {
                }),
                TextAlertAction(type: .defaultAction, title: isRussian ? "Скачать" : "Download", action: {
                    context.sharedContext.applicationBindings.openUrl(link)
                })
            ], actionLayout: .vertical)
            present(controller)
        }
    }.resume()
}
