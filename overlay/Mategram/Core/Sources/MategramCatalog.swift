import Foundation

public enum MategramSection: Int, CaseIterable {
    case ghost
    case profile
    case time
    case chat
    case chatList
    case calls
    case settings
    case security
    case media

    public func title(_ language: MategramLanguage) -> String {
        switch (self, language) {
        case (.ghost, .russian): return "Режим призрака"
        case (.ghost, .english): return "Ghost mode"
        case (.profile, .russian): return "Профили"
        case (.profile, .english): return "Profiles"
        case (.time, .russian): return "Время и статус"
        case (.time, .english): return "Time and status"
        case (.chat, .russian): return "Чат"
        case (.chat, .english): return "Chat"
        case (.security, .russian): return "Конфиденциальность"
        case (.security, .english): return "Privacy"
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
        case (.ghost, .russian): return "Прочтение, печать, онлайн, истории"
        case (.ghost, .english): return "Read, typing, online, stories"
        case (.profile, .russian): return "ID, датацентр, регистрация"
        case (.profile, .english): return "ID, data center, registration"
        case (.time, .russian): return "Секунды, точный визит, просмотры"
        case (.time, .english): return "Seconds, exact visit, views"
        case (.chat, .russian): return "Реакции, отправка, меню сообщения"
        case (.chat, .english): return "Reactions, sending, message menu"
        case (.security, .russian): return "Номер телефона, сеансы"
        case (.security, .english): return "Phone number, sessions"
        case (.chatList, .russian): return "Истории, заголовок, свайпы, прокси"
        case (.chatList, .english): return "Stories, title, swipes, proxy"
        case (.calls, .russian): return "Подтверждение, браузер"
        case (.calls, .english): return "Confirmation, browser"
        case (.settings, .russian): return "Скрытие стандартных пунктов"
        case (.settings, .english): return "Hide standard rows"
        case (.media, .russian): return "Камера в галерее, HD"
        case (.media, .english): return "Camera in gallery, HD"
        }
    }

    public var symbol: String {
        switch self {
        case .ghost: return "moon"
        case .profile: return "person.crop.circle"
        case .time: return "clock"
        case .chat: return "bubble.left.and.bubble.right"
        case .security: return "lock"
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

public struct MategramTextOption {
    public let key: MategramTextKey
    public let section: MategramSection
    public let titleRu: String
    public let titleEn: String
    public let placeholderRu: String
    public let placeholderEn: String

    public func title(_ language: MategramLanguage) -> String {
        return language == .russian ? self.titleRu : self.titleEn
    }

    public func placeholder(_ language: MategramLanguage) -> String {
        return language == .russian ? self.placeholderRu : self.placeholderEn
    }
}

public enum MategramCatalog {
    public static let options: [MategramOption] = [
        MategramOption(key: .ghostMode, section: .ghost, titleRu: "Режим призрака", titleEn: "Ghost mode",
            footerRu: "Главный выключатель. Включает все пункты ниже, которые вы оставили включёнными. Отдельный чат можно исключить в его профиле.",
            footerEn: "Master switch. Turns on every option below that you left on. A single chat can be excluded in its profile."),
        MategramOption(key: .ghostRead, section: .ghost, titleRu: "Не отмечать прочитанным", titleEn: "Do not mark as read",
            footerRu: "Собеседник не увидит, что вы прочитали сообщения. У вас чат выглядит прочитанным.",
            footerEn: "The other side will not see that you read messages. On your side the chat looks read."),
        MategramOption(key: .ghostTyping, section: .ghost, titleRu: "Скрыть «печатает»", titleEn: "Hide «typing»",
            footerRu: "Не отправляется статус «печатает», запись голоса и другие действия.",
            footerEn: "Typing, voice recording and other activity are not sent."),
        MategramOption(key: .ghostOnline, section: .ghost, titleRu: "Не показывать «онлайн»", titleEn: "Do not show «online»",
            footerRu: "Ваш статус в сети не обновляется, пока приложение открыто.",
            footerEn: "Your online status is not updated while the app is open."),
        MategramOption(key: .ghostStories, section: .ghost, titleRu: "Невидимые истории", titleEn: "Invisible stories",
            footerRu: "Просмотр историй не отмечается у автора.",
            footerEn: "Story views are not shown to the author."),
        MategramOption(key: .ghostContents, section: .ghost, titleRu: "Не отмечать прослушанным", titleEn: "Do not mark as listened",
            footerRu: "Голосовые и кружки остаются непрослушанными у отправителя.",
            footerEn: "Voice and video messages stay unlistened for the sender."),
        MategramOption(key: .ghostAlwaysOnline, section: .ghost, titleRu: "Всегда в сети", titleEn: "Always online",
            footerRu: "Статус «в сети» обновляется каждые 30 секунд, пока приложение работает. Не действует, если включено «Не показывать онлайн».",
            footerEn: "The online status is refreshed every 30 seconds while the app runs. Has no effect when «Do not show online» is on."),
        MategramOption(key: .hideReactions, section: .chat, titleRu: "Скрыть реакции", titleEn: "Hide reactions",
            footerRu: "Реакции под сообщениями не показываются.",
            footerEn: "Reactions under messages are not shown."),
        MategramOption(key: .sendOnReturn, section: .chat, titleRu: "Отправка клавишей Return", titleEn: "Send with Return",
            footerRu: "Клавиша Return отправляет сообщение вместо новой строки.",
            footerEn: "The Return key sends the message instead of a new line."),
        MategramOption(key: .hideSendAs, section: .chat, titleRu: "Скрыть «Отправить от имени»", titleEn: "Hide «Send as»",
            footerRu: "Убирает аватарку выбора отправителя в поле ввода групп и каналов.",
            footerEn: "Removes the sender picker avatar from the input field in groups and channels."),
        MategramOption(key: .zalgoFilter, section: .chat, titleRu: "Фильтр «ломаного» текста", titleEn: "Zalgo filter",
            footerRu: "Перед отправкой убирает лишние надстрочные знаки, которыми ломают текст.",
            footerEn: "Removes stacked combining marks used to break text before sending."),
        MategramOption(key: .menuSaveToSaved, section: .chat, titleRu: "«Избранное» в меню сообщения", titleEn: "«Saved Messages» in message menu",
            footerRu: "Пункт в меню сообщения: пересылает его в Избранное одним нажатием.",
            footerEn: "A message menu item that forwards it to Saved Messages in one tap."),
        MategramOption(key: .wordFilter, section: .chat, titleRu: "Фильтр по словам", titleEn: "Word filter",
            footerRu: "Входящие сообщения со словами из списка ниже становятся бледными. Слова через запятую или с новой строки.",
            footerEn: "Incoming messages with words from the list below are dimmed. Separate words with commas or new lines."),
        MategramOption(key: .noAutoplayNextVoice, section: .chat, titleRu: "Не включать следующее голосовое", titleEn: "Do not play next voice",
            footerRu: "После голосового или кружка следующее не начинает играть само.",
            footerEn: "After a voice or video message the next one does not start by itself."),
        MategramOption(key: .googleTranslate, section: .chat, titleRu: "Перевод через Google", titleEn: "Google translation",
            footerRu: "Кнопка «Перевести» переводит текст через Google, а не через Telegram. Текст без форматирования уходит в Google.",
            footerEn: "The Translate button uses Google instead of Telegram. Plain text is sent to Google."),
        MategramOption(key: .smallStickers, section: .chat, titleRu: "Уменьшенные стикеры", titleEn: "Smaller stickers",
            footerRu: "Стикеры в чате на треть меньше обычного.",
            footerEn: "Stickers in chats are a third smaller."),
        MategramOption(key: .mutedNameColors, section: .chat, titleRu: "Приглушённые цвета имён", titleEn: "Muted name colors",
            footerRu: "Цвета имён и цитат вдвое менее насыщенные.",
            footerEn: "Name and quote colors are half as saturated."),
        MategramOption(key: .hideBusinessBotPanel, section: .chat, titleRu: "Скрыть панель бизнес-бота", titleEn: "Hide business bot panel",
            footerRu: "Убирает плашку бота, который управляет чатом.",
            footerEn: "Removes the bar of the bot that manages the chat."),
        MategramOption(key: .hidePhone, section: .security, titleRu: "Скрыть номер телефона", titleEn: "Hide phone number",
            footerRu: "Ваш номер закрыт точками в настройках и в вашем профиле, видна только страна.",
            footerEn: "Your number is masked with dots in settings and in your profile, only the country code stays."),
        MategramOption(key: .showSessionApiId, section: .security, titleRu: "API ID в сеансах", titleEn: "API ID in sessions",
            footerRu: "В «Устройствах» рядом с приложением виден его API ID: так легче узнать неофициальный клиент.",
            footerEn: "Devices show each app's API ID, so unofficial clients are easier to spot."),
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
        MategramOption(key: .disableChatSwipes, section: .chatList, titleRu: "Без свайпов в списке", titleEn: "No swipes in list",
            footerRu: "Отключает свайпы по чату: архив, закрепить, удалить.",
            footerEn: "Turns off chat swipes: archive, pin, delete."),
        MategramOption(key: .hideProxySponsor, section: .chatList, titleRu: "Скрыть канал спонсора прокси", titleEn: "Hide proxy sponsor",
            footerRu: "Убирает закреплённый канал, который добавляет прокси-сервер.",
            footerEn: "Removes the pinned channel that a proxy server adds."),
        MategramOption(key: .hideTabTitles, section: .chatList, titleRu: "Без подписей вкладок", titleEn: "No tab titles",
            footerRu: "Внизу остаются только значки вкладок, без названий.",
            footerEn: "Only the tab icons stay at the bottom, without names."),
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
        MategramOption(key: .alwaysHD, section: .media, titleRu: "Всегда HD", titleEn: "Always HD",
            footerRu: "Фото в галерее сразу отправляются в высоком качестве.",
            footerEn: "Photos from the gallery are always sent in high quality."),
        MategramOption(key: .fastDownload, section: .media, titleRu: "Ускорить скачивание", titleEn: "Faster downloads",
            footerRu: "Файлы качаются большими частями и в 16 потоков. Расходует больше трафика за раз.",
            footerEn: "Files download in larger parts with 16 parallel requests. Uses more traffic at once."),
        MategramOption(key: .cameraInGallery, section: .media, titleRu: "Камера в галерее", titleEn: "Camera in gallery",
            footerRu: "Живая камера первой ячейкой в галерее. Выключена, галерея открывается легче.",
            footerEn: "Live camera as the first gallery cell. Off keeps the gallery lighter.")
    ]

    public static let textOptions: [MategramTextOption] = [
        MategramTextOption(key: .filterWords, section: .chat, titleRu: "СЛОВА ДЛЯ ФИЛЬТРА", titleEn: "FILTER WORDS", placeholderRu: "Слова через запятую", placeholderEn: "Words separated by commas")
    ]

    public static func textOptions(in section: MategramSection) -> [MategramTextOption] {
        return textOptions.filter { $0.section == section }
    }

    public static func options(in section: MategramSection) -> [MategramOption] {
        return options.filter { $0.section == section }
    }
}
