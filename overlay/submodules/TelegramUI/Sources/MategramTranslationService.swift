import Foundation
import SwiftSignalKit
import TelegramCore
import MategramCore

final class MategramTranslationService: ExperimentalInternalTranslationService {
    static let shared = MategramTranslationService()

    func translate(texts: [AnyHashable: String], fromLang: String, toLang: String) -> Signal<[AnyHashable: String]?, NoError> {
        let keys = Array(texts.keys)
        let values = keys.map { texts[$0] ?? "" }
        return Signal { subscriber in
            MategramGoogleTranslate.translateAll(values, toLang: toLang, completion: { results in
                var output: [AnyHashable: String] = [:]
                for (index, key) in keys.enumerated() {
                    output[key] = (index < results.count ? results[index] : nil) ?? values[index]
                }
                subscriber.putNext(output)
                subscriber.putCompletion()
            })
            return EmptyDisposable
        }
    }
}
