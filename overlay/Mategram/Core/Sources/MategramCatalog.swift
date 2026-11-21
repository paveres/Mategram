import Foundation

public enum MategramSection: Int, CaseIterable {
    case profile
    case status
    case messages
    case chatList
    case calls
    case settings

    public func title(_ language: MategramLanguage) -> String {
        switch (self, language) {
        case (.profile, .russian): return "Профиль"
        case (.profile, .english): return "Profile"
        case (.status, .russian): return "Статус в сети"
        case (.status, .english): return "Last seen"
        case (.messages, .russian): return "Сообщения"
        case (.messages, .english): return "Messages"
        case (.chatList, .russian): return "Список чатов"
        case (.chatList, .english): return "Chat list"
        case (.calls, .russian): return "Звонки и ссылки"
        case (.calls, .english): return "Calls and links"
        case (.settings, .russian): return "Пункты настроек"
        case (.settings, .english): return "Settings items"
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
        MategramOption(key: .showProfileId, section: .profile, titleRu: "Показывать ID", titleEn: "Show ID",
            footerRu: "Строка с числовым ID в информации о пользователе, группе или канале. Нажмите на строку, чтобы скопировать.",
            footerEn: "A row with the numeric ID in the info of a user, group or channel. Tap the row to copy."),
        MategramOption(key: .showDataCenter, section: .profile, titleRu: "Показывать датацентр", titleEn: "Show data center",
            footerRu: "Датацентр Telegram, где хранится аккаунт, и страна номера, если она известна.",
            footerEn: "The Telegram data center that stores the account and the country of the number, when known."),
        MategramOption(key: .showMutualContact, section: .profile, titleRu: "Взаимные контакты", titleEn: "Mutual contacts",
            footerRu: "Строка в профиле, если вы и этот человек сохранили друг друга в контактах.",
            footerEn: "A row in the profile when you and this person have saved each other in contacts."),
        MategramOption(key: .showRegistrationDate, section: .profile, titleRu: "Дата регистрации", titleEn: "Registration date",
            footerRu: "Приблизительная дата создания аккаунта. Считается по номеру аккаунта и может отличаться на несколько месяцев.",
            footerEn: "Approximate date the account was created. Estimated from the account number and may be off by a few months."),
        MategramOption(key: .hideStarRating, section: .profile, titleRu: "Скрыть рейтинг", titleEn: "Hide rating",
            footerRu: "Убирает значок рейтинга под именем в профиле и в настройках.",
            footerEn: "Removes the rating badge under the name in profiles and settings."),
        MategramOption(key: .preciseLastSeen, section: .status, titleRu: "Точное время визита", titleEn: "Exact visit time",
            footerRu: "К статусу «был(а)» добавляются секунды: в шапке чата, профиле, списке контактов и участников. Если человек скрыл время, оно не покажется.",
            footerEn: "Seconds are added to «last seen» in the chat header, profile, contacts and member lists. If a person hides the time, it stays hidden."),
        MategramOption(key: .timeSeconds, section: .messages, titleRu: "Секунды во времени", titleEn: "Seconds in time",
            footerRu: "Время сообщений показывается с секундами: 12:03:07.",
            footerEn: "Message time is shown with seconds: 12:03:07."),
        MategramOption(key: .fullViewCount, section: .messages, titleRu: "Точное число просмотров", titleEn: "Exact view count",
            footerRu: "Под постами канала просмотры показываются полностью: 1 234 567 вместо 1,2M.",
            footerEn: "Views under channel posts are shown in full: 1,234,567 instead of 1.2M."),
        MategramOption(key: .hideStoriesBar, section: .chatList, titleRu: "Скрыть ленту историй", titleEn: "Hide stories bar",
            footerRu: "Лента историй над списком чатов не показывается. Сами истории доступны из профиля.",
            footerEn: "The stories bar above the chat list is not shown. Stories stay available from profiles."),
        MategramOption(key: .hideChatsTitle, section: .chatList, titleRu: "Скрыть заголовок «Чаты»", titleEn: "Hide «Chats» title",
            footerRu: "В шапке списка чатов не пишется заголовок, места становится больше.",
            footerEn: "The chat list header has no title, which frees up space."),
        MategramOption(key: .confirmCalls, section: .calls, titleRu: "Подтверждать звонок", titleEn: "Confirm calls",
            footerRu: "Перед звонком спрашивает «Позвонить?», чтобы не позвонить случайно.",
            footerEn: "Asks «Call?» before dialing so you never call by accident."),
        MategramOption(key: .openLinksExternal, section: .calls, titleRu: "Ссылки в браузере", titleEn: "Open links in browser",
            footerRu: "Обычные ссылки открываются в вашем браузере, а не во встроенном просмотре Telegram.",
            footerEn: "Regular links open in your browser instead of the built-in Telegram viewer."),
        MategramOption(key: .hidePremiumRow, section: .settings, titleRu: "Скрыть Premium", titleEn: "Hide Premium",
            footerRu: "Убирает пункт Telegram Premium из настроек.",
            footerEn: "Removes the Telegram Premium row from settings."),
        MategramOption(key: .hideStarsRow, section: .settings, titleRu: "Скрыть Звёзды", titleEn: "Hide Stars",
            footerRu: "Убирает пункт «Звёзды» из настроек.",
            footerEn: "Removes the Stars row from settings."),
        MategramOption(key: .hideTonRow, section: .settings, titleRu: "Скрыть TON", titleEn: "Hide TON",
            footerRu: "Убирает пункт «Мой TON» из настроек.",
            footerEn: "Removes the My TON row from settings."),
        MategramOption(key: .hideBusinessRow, section: .settings, titleRu: "Скрыть Бизнес", titleEn: "Hide Business",
            footerRu: "Убирает пункт «Telegram для бизнеса» из настроек.",
            footerEn: "Removes the Telegram Business row from settings."),
        MategramOption(key: .hideGiftRow, section: .settings, titleRu: "Скрыть «Отправить подарок»", titleEn: "Hide Send a Gift",
            footerRu: "Убирает пункт «Отправить подарок» из настроек.",
            footerEn: "Removes the Send a Gift row from settings."),
        MategramOption(key: .hideAppsRow, section: .settings, titleRu: "Скрыть мини-приложения", titleEn: "Hide mini apps",
            footerRu: "Убирает список мини-приложений из настроек.",
            footerEn: "Removes the mini apps list from settings."),
        MategramOption(key: .hideTipsRow, section: .settings, titleRu: "Скрыть «Возможности Telegram»", titleEn: "Hide Telegram Features",
            footerRu: "Убирает пункты «Вопросы о Telegram» и «Возможности Telegram».",
            footerEn: "Removes the Telegram FAQ and Telegram Features rows.")
    ]
}
