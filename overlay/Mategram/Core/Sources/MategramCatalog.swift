import Foundation

public enum MategramSection: Int, CaseIterable {
    case profile
    case time
    case chatList
    case calls
    case settings
    case media

    public func title(_ language: MategramLanguage) -> String {
        switch (self, language) {
        case (.profile, .russian): return "Профили"
        case (.profile, .english): return "Profiles"
        case (.time, .russian): return "Время и статус"
        case (.time, .english): return "Time and status"
        case (.chatList, .russian): return "Список чатов"
        case (.chatList, .english): return "Chat list"
        case (.calls, .russian): return "Звонки и ссылки"
        case (.calls, .english): return "Calls and links"
        case (.settings, .russian): return "Разделы настроек"
        case (.settings, .english): return "Settings sections"
        case (.media, .russian): return "Медиа"
        case (.media, .english): return "Media"
        }
    }

    public func subtitle(_ language: MategramLanguage) -> String {
        switch (self, language) {
        case (.profile, .russian): return "ID, датацентр, регистрация"
        case (.profile, .english): return "ID, data center, registration"
        case (.time, .russian): return "Секунды, точный визит, просмотры"
        case (.time, .english): return "Seconds, exact visit, views"
        case (.chatList, .russian): return "Истории и заголовок"
        case (.chatList, .english): return "Stories and title"
        case (.calls, .russian): return "Подтверждение, браузер"
        case (.calls, .english): return "Confirmation, browser"
        case (.settings, .russian): return "Скрытие стандартных пунктов"
        case (.settings, .english): return "Hide standard rows"
        case (.media, .russian): return "Камера в галерее"
        case (.media, .english): return "Camera in gallery"
        }
    }

    public var symbol: String {
        switch self {
        case .profile: return "person.crop.circle"
        case .time: return "clock"
        case .chatList: return "list.bullet"
        case .calls: return "phone"
        case .settings: return "eye.slash"
        case .media: return "camera"
        }
    }
}

public struct MategramOption {
    public let key: MategramKey
    public let section: MategramSection
    public let titleRu: String
    public let titleEn: String
    public let footerRu: String
    public let footerEn: String

    public func title(_ language: MategramLanguage) -> String {
        return language == .russian ? self.titleRu : self.titleEn
    }

    public func footer(_ language: MategramLanguage) -> String {
        return language == .russian ? self.footerRu : self.footerEn
    }
}

public enum MategramCatalog {
    public static let options: [MategramOption] = [
        MategramOption(key: .showProfileId, section: .profile, titleRu: "ID в профиле", titleEn: "ID in profile",
            footerRu: "Числовой ID пользователя, группы или канала. Нажмите на строку, чтобы скопировать.",
            footerEn: "Numeric ID of a user, group or channel. Tap the row to copy."),
        MategramOption(key: .showDataCenter, section: .profile, titleRu: "Датацентр и страна", titleEn: "Data center and country",
            footerRu: "Где хранится аккаунт и страна номера, если известна.",
            footerEn: "Where the account is stored and the country of the number, if known."),
        MategramOption(key: .showMutualContact, section: .profile, titleRu: "Взаимный контакт", titleEn: "Mutual contact",
            footerRu: "Отметка в профиле, если вы сохранили друг друга в контактах.",
            footerEn: "A mark in the profile when you saved each other in contacts."),
        MategramOption(key: .showRegistrationDate, section: .profile, titleRu: "Дата регистрации", titleEn: "Registration date",
            footerRu: "Примерная дата создания аккаунта по его ID, точность до нескольких месяцев.",
            footerEn: "Approximate account creation date from its ID, within a few months."),
        MategramOption(key: .hideStarRating, section: .profile, titleRu: "Скрыть рейтинг", titleEn: "Hide rating",
            footerRu: "Убирает значок рейтинга под именем.",
            footerEn: "Removes the rating badge under the name."),
        MategramOption(key: .roundProfileButtons, section: .profile, titleRu: "Круглые кнопки", titleEn: "Round buttons",
            footerRu: "Большие круглые стеклянные кнопки под аватаркой в профиле.",
            footerEn: "Large round glass buttons under the avatar in profiles."),
        MategramOption(key: .preciseLastSeen, section: .time, titleRu: "Точное время визита", titleEn: "Exact visit time",
            footerRu: "К «был(а)» добавляются секунды везде, где виден статус. Если время скрыто, оно не покажется.",
            footerEn: "Seconds are added to «last seen» wherever the status is shown. Hidden times stay hidden."),
        MategramOption(key: .timeSeconds, section: .time, titleRu: "Секунды в сообщениях", titleEn: "Seconds in messages",
            footerRu: "Время сообщений с секундами: 12:03:07.",
            footerEn: "Message time with seconds: 12:03:07."),
        MategramOption(key: .fullViewCount, section: .time, titleRu: "Точные просмотры", titleEn: "Exact views",
            footerRu: "Просмотры поста полностью: 1 234 567 вместо 1,2M.",
            footerEn: "Post views in full: 1,234,567 instead of 1.2M."),
        MategramOption(key: .hideStoriesBar, section: .chatList, titleRu: "Скрыть ленту историй", titleEn: "Hide stories bar",
            footerRu: "Убирает ленту историй над списком чатов.",
            footerEn: "Removes the stories bar above the chat list."),
        MategramOption(key: .hideChatsTitle, section: .chatList, titleRu: "Скрыть заголовок «Чаты»", titleEn: "Hide «Chats» title",
            footerRu: "Больше места в шапке списка чатов.",
            footerEn: "More room in the chat list header."),
        MategramOption(key: .confirmCalls, section: .calls, titleRu: "Подтверждать звонок", titleEn: "Confirm calls",
            footerRu: "Спрашивает «Позвонить?» перед звонком.",
            footerEn: "Asks «Call?» before dialing."),
        MategramOption(key: .openLinksExternal, section: .calls, titleRu: "Ссылки в браузере", titleEn: "Links in browser",
            footerRu: "Обычные ссылки открываются в вашем браузере.",
            footerEn: "Regular links open in your browser."),
        MategramOption(key: .hidePremiumRow, section: .settings, titleRu: "Скрыть Premium", titleEn: "Hide Premium",
            footerRu: "Убирает пункт Telegram Premium.",
            footerEn: "Removes the Telegram Premium row."),
        MategramOption(key: .hideStarsRow, section: .settings, titleRu: "Скрыть Звёзды", titleEn: "Hide Stars",
            footerRu: "Убирает пункт «Звёзды».",
            footerEn: "Removes the Stars row."),
        MategramOption(key: .hideTonRow, section: .settings, titleRu: "Скрыть TON", titleEn: "Hide TON",
            footerRu: "Убирает пункт «Мой TON».",
            footerEn: "Removes the My TON row."),
        MategramOption(key: .hideBusinessRow, section: .settings, titleRu: "Скрыть Бизнес", titleEn: "Hide Business",
            footerRu: "Убирает пункт «Telegram для бизнеса».",
            footerEn: "Removes the Telegram Business row."),
        MategramOption(key: .hideGiftRow, section: .settings, titleRu: "Скрыть «Отправить подарок»", titleEn: "Hide Send a Gift",
            footerRu: "Убирает пункт «Отправить подарок».",
            footerEn: "Removes the Send a Gift row."),
        MategramOption(key: .hideAppsRow, section: .settings, titleRu: "Скрыть мини-приложения", titleEn: "Hide mini apps",
            footerRu: "Убирает список мини-приложений.",
            footerEn: "Removes the mini apps list."),
        MategramOption(key: .hideTipsRow, section: .settings, titleRu: "Скрыть справку", titleEn: "Hide help rows",
            footerRu: "Убирает «Вопросы о Telegram» и «Возможности Telegram».",
            footerEn: "Removes Telegram FAQ and Telegram Features."),
        MategramOption(key: .cameraInGallery, section: .media, titleRu: "Камера в галерее", titleEn: "Camera in gallery",
            footerRu: "Живая камера первой ячейкой в галерее. Выключена, галерея открывается легче.",
            footerEn: "Live camera as the first gallery cell. Off keeps the gallery lighter.")
    ]

    public static func options(in section: MategramSection) -> [MategramOption] {
        return options.filter { $0.section == section }
    }
}
