import Foundation

public enum MategramSection: Int, CaseIterable {
    case ghost
    case appearance
    case liquidGlass
    case profile
    case tabs
    case folders
    case chatList
    case chat
    case input
    case voice
    case media
    case calls
    case network
    case time
    case security
    case settings

    public func title(_ language: MategramLanguage) -> String {
        switch (self, language) {
        case (.ghost, .russian): return "Режим призрака"
        case (.ghost, .english): return "Ghost mode"
        case (.appearance, .russian): return "Внешний вид"
        case (.appearance, .english): return "Appearance"
        case (.liquidGlass, .russian): return "Liquid Glass"
        case (.liquidGlass, .english): return "Liquid Glass"
        case (.profile, .russian): return "Профили"
        case (.profile, .english): return "Profiles"
        case (.tabs, .russian): return "Вкладки"
        case (.tabs, .english): return "Tabs"
        case (.folders, .russian): return "Папки"
        case (.folders, .english): return "Folders"
        case (.chatList, .russian): return "Список чатов"
        case (.chatList, .english): return "Chat list"
        case (.chat, .russian): return "Сообщения"
        case (.chat, .english): return "Messages"
        case (.input, .russian): return "Ввод"
        case (.input, .english): return "Input"
        case (.voice, .russian): return "Голосовые и музыка"
        case (.voice, .english): return "Voice and music"
        case (.media, .russian): return "Медиа и камера"
        case (.media, .english): return "Media and camera"
        case (.calls, .russian): return "Звонки"
        case (.calls, .english): return "Calls"
        case (.network, .russian): return "Сеть"
        case (.network, .english): return "Network"
        case (.time, .russian): return "Время и статус"
        case (.time, .english): return "Time and status"
        case (.security, .russian): return "Конфиденциальность"
        case (.security, .english): return "Privacy"
        case (.settings, .russian): return "Разделы настроек"
        case (.settings, .english): return "Settings sections"
        }
    }

    public func subtitle(_ language: MategramLanguage) -> String {
        switch (self, language) {
        case (.ghost, .russian): return "Прочтение, печать, онлайн, истории"
        case (.ghost, .english): return "Read, typing, online, stories"
        case (.appearance, .russian): return "Шрифт приложения"
        case (.appearance, .english): return "App font"
        case (.liquidGlass, .russian): return "Стекло на сообщениях и кнопках"
        case (.liquidGlass, .english): return "Glass on messages and buttons"
        case (.profile, .russian): return "ID, датацентр, регистрация"
        case (.profile, .english): return "ID, data center, registration"
        case (.tabs, .russian): return "Панель вкладок"
        case (.tabs, .english): return "Tab bar"
        case (.folders, .russian): return "Папки чатов"
        case (.folders, .english): return "Chat folders"
        case (.chatList, .russian): return "Истории, заголовок, свайпы"
        case (.chatList, .english): return "Stories, title, swipes"
        case (.chat, .russian): return "Реакции, перевод, фильтры"
        case (.chat, .english): return "Reactions, translation, filters"
        case (.input, .russian): return "Клавиатура и отправка"
        case (.input, .english): return "Keyboard and sending"
        case (.voice, .russian): return "Микрофон и воспроизведение"
        case (.voice, .english): return "Microphone and playback"
        case (.media, .russian): return "Видео и фото"
        case (.media, .english): return "Video and photo"
        case (.calls, .russian): return "Подтверждение, TCP, ссылки"
        case (.calls, .english): return "Confirmation, TCP, links"
        case (.network, .russian): return "Ускорение загрузки"
        case (.network, .english): return "Faster downloads"
        case (.time, .russian): return "Секунды, точный визит, просмотры"
        case (.time, .english): return "Seconds, exact visit, views"
        case (.security, .russian): return "Номер телефона, сеансы"
        case (.security, .english): return "Phone number, sessions"
        case (.settings, .russian): return "Скрытие стандартных разделов"
        case (.settings, .english): return "Hide standard rows"
        }
    }

    public var symbol: String {
        switch self {
        case .ghost: return "moon"
        case .appearance: return "textformat"
        case .liquidGlass: return "drop"
        case .profile: return "person.crop.circle"
        case .tabs: return "rectangle.bottomthird.inset.filled"
        case .folders: return "folder"
        case .chatList: return "list.bullet"
        case .chat: return "bubble.left"
        case .input: return "keyboard"
        case .voice: return "waveform"
        case .media: return "photo"
        case .calls: return "phone"
        case .network: return "arrow.up.arrow.down"
        case .time: return "clock"
        case .security: return "lock"
        case .settings: return "eye.slash"
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
        MategramOption(key: .ghostHideText, section: .ghost, titleRu: "Без «печатает»", titleEn: "No «typing»",
            footerRu: "Скрывает только набор текста. Остальные действия видны, если не включено «Скрыть «печатает»».",
            footerEn: "Hides text typing only. Other actions stay visible unless «Hide typing» is on."),
        MategramOption(key: .ghostHideRecording, section: .ghost, titleRu: "Без «записывает»", titleEn: "No «recording»",
            footerRu: "Скрывает запись голосового и кружка.",
            footerEn: "Hides voice and video message recording."),
        MategramOption(key: .ghostHideUploads, section: .ghost, titleRu: "Без «отправляет»", titleEn: "No «sending»",
            footerRu: "Скрывает отправку фото, видео и файлов.",
            footerEn: "Hides sending photos, videos and files."),
        MategramOption(key: .ghostHideStickers, section: .ghost, titleRu: "Без «выбирает стикер»", titleEn: "No «choosing sticker»",
            footerRu: "Скрывает выбор стикера.",
            footerEn: "Hides choosing a sticker."),
        MategramOption(key: .ghostReadOnReply, section: .ghost, titleRu: "Читать при ответе", titleEn: "Read on reply",
            footerRu: "Когда вы пишете в чат, он отмечается прочитанным у собеседника. Остальные чаты остаются скрытыми.",
            footerEn: "When you write to a chat it is marked as read for the other side. Other chats stay hidden."),
        MategramOption(key: .ghostDelaySend, section: .ghost, titleRu: "Задержка отправки", titleEn: "Delayed sending",
            footerRu: "Сообщения уходят через 12 секунд как отложенные, вас не видно в сети в момент отправки. Не для секретных чатов.",
            footerEn: "Messages go out after 12 seconds as scheduled, so you are not seen online when sending. Not for secret chats."),
        MategramOption(key: .warnStories, section: .ghost, titleRu: "Спрашивать перед историей", titleEn: "Ask before stories",
            footerRu: "Если просмотр будет виден автору, перед открытием истории появится вопрос. Работает и без режима призрака.",
            footerEn: "If the author would see your view, you are asked before a story opens. Works without ghost mode too."),
        MategramOption(key: .ghostPrivateOnly, section: .ghost, titleRu: "Только в личных чатах", titleEn: "Private chats only",
            footerRu: "В группах и каналах прочтения и «печатает» отправляются как обычно.",
            footerEn: "In groups and channels reads and typing are sent as usual."),
        MategramOption(key: .ghostChatButtons, section: .ghost, titleRu: "Кнопки призрака в чате", titleEn: "Ghost buttons in chat",
            footerRu: "Долгое нажатие на аватарку в чате: призрак для этого чата и «Прочитать на сервере».",
            footerEn: "Long press the avatar in a chat: ghost for this chat and «Mark as read on server»."),
        MategramOption(key: .peekOnline, section: .ghost, titleRu: "Подглядеть онлайн", titleEn: "Peek last seen",
            footerRu: "В меню «…» профиля: на время открывает ваш «был(а)», чтобы увидеть чужой, и возвращает правило.",
            footerEn: "In the profile «…» menu: briefly opens your last seen to see theirs, then restores the rule."),
        MategramOption(key: .ghostAlwaysOnline, section: .ghost, titleRu: "Всегда в сети", titleEn: "Always online",
            footerRu: "Статус «в сети» обновляется каждые 30 секунд, пока приложение работает. Не действует, если включено «Не показывать онлайн».",
            footerEn: "The online status is refreshed every 30 seconds while the app runs. Has no effect when «Do not show online» is on."),
        MategramOption(key: .viewOnceDefault, section: .input, titleRu: "«Один раз» по умолчанию", titleEn: "«View once» by default",
            footerRu: "Голосовые и кружки сразу записываются с просмотром один раз. Кнопкой при записи можно снять.",
            footerEn: "Voice and video messages are recorded as view once. The button while recording turns it off."),
        MategramOption(key: .doubleTapEdit, section: .chat, titleRu: "Двойной тап — правка", titleEn: "Double tap to edit",
            footerRu: "Двойной тап по своему сообщению открывает его правку вместо реакции.",
            footerEn: "Double tap on your message opens editing instead of a reaction."),
        MategramOption(key: .charCounter, section: .input, titleRu: "Счётчик символов", titleEn: "Character counter",
            footerRu: "В длинном сообщении в углу поля ввода видно, сколько символов набрано.",
            footerEn: "A long message shows how many characters are typed in the corner of the input field."),
        MategramOption(key: .hideBlockedMessages, section: .chat, titleRu: "Скрыть заблокированных", titleEn: "Hide blocked users",
            footerRu: "Сообщения заблокированных людей не показываются в группах.",
            footerEn: "Messages from blocked people are hidden in groups."),
        MategramOption(key: .noDoubleTapReaction, section: .chat, titleRu: "Без реакции двойным тапом", titleEn: "No double-tap reaction",
            footerRu: "Двойной тап по сообщению не ставит реакцию.",
            footerEn: "Double tap on a message does not add a reaction."),
        MategramOption(key: .hideSponsored, section: .chat, titleRu: "Скрыть рекламу в каналах", titleEn: "Hide sponsored messages",
            footerRu: "Спонсорские сообщения внизу каналов не показываются.",
            footerEn: "Sponsored messages at the bottom of channels are hidden."),
        MategramOption(key: .hideReactions, section: .chat, titleRu: "Скрыть реакции", titleEn: "Hide reactions",
            footerRu: "Реакции под сообщениями не показываются.",
            footerEn: "Reactions under messages are not shown."),
        MategramOption(key: .sendOnReturn, section: .input, titleRu: "Отправка клавишей Return", titleEn: "Send with Return",
            footerRu: "Клавиша Return отправляет сообщение вместо новой строки.",
            footerEn: "The Return key sends the message instead of a new line."),
        MategramOption(key: .hideSendAs, section: .input, titleRu: "Скрыть «Отправить от имени»", titleEn: "Hide «Send as»",
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
        MategramOption(key: .noAutoplayNextVoice, section: .voice, titleRu: "Не включать следующее голосовое", titleEn: "Do not play next voice",
            footerRu: "После голосового или кружка следующее не начинает играть само.",
            footerEn: "After a voice or video message the next one does not start by itself."),
        MategramOption(key: .alwaysTranslate, section: .chat, titleRu: "«Перевести» всегда", titleEn: "Always «Translate»",
            footerRu: "Пункт «Перевести» есть в меню любого сообщения с текстом, даже на вашем языке.",
            footerEn: "Translate is in the menu of every text message, even in your language."),
        MategramOption(key: .chatTranslateFree, section: .chat, titleRu: "Перевод чата без Premium", titleEn: "Chat translation without Premium",
            footerRu: "Панель «Перевести» над чатом переводит все сообщения через Google.",
            footerEn: "The «Translate» bar above a chat translates all messages with Google."),
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
        MategramOption(key: .glassMessages, section: .liquidGlass, titleRu: "Стекло на сообщениях", titleEn: "Glass messages",
            footerRu: "Пузыри сообщений становятся жидким стеклом.",
            footerEn: "Message bubbles become liquid glass."),
        MategramOption(key: .glassInlineButtons, section: .liquidGlass, titleRu: "Стекло на кнопках ботов", titleEn: "Glass bot buttons",
            footerRu: "Кнопки под сообщениями ботов становятся стеклянными капсулами.",
            footerEn: "Buttons under bot messages become glass capsules."),
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
        MategramOption(key: .showCreationDate, section: .profile, titleRu: "Дата создания", titleEn: "Creation date",
            footerRu: "Когда создана группа или ваш канал.",
            footerEn: "When a group or your channel was created."),
        MategramOption(key: .hideEmojiStatus, section: .profile, titleRu: "Скрыть эмодзи-статус", titleEn: "Hide emoji status",
            footerRu: "Не показывает эмодзи-статус рядом с именем в профиле.",
            footerEn: "Hides the emoji status next to the name in profiles."),
        MategramOption(key: .hideProfileColor, section: .profile, titleRu: "Скрыть цвет профиля", titleEn: "Hide profile color",
            footerRu: "Не закрашивает шапку профиля выбранным цветом.",
            footerEn: "Does not tint the profile header with its color."),
        MategramOption(key: .hideProfileGifts, section: .profile, titleRu: "Скрыть подарки", titleEn: "Hide gifts",
            footerRu: "Вкладка «Подарки» не показывается в профилях.",
            footerEn: "The Gifts tab is not shown in profiles."),
        MategramOption(key: .hideStarRating, section: .profile, titleRu: "Скрыть рейтинг", titleEn: "Hide rating",
            footerRu: "Убирает значок рейтинга под именем.",
            footerEn: "Removes the rating badge under the name."),
        MategramOption(key: .preciseLastSeen, section: .time, titleRu: "Точное время визита", titleEn: "Exact visit time",
            footerRu: "К «был(а)» добавляются секунды везде, где виден статус. Если время скрыто, оно не покажется.",
            footerEn: "Seconds are added to «last seen» wherever the status is shown. Hidden times stay hidden."),
        MategramOption(key: .timeSeconds, section: .time, titleRu: "Секунды в сообщениях", titleEn: "Seconds in messages",
            footerRu: "Время сообщений с секундами: 12:03:07.",
            footerEn: "Message time with seconds: 12:03:07."),
        MategramOption(key: .serviceMessageTime, section: .time, titleRu: "Время у служебных", titleEn: "Time on service messages",
            footerRu: "К «вступил(а) в группу», «закрепил(а)» и другим служебным сообщениям добавляется время.",
            footerEn: "Joins, pins and other service messages show their time."),
        MategramOption(key: .fullViewCount, section: .time, titleRu: "Точные просмотры", titleEn: "Exact views",
            footerRu: "Просмотры поста полностью: 1 234 567 вместо 1,2M.",
            footerEn: "Post views in full: 1,234,567 instead of 1.2M."),
        MategramOption(key: .hideStoriesBar, section: .chatList, titleRu: "Скрыть ленту историй", titleEn: "Hide stories bar",
            footerRu: "Убирает ленту историй над списком чатов.",
            footerEn: "Removes the stories bar above the chat list."),
        MategramOption(key: .hideChatListStatus, section: .chatList, titleRu: "Скрыть статусы в списке", titleEn: "Hide statuses in list",
            footerRu: "Эмодзи-статусы и звёзды Premium не показываются рядом с именами в списке чатов.",
            footerEn: "Emoji statuses and Premium stars are hidden next to names in the chat list."),
        MategramOption(key: .hideChatsTitle, section: .chatList, titleRu: "Скрыть заголовок «Чаты»", titleEn: "Hide «Chats» title",
            footerRu: "Больше места в шапке списка чатов.",
            footerEn: "More room in the chat list header."),
        MategramOption(key: .singleLinePreview, section: .chatList, titleRu: "Одна строка текста", titleEn: "One line of text",
            footerRu: "В списке чатов последнее сообщение показывается одной строкой.",
            footerEn: "The chat list shows the last message in one line."),
        MategramOption(key: .longAllChats, section: .folders, titleRu: "Полное «Все чаты»", titleEn: "Full «All Chats»",
            footerRu: "Первая папка называется «Все чаты», а не «Все».",
            footerEn: "The first folder is called «All Chats» instead of «All»."),
        MategramOption(key: .hideAllChatsTab, section: .folders, titleRu: "Скрыть «Все чаты»", titleEn: "Hide «All Chats»",
            footerRu: "Убирает папку «Все чаты», если есть другие папки.",
            footerEn: "Removes the «All Chats» folder when other folders exist."),
        MategramOption(key: .compactFolders, section: .folders, titleRu: "Компактные папки", titleEn: "Compact folders",
            footerRu: "Меньше отступы между названиями папок, больше папок помещается.",
            footerEn: "Smaller gaps between folder names so more folders fit."),
        MategramOption(key: .rememberFolder, section: .folders, titleRu: "Запоминать папку", titleEn: "Remember folder",
            footerRu: "При запуске открывается последняя выбранная папка.",
            footerEn: "Opens the last selected folder on launch."),
        MategramOption(key: .hideCallsTab, section: .tabs, titleRu: "Скрыть вкладку «Звонки»", titleEn: "Hide Calls tab",
            footerRu: "Убирает вкладку звонков внизу. Применяется после перезапуска.",
            footerEn: "Removes the Calls tab at the bottom. Applies after restart."),
        MategramOption(key: .disableChatSwipes, section: .chatList, titleRu: "Без свайпов в списке", titleEn: "No swipes in list",
            footerRu: "Отключает свайпы по чату: архив, закрепить, удалить.",
            footerEn: "Turns off chat swipes: archive, pin, delete."),
        MategramOption(key: .hideProxySponsor, section: .chatList, titleRu: "Скрыть канал спонсора прокси", titleEn: "Hide proxy sponsor",
            footerRu: "Убирает закреплённый канал, который добавляет прокси-сервер.",
            footerEn: "Removes the pinned channel that a proxy server adds."),
        MategramOption(key: .hideTabTitles, section: .tabs, titleRu: "Без подписей вкладок", titleEn: "No tab titles",
            footerRu: "Внизу остаются только значки вкладок, без названий.",
            footerEn: "Only the tab icons stay at the bottom, without names."),
        MategramOption(key: .callsTcp, section: .calls, titleRu: "Звонки через TCP", titleEn: "TCP calls",
            footerRu: "Разрешает TCP для звонков, если UDP блокируется.",
            footerEn: "Allows TCP for calls when UDP is blocked."),
        MategramOption(key: .confirmCalls, section: .calls, titleRu: "Подтверждать звонок", titleEn: "Confirm calls",
            footerRu: "Спрашивает «Позвонить?» перед звонком.",
            footerEn: "Asks «Call?» before dialing."),
        MategramOption(key: .systemShare, section: .chat, titleRu: "Системное «Поделиться»", titleEn: "System share sheet",
            footerRu: "Ссылки отправляются через окно «Поделиться» iOS.",
            footerEn: "Links are shared with the iOS share sheet."),
        MategramOption(key: .openLinksExternal, section: .calls, titleRu: "Ссылки в браузере", titleEn: "Links in browser",
            footerRu: "Обычные ссылки открываются в вашем браузере.",
            footerEn: "Regular links open in your browser."),
        MategramOption(key: .hideMyProfileRow, section: .settings, titleRu: "Скрыть «Мой профиль»", titleEn: "Hide My Profile",
            footerRu: "Убирает пункт «Мой профиль» из настроек.",
            footerEn: "Removes My Profile from settings."),
        MategramOption(key: .hideWalletRow, section: .settings, titleRu: "Скрыть Кошелёк", titleEn: "Hide Wallet",
            footerRu: "Убирает пункт Кошелёк из настроек.",
            footerEn: "Removes Wallet from settings."),
        MategramOption(key: .hideProxyRow, section: .settings, titleRu: "Скрыть Прокси", titleEn: "Hide Proxy",
            footerRu: "Убирает пункт Прокси из настроек.",
            footerEn: "Removes Proxy from settings."),
        MategramOption(key: .hideSavedRow, section: .settings, titleRu: "Скрыть Избранное", titleEn: "Hide Saved Messages",
            footerRu: "Убирает пункт Избранное из настроек.",
            footerEn: "Removes Saved Messages from settings."),
        MategramOption(key: .hideRecentCallsRow, section: .settings, titleRu: "Скрыть Недавние звонки", titleEn: "Hide Recent Calls",
            footerRu: "Убирает пункт Недавние звонки из настроек.",
            footerEn: "Removes Recent Calls from settings."),
        MategramOption(key: .hideContactsRow, section: .settings, titleRu: "Скрыть Контакты", titleEn: "Hide Contacts",
            footerRu: "Убирает пункт Контакты из настроек.",
            footerEn: "Removes Contacts from settings."),
        MategramOption(key: .hideDevicesRow, section: .settings, titleRu: "Скрыть Устройства", titleEn: "Hide Devices",
            footerRu: "Убирает пункт Устройства из настроек.",
            footerEn: "Removes Devices from settings."),
        MategramOption(key: .hideFoldersRow, section: .settings, titleRu: "Скрыть Папки с чатами", titleEn: "Hide Chat Folders",
            footerRu: "Убирает пункт Папки с чатами из настроек.",
            footerEn: "Removes Chat Folders from settings."),
        MategramOption(key: .hideNotificationsRow, section: .settings, titleRu: "Скрыть Уведомления и звуки", titleEn: "Hide Notifications and Sounds",
            footerRu: "Убирает пункт Уведомления и звуки из настроек.",
            footerEn: "Removes Notifications and Sounds from settings."),
        MategramOption(key: .hidePrivacyRow, section: .settings, titleRu: "Скрыть Конфиденциальность", titleEn: "Hide Privacy and Security",
            footerRu: "Убирает пункт Конфиденциальность из настроек.",
            footerEn: "Removes Privacy and Security from settings."),
        MategramOption(key: .hideDataRow, section: .settings, titleRu: "Скрыть Данные и память", titleEn: "Hide Data and Storage",
            footerRu: "Убирает пункт Данные и память из настроек.",
            footerEn: "Removes Data and Storage from settings."),
        MategramOption(key: .hideAppearanceRow, section: .settings, titleRu: "Скрыть Оформление", titleEn: "Hide Appearance",
            footerRu: "Убирает пункт Оформление из настроек.",
            footerEn: "Removes Appearance from settings."),
        MategramOption(key: .hidePowerSavingRow, section: .settings, titleRu: "Скрыть Энергосбережение", titleEn: "Hide Power Saving",
            footerRu: "Убирает пункт Энергосбережение из настроек.",
            footerEn: "Removes Power Saving from settings."),
        MategramOption(key: .hideLanguageRow, section: .settings, titleRu: "Скрыть Язык", titleEn: "Hide Language",
            footerRu: "Убирает пункт Язык из настроек.",
            footerEn: "Removes Language from settings."),
        MategramOption(key: .hidePassportRow, section: .settings, titleRu: "Скрыть Telegram Passport", titleEn: "Hide Telegram Passport",
            footerRu: "Убирает пункт Telegram Passport из настроек.",
            footerEn: "Removes Telegram Passport from settings."),
        MategramOption(key: .hideWatchRow, section: .settings, titleRu: "Скрыть Apple Watch", titleEn: "Hide Apple Watch",
            footerRu: "Убирает пункт Apple Watch из настроек.",
            footerEn: "Removes Apple Watch from settings."),
        MategramOption(key: .hideSupportRow, section: .settings, titleRu: "Скрыть «Задать вопрос»", titleEn: "Hide Ask a Question",
            footerRu: "Убирает пункт «Задать вопрос» из настроек.",
            footerEn: "Removes Ask a Question from settings."),
        MategramOption(key: .hideFaqRow, section: .settings, titleRu: "Скрыть «Вопросы о Telegram»", titleEn: "Hide Telegram FAQ",
            footerRu: "Убирает пункт «Вопросы о Telegram» из настроек.",
            footerEn: "Removes Telegram FAQ from settings."),
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
        MategramOption(key: .hideTipsRow, section: .settings, titleRu: "Скрыть «Возможности Telegram»", titleEn: "Hide Telegram Features",
            footerRu: "Убирает пункт «Возможности Telegram».",
            footerEn: "Removes Telegram Features."),
        MategramOption(key: .appleSpeech, section: .voice, titleRu: "Расшифровка без Premium", titleEn: "Transcription without Premium",
            footerRu: "Голосовые и кружки расшифровываются на устройстве через Apple Speech.",
            footerEn: "Voice and video messages are transcribed on device with Apple Speech."),
        MategramOption(key: .musicCrossfade, section: .voice, titleRu: "Кроссфейд музыки", titleEn: "Music crossfade",
            footerRu: "Треки длиннее минуты плавно затухают в конце и плавно начинаются.",
            footerEn: "Tracks longer than a minute fade out at the end and fade in at the start."),
        MategramOption(key: .builtInMic, section: .voice, titleRu: "Встроенный микрофон", titleEn: "Built-in microphone",
            footerRu: "Голосовые и кружки пишутся микрофоном телефона, даже если подключены наушники.",
            footerEn: "Voice and video messages use the phone microphone even with headphones connected."),
        MategramOption(key: .backCameraRound, section: .media, titleRu: "Задняя камера для кружков", titleEn: "Back camera for round videos",
            footerRu: "Кружки начинают запись с задней камеры.",
            footerEn: "Round videos start with the back camera."),
        MategramOption(key: .externalVideoPlayer, section: .media, titleRu: "Внешний видеоплеер", titleEn: "External video player",
            footerRu: "В меню видео появляется «Открыть в…» для загруженного видео.",
            footerEn: "Adds «Open in…» to the video menu for downloaded videos."),
        MategramOption(key: .alwaysHD, section: .media, titleRu: "Всегда HD", titleEn: "Always HD",
            footerRu: "Фото в галерее сразу отправляются в высоком качестве.",
            footerEn: "Photos from the gallery are always sent in high quality."),
        MategramOption(key: .ramMonitor, section: .network, titleRu: "RAM под часами", titleEn: "RAM under the clock",
            footerRu: "Показывает, сколько памяти занимает приложение.",
            footerEn: "Shows how much memory the app uses."),
        MategramOption(key: .fastDownload, section: .network, titleRu: "Ускорить скачивание", titleEn: "Faster downloads",
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
