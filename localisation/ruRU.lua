-- Russian (RU) locale ZamestoTV
local LOCALE = GetLocale()
if LOCALE ~= "ruRU" then return end

local L = _G.SecretChecklistLocale or {}

-- General
L["ADDON_NAME"] = "Secret Checklist"
L["ADDON_LOADED"] = "Загружен. Введите /secrets, чтобы открыть."

-- UI Elements
L["WINDOW_TITLE"] = "Secret Checklist"
L["PAGE_FORMAT"] = "Страница %d / %d"
L["SECRETS"] = "Секреты"
L["MIND_SEEKER"] = "Искатель разума"

-- Filter
L["FILTER"] = "Фильтр"
L["FILTER_WITH_COUNT"] = "Фильтр (%d)"
L["FILTER_BY_STATUS"] = "По статусу"
L["FILTER_BY_TYPE"] = "По типу"
L["FILTER_ALL"] = "Все"
L["FILTER_COLLECTED"] = "Собрано"
L["FILTER_MISSING"] = "Недостающие"
L["FILTER_NOT_COLLECTED"] = "Не собрано"
L["FILTER_SELECT_ALL"] = "Выбрать все"
L["FILTER_DESELECT_ALL"] = "Снять выделение"
L["FILTER_BY_TRACKER"] = "Фильтр по трекеру"
L["FILTER_MIND_SEEKER_ONLY"] = "Только «Искатель разума»"
L["SORT_BY"] = "Сортировка"
L["SORT_TYPE"] = "По типу"
L["SORT_NAME"] = "По названию"
L["SORT_STATUS"] = "По статусу"
L["SORT_STATUS_INC"] = "Сначала незавершенные"
L["SORT_STATUS_COL"] = "Сначала собранные"
-- Entry Types (singular)
L["KIND_TOY"] = "Игрушка"
L["KIND_MOUNT"] = "Средство передвижения"
L["KIND_PET"] = "Питомец"
L["KIND_ACHIEVEMENT"] = "Достижение"
L["KIND_TRANSMOG"] = "Трансмогрификация"
L["KIND_QUEST"] = "Задание"
L["KIND_MANUAL"] = "Руководство"
L["KIND_HOUSING"] = "Предмет декора"
L["KIND_MYSTERY"] = "Тайна"

-- Entry Types (plural - for filter menu)
L["KIND_TOYS"] = "Игрушки"
L["KIND_MOUNTS"] = "Транспорт"
L["KIND_PETS"] = "Питомцы"
L["KIND_ACHIEVEMENTS"] = "Достижения"
L["KIND_TRANSMOGS"] = "Трансмогрификация"
L["KIND_QUESTS"] = "Задания"
L["KIND_HOUSINGS"] = "Декор (жилье)"
L["KIND_MYSTERIES"] = "Тайны"

-- Tooltips
L["TOOLTIP_CLICK_TOGGLE"] = "ЛКМ: открыть/закрыть окно"
L["TOOLTIP_DRAG_MOVE"] = "Перетащите, чтобы переместить"
L["TOOLTIP_COLLECTED"] = "Собрано"
L["TOOLTIP_NOT_COLLECTED"] = "Не собрано"
L["TOOLTIP_COMPLETED"] = "Завершено"
L["TOOLTIP_NOT_COMPLETED"] = "Не завершено"

-- Settings
L["SETTINGS_TITLE"] = "SecretChecklist"
L["SETTINGS_MINIMAP_BUTTON"] = "Кнопка у миникарты"
L["SETTINGS_MINIMAP_BUTTON_DESC"] = "Показать или скрыть кнопку SecretChecklist у миникарты."

-- Slash Commands
L["CMD_OPTIONS"] = "Открытие настроек..."
L["CMD_MINIMAP_SHOW"] = "Кнопка у миникарты включена."
L["CMD_MINIMAP_HIDE"] = "Кнопка у миникарты скрыта."

-- Status Messages
L["DATA_NOT_READY"] = "Данные коллекции еще не готовы. Попробуйте один раз открыть окно коллекций."
L["UNKNOWN"] = "(неизвестно)"

-- About tab
L["TAB_ABOUT"]            = "О аддоне"
L["ABOUT_BY"] = "Автор: Calaglyn"
L["ABOUT_DESC"] = "Отслеживание секретных предметов в World of Warcraft.\nТранспорт, питомцы, игрушки, достижения, задания и трансмогрификация."
L["ABOUT_THANKS_HEADER"] = "Особая благодарность"
L["ABOUT_THANKS_TEXT"] = "Огромное спасибо сообществу Secret Finding Discord\nза невероятную работу по поиску этих секретов\nи составление руководств по их получению."
L["ABOUT_DISCORD_LABEL"] = "Discord «Secret Finding»"

-- Theme
L["SETTINGS_THEME"]      = "Тема оформления"
L["SETTINGS_THEME_DESC"] = "Выберите визуальную тему для SecretChecklist."

-- Minimap button
L["TOOLTIP_RIGHT_CLICK_OPTIONS"] = "ПКМ: открыть настройки"

_G.SecretChecklistLocale = L
