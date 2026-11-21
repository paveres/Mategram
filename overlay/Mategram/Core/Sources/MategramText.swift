import Foundation

public enum MategramLanguage {
    case russian
    case english

    public init(code: String) {
        if code.hasPrefix("ru") || code.hasPrefix("uk") || code.hasPrefix("be") {
            self = .russian
        } else {
            self = .english
        }
    }
}

public enum MategramText {
    case settingsTitle
    case sectionProfile
    case sectionProfileFooter
    case profileId
    case profileIdFooter
    case dataCenter
    case dataCenterFooter
    case mutualContact
    case mutualContactFooter
    case registrationDate
    case registrationDateFooter
    case sectionStatus
    case preciseLastSeen
    case preciseLastSeenFooter

    case sectionChats
    case fullViewCount
    case fullViewCountFooter
    case hideStoriesBar
    case hideStoriesBarFooter

    case rowId
    case rowDataCenter
    case rowDataCenterUnknown
    case rowContacts
    case rowContactsMutual
    case rowRegistration
    case rowRegistrationAbout
    case copiedId
    case copiedValue
    case anonymousNumber

    public func string(_ language: MategramLanguage) -> String {
        switch language {
        case .russian:
            return self.russian
        case .english:
            return self.english
        }
    }

    private var russian: String {
        switch self {
        case .settingsTitle: return "Mategram"
        case .sectionProfile: return "Профиль"
        case .sectionProfileFooter: return "Строки добавляются в информацию о пользователе, группе или канале."
        case .profileId: return "Показывать ID"
        case .profileIdFooter: return "Числовой идентификатор. Нажмите на строку в профиле, чтобы скопировать."
        case .dataCenter: return "Показывать датацентр"
        case .dataCenterFooter: return "Датацентр Telegram, где хранится аккаунт, и страна номера, если она известна."
        case .mutualContact: return "Взаимные контакты"
        case .mutualContactFooter: return "Показывать, если вы и этот человек сохранили друг друга в контактах."
        case .registrationDate: return "Дата регистрации"
        case .registrationDateFooter: return "Приблизительная дата создания аккаунта. Считается по номеру аккаунта и может отличаться на несколько месяцев."
        case .sectionStatus: return "Статус в сети"
        case .preciseLastSeen: return "Точное время визита"
        case .preciseLastSeenFooter: return "К статусу «был(а)» добавляются секунды: в шапке чата, профиле, списке контактов и участников. Если человек скрыл время, оно не покажется."
        case .sectionChats: return "Чаты и каналы"
        case .fullViewCount: return "Точное число просмотров"
        case .fullViewCountFooter: return "Под постами канала число просмотров показывается полностью: 1 234 567 вместо 1,2M."
        case .hideStoriesBar: return "Скрыть ленту историй"
        case .hideStoriesBarFooter: return "Лента историй над списком чатов не показывается. Сами истории доступны из профиля."
        case .rowId: return "ID"
        case .rowDataCenter: return "Датацентр"
        case .rowDataCenterUnknown: return "неизвестно"
        case .rowContacts: return "Контакты"
        case .rowContactsMutual: return "Вы в контактах друг у друга"
        case .rowRegistration: return "Регистрация"
        case .rowRegistrationAbout: return "по номеру аккаунта"
        case .copiedId: return "ID скопирован"
        case .copiedValue: return "Скопировано"
        case .anonymousNumber: return "анонимный номер"
        }
    }

    private var english: String {
        switch self {
        case .settingsTitle: return "Mategram"
        case .sectionProfile: return "Profile"
        case .sectionProfileFooter: return "Rows are added to the info of a user, group or channel."
        case .profileId: return "Show ID"
        case .profileIdFooter: return "Numeric identifier. Tap the row in a profile to copy it."
        case .dataCenter: return "Show data center"
        case .dataCenterFooter: return "The Telegram data center that stores the account and the country of the number, when known."
        case .mutualContact: return "Mutual contacts"
        case .mutualContactFooter: return "Shown when you and this person have saved each other in contacts."
        case .registrationDate: return "Registration date"
        case .registrationDateFooter: return "Approximate date the account was created. Estimated from the account number and may be off by a few months."
        case .sectionStatus: return "Last seen"
        case .preciseLastSeen: return "Exact visit time"
        case .preciseLastSeenFooter: return "Seconds are added to «last seen» in the chat header, profile, contacts and member lists. If a person hides the time, it stays hidden."
        case .sectionChats: return "Chats and channels"
        case .fullViewCount: return "Exact view count"
        case .fullViewCountFooter: return "Views under channel posts are shown in full: 1,234,567 instead of 1.2M."
        case .hideStoriesBar: return "Hide stories bar"
        case .hideStoriesBarFooter: return "The stories bar above the chat list is not shown. Stories stay available from profiles."
        case .rowId: return "ID"
        case .rowDataCenter: return "Data center"
        case .rowDataCenterUnknown: return "unknown"
        case .rowContacts: return "Contacts"
        case .rowContactsMutual: return "You are in each other's contacts"
        case .rowRegistration: return "Registered"
        case .rowRegistrationAbout: return "estimated by account number"
        case .copiedId: return "ID copied"
        case .copiedValue: return "Copied"
        case .anonymousNumber: return "anonymous number"
        }
    }
}
