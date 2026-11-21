# Анализ исходника Telegram-iOS (для Mategram)

Только анализ, в `upstream/` ничего не правилось (`git status` чистый). Версия: **release-13.2** (коммит `24638bc`, 3 ноября 2026).

## 1. Что скачано

| | |
|---|---|
| Репозиторий | `github.com/TelegramMessenger/Telegram-iOS`, глубина 1, тег `release-13.2` |
| Размер | 710 МБ на диске |
| Файлов | 37 327, из них Swift 7 210 |
| Модулей | 276 в `submodules/` плюс расширения в `Telegram/` |
| Сборка | Bazel 9.2, Xcode 27.1, macOS 27 (`versions.json`) |
| Последние релизы | 13.1.1, 13.1.2, 13.2 |

В корне репозитория есть служебные файлы с описанием сборки; из них взяты только сведения о сборке.

## 2. Устройство проекта

| Папка | Что внутри |
|---|---|
| `submodules/TelegramCore` | Ядро: сеть, аккаунты, сообщения, состояния. Здесь живёт вся «что уходит на сервер» |
| `submodules/Postbox` | База данных |
| `submodules/MtProtoKit` | Протокол MTProto (появился ещё `MTProtoRustEngine`) |
| `submodules/TelegramUI` | Главный интерфейс. `Sources/` старый код, `Components/` новые компоненты (чат, профиль, истории, камера, стекло) |
| `submodules/ChatListUI`, `TabBarUI`, `SettingsUI`, `ContactListUI`, `CallListUI` | Экраны |
| `submodules/Display`, `AsyncDisplayKit` | Графика и узлы интерфейса |
| `submodules/TelegramCallsUI`, `TelegramVoip` | Звонки |
| `submodules/Camera`, `MediaPickerUI`, `GalleryUI`, `MediaPlayer` | Камера, галерея, плеер |
| `Telegram/` | Основное приложение и расширения: `NotificationService`, `Share`, `SiriIntents`, `WidgetKitWidget`, `BroadcastUpload`, часы |
| `build-system/` | `Make/Make.py` (обёртка Bazel), конфигурации, подпись |

Что важно для нас:

1. **Каждый модуль это Bazel-цель** со своим `BUILD`. Чтобы наш модуль был виден из `TelegramCore`, `TelegramUI` и расширений, нужно добавить зависимость в `deps = [...]` их `BUILD`. Это тоже хук (вставка строки в список), скрипт умеет такое.
2. **`TelegramCore` собирается с `-warnings-as-errors`.** Любое предупреждение в нашей вставке остановит сборку. Вставки должны быть однострочными вызовами.
3. **Расширения собираются отдельно** (уведомления, «Поделиться», Siri). Если решение о приватности принимается в приложении, а расширение этого не знает, раскроется прочтение или всплывёт сообщение. Модуль режима призрака должен собираться и для приложения, и для расширений, как у Ghostgram (`GGFeaturesShared`).
4. **Сборка только целиком**: селективной сборки модуля нет, единственная команда собирает `Telegram/Telegram`.

## 3. Карта мест встраивания (проверено на 13.2)

Строки приведены для 13.2 и будут плавать, поэтому в хуках хранятся якоря, а не номера. `✔` значит, что якорь найден скриптом и хук оформлен (`hooks/_examples/`). Остальное найдено поиском и ждёт оформления.

### 3.1. Режим призрака (из Ghostgram)

| Что | Файл и место | Как встраиваем |
|---|---|---|
| Прочтение истории | `TelegramCore/Sources/State/SynchronizePeerReadState.swift:323`, `Api.functions.messages.readHistory` ✔ | Вставка перед запросом: если держим, возвращаем состояние без отправки |
| Прочтение в обсуждениях | `TelegramEngine/Messages/ApplyMaxReadIndexInteractively.swift:222,258,300`, `messages.readDiscussion` | То же, три места |
| Содержимое (голосовое, кружок, view-once) | `State/ManagedSynchronizeConsumeMessageContentsOperations.swift:114` ✔, `State/ManagedConsumePersonalMessagesActions.swift:256,325`, `State/AccountViewTracker.swift:988`, `messages.readMessageContents` | Вставка перед запросами |
| «Печатает» | `State/ManagedLocalInputActivities.swift:184`, `messages.setTyping` ✔; тип `PeerInputActivity` (`State/PeerInputActivity.swift:69`), `Account.swift:1742` | Вставка перед запросом, фильтр по виду активности |
| Онлайн | `State/ManagedAccountPresence.swift:45`, `updatePresence`, `account.updateStatus` ✔ (строки 56 и 60) | Вставка в начале функции |
| Просмотр историй | `TelegramEngine/Messages/Stories.swift:2110`, `_internal_markStoryAsSeen` ✔; `State/ManagedSynchronizeViewStoriesOperations.swift:125`, `stories.readStories` | Вставка в начало функции |
| Отложенная отправка | `PendingMessages/EnqueueMessage.swift:761` и `:896`, `enqueueMessages` | Вставка в начало, оба варианта |
| «Онлайн всегда» | `Account.swift:1283` `shouldKeepOnlinePresence`, `:1378` `AccountPresenceManager` | Подмена источника сигнала |
| Тип/статус собеседника (для исключений) | `SyncCore/SyncCore_PeerStatusSettings.swift:41–42`, `registrationDate`, `phoneCountry` | Только чтение в профиле |
| Расширения (NSE, Share) | `Telegram/NotificationService/Sources/NotificationService.swift:765,2697` | Подключить тот же модуль политики |

Новое в 13.2 против 13.0: код обновлений состояния переехал из `State/AccountStateManagementUtils.swift` в папку `State/Sync/` (`UpdateInterpreter+ReadStates.swift` и другие). Если понадобится ловить удаления и правки (сохранение удалённых), искать там.

### 3.2. Профиль (ID, DC, даты, большая аватарка, кнопки)

Папка `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/`:

| Что | Файл и место |
|---|---|
| Строки информации в профиле | `PeerInfoProfileItems.swift:58`, `func infoItems(...)`, в ней создаются `PeerInfoScreenLabeledValueItem` (телефон `:188`, о себе `:273`). Сюда добавляем ID, DC, дату регистрации, дату создания |
| Данные профиля | `PeerInfoData.swift:1160`, `peerInfoScreenData(...)` (там же канал, `cachedData`) |
| Разделы настроек | `PeerInfoScreen.swift:164`, `enum PeerInfoSettingsSection`; `PeerInfoSettingsItems.swift:32`, `func settingsItems(...)`. Сюда добавляем пункт «Mategram» |
| Шапка | `PeerInfoHeaderNode.swift`, `PeerInfoHeaderButtonNode.swift` (круглые кнопки), `PeerInfoExpansionPolicy.swift:16` `peerInfoExpansionPath(isAvatarExpanded:)` (политика раскрытия аватарки, подходящее одно место для «аватарка сразу большая») |
| DC | В 13.2 нужный тип ресурса `CloudPeerPhotoSizeMediaResource` ищется в `TelegramCore/Sources/SyncCore/`; сам `datacenterId` берётся от `smallProfileImage` (подтвердить при реализации) |

### 3.3. Список чатов, вкладки, папки

| Что | Файл и место |
|---|---|
| Строка чата (карточки, затухание, радиус) | `ChatListUI/Sources/Node/ChatListItem.swift` |
| Список | `ChatListUI/Sources/Node/ChatListNode.swift:1225`, интеракции `:77` |
| Контроллер и узел | `ChatListUI/Sources/ChatListControllerNode.swift:1173`, `ChatListController.swift` (фон, историй-панель, свайпы, папки) |
| Таб-бар (старый) | `TabBarUI/Sources/TabBarController.swift:47`, `TabBarContollerNode.swift:12` |
| Таб-бар (компонент, стекло) | `TelegramUI/Components/TabBarComponent/Sources/TabBarComponent.swift:350` |
| Корневой контроллер (набор вкладок) | `TelegramUI/Sources/TelegramRootController.swift:77` |
| Папки | `ChatListUI/Sources/ChatContextMenus.swift`, `TelegramEngine/Peers/ChatListFiltering.swift` |

### 3.4. Чат

| Что | Файл и место |
|---|---|
| Пузырь, стекло, обводка | `TelegramUI/Components/Chat/ChatMessageBubbleItemNode/Sources/ChatMessageBubbleItemNode.swift`, `Chat/ChatMessageItemView/Sources/ChatMessageItemView.swift:663` |
| Время и статус (секунды, на стикерах) | `Chat/ChatMessageDateAndStatusNode/Sources/ChatMessageDateAndStatusNode.swift` |
| Поле ввода | `Chat/ChatTextInputPanelNode/Sources/ChatTextInputPanelNode.swift`, `AttachmentTextInputPanelNode/Sources/AttachmentTextInputPanelNode.swift:251` (Return = отправить, панель форматирования, свайп вверх) |
| Контекстное меню | `TelegramUI/Sources/ChatInterfaceStateContextMenus.swift:493` (пункты «В Избранное», «JSON», «выбрать от пользователя») |
| Контроллер и узел чата | `TelegramUI/Sources/ChatController.swift`, `ChatControllerNode.swift` (снег, редактор текста, жесты) |
| Двойной тап, жесты пузыря | в `ChatMessageBubbleItemNode.swift` |

### 3.5. Стекло, тема, шрифт, запуск

| Что | Файл и место |
|---|---|
| Материалы (Liquid Glass) | `TelegramUI/Components/GlassBackgroundComponent/Sources/GlassBackgroundComponent.swift:53` `GlassBackgroundView`, `:954` `GlassBackgroundContainerView` (сюда «холодное стекло», «блюр», «цвет вместо стекла») |
| Тема | `TelegramPresentationData/Sources/PresentationData.swift:93` и `:743` (цепочка, сюда AMOLED, цвета пузырей) |
| Шрифты | `Display/Source/Font.swift:291–303`, `regular/medium/semibold/bold` (подмена шрифта) |
| Запуск, жизненный цикл | `TelegramUI/Sources/AppDelegate.swift:239,348` |
| Отладочное меню | `DebugSettingsUI/Sources/DebugController.swift:2087,2257` (содержит штатный флаг «Skip read history») |

### 3.6. Голос, камера, звонки, сеть, перевод

| Что | Файл и место |
|---|---|
| Запись голосового (чейнджер) | `TelegramUI/Sources/ManagedAudioRecorder.swift:147` `ManagedAudioRecorderContext` |
| Сессия звука (встроенный микрофон) | `TelegramAudio/Sources/ManagedAudioSession.swift` |
| Кружки и маски | `TelegramUI/Components/VideoMessageCameraScreen/Sources/VideoMessageCameraScreen.swift:134`, `Camera/CameraLegacy/Sources/CameraOutput.swift:12`; в 13.2 появился новый `Camera/CameraNeo` (проверить, какой путь используется) |
| Звонки | `TelegramCallsUI/Sources/PresentationCall.swift:18` `PresentationCallImpl`, `:1568` `setIsMuted` (тихий mute); `PresentationCallManager.swift` (TCP); `TelegramUI/Sources/AccountContext.swift:1011` `requestCall` (подтверждение звонка) |
| Скачивание (части файла) | `TelegramCore/Sources/Network/FetchV2.swift:83,303` |
| Отправка (части файла) | `TelegramCore/Sources/Network/MultipartUpload.swift:124,149` (`useLargerParts`, `increaseParallelParts`) |
| Перевод | `TelegramEngine/Messages/Translate.swift:32,175,220` (`_internal_translate`, `translateTexts`, `translateMessages`) |
| Историй: открытие | `Stories/StoryContainerScreen/Sources/StoryContainerScreen.swift:2181` (предупреждение перед просмотром) |

## 4. Что изменилось между 13.0 и 13.2 (по реальным данным)

Я взял 1 430 мест, где Ghostgram (база 13.0) оставил свои метки в файлах Telegram, и проверил их скриптом на 13.2:

| Результат | Сколько |
|---|---|
| Отдельные строки-хуки, всего проверено | 320 |
| Якорь найден точно, окружение совпало | 130 |
| Якорь найден, окружение изменилось (проверить) | 137 |
| Приблизительно, высокая уверенность | 0 |
| Приблизительно, нужна проверка | 2 |
| Неоднозначно | 11 |
| Якорь пропал | 28 |
| Файл удалён или переехал | 3 |
| Правки внутри существующих строк (без отдельной вставки) | 929 |
| Слишком короткий якорь | 181 |

Вывод: **около 83 % вставок в этот набор переживает два релиза Telegram** (267 из 320), остальное приходится дочинивать вручную по отчёту. Файлы, которые пропали: `State/AccountStateManagementUtils.swift` (разбит на `State/Sync/*`), `TelegramUI/Sources/CoreListChatHistoryBackend.swift`, плюс служебный `GGSettingsSearchBridge.swift` (это файл самого Ghostgram). Больше всего пострадали `AppBundle`, `CameraNeo`, `ChatListItem.swift`, `StarGifts.swift`, `PresentationData.swift`, `PeerInfoScreen.swift`.

Ещё важный урок: у Ghostgram 929 правок сделаны **внутри существующих строк**, а не отдельными вставками. Такие правки хуже всего переживают обновления. Наше правило: в Telegram только отдельные строки-вставки, а если строку необходимо изменить, оформлять как `replace` с якорем по исходной строке (скрипт это умеет).

Полные данные: `docs/reference/ghostgram-hooks-vs-13.2.json` (что потерялось) и `docs/reference/ghostgram-hook-catalog.json` (166 имён хуков Ghostgram с файлами).

## 5. Хуки, которые уже оформлены и проверены

`hooks/_examples/ghost-mode.json`, 5 штук, все найдены точно на 13.2 и применяются в git как 5 добавленных строк:

| id | Файл | Что гасит |
|---|---|---|
| `ghost.typing` | `ManagedLocalInputActivities.swift` | «печатает» |
| `ghost.online` | `ManagedAccountPresence.swift` | «онлайн» |
| `ghost.read-history` | `SynchronizePeerReadState.swift` | прочтение |
| `ghost.story-views` | `Stories.swift` | просмотр историй |
| `ghost.consume-contents` | `ManagedSynchronizeConsumeMessageContentsOperations.swift` | прослушивание и просмотр содержимого |

Код этих вставок обращается к `MategramGhost`, которого в `overlay/` ещё нет, поэтому хуки лежат в папке `_examples` и по умолчанию не применяются (запуск с `--examples`). Имена переменных внутри вставок (`peerId`, `maxIncomingReadId`) и тип возврата надо будет подтвердить при первой сборке.

## 6. Что нужно для первой сборки

1. **Свои ключи Telegram**: `api_id` и `api_hash` с my.telegram.org.
2. **Подпись**: Apple Developer `team_id`, свой `bundle_id`, профили для приложения и каждого расширения. На бесплатном Apple ID ранее ловили чёрный экран из-за App Group.
3. **Файл конфигурации** по образцу `build-system/example-configuration` (`variables.bzl`, provisioning).
4. **Раннер GitHub Actions**: Telegram 13.2 требует Xcode 27.1 и macOS 27. Нужно проверить, есть ли такой образ у GitHub, иначе брать релиз Telegram, который собирается на доступном Xcode (например, 13.1.x).
5. **Объём и время**: полная сборка Telegram на облачном macOS занимает от десятков минут до часа; нужен кэш Bazel.
6. **Лицензия**: GPL-2.0, исходники клиента придётся открыть при распространении.
7. **Ограничение сборки**: нет сборки одного модуля, поэтому проверять хук можно только полной сборкой.

## 7. Следующие шаги (когда скажете)

1. Создать `overlay/Mategram/Core` (настройки, реестр, точки подключения) и модуль `MategramGhost`.
2. Перенести хуки из `_examples` в рабочую папку `hooks/`, добавить хук `BUILD` (зависимость от нашего модуля у `TelegramCore`, `TelegramUI` и расширений).
3. Оформить хуки профиля (ID, DC, даты), пункт «Mategram» в настройках, экран настроек.
4. Написать GitHub Actions workflow: `fetch --latest`, отчёт, сборка, выпуск IPA.
