# restore — Дашборд перформеров

Квартальный дашборд ранжирования продавцов re:Store по грейдам A+/A/B/C.
Показывает перформеров (все три порога), «почти перформеров», сводный рейтинг «Гонконг» и рейтинг магазинов по выручке.

**Ссылка:** https://cryheya.github.io/restore-dashboard/

---

## Как устроен pipeline

```
Перформеры_re.xlsx  →  generate_data.py  →  data.json  →  index.html  →  GitHub Pages
```

| Файл | Назначение |
|---|---|
| `index.html` | Интерфейс дашборда. Обновляется редко — только при изменении логики или UI |
| `data.json` | Данные квартала. Обновляется каждый квартал |
| `generate_data.py` | Скрипт генерации `data.json` из Excel |
| `update_dashboard.sh` | Одна команда: сгенерировать → скопировать → коммит → push |

Исходники (Excel + скрипт + локальная копия HTML) лежат в папке `!restore_perf/` на Mac.

---

## Обновление данных (каждый квартал)

### Быстрый способ — через update_dashboard.sh

В папке `Codex/restore-dashboard/` выполнить:

```bash
# Авто-определение квартала по текущей дате:
./update_dashboard.sh --auto-quarter

# Или задать квартал явно:
./update_dashboard.sh --quarter "Q3 2026"

# Если одновременно меняется index.html:
./update_dashboard.sh --quarter "Q3 2026" --with-index --message "Q3 2026: медали, новый грейд"
```

Скрипт автоматически:
1. Запускает `generate_data.py` из папки `!restore_perf/`
2. Копирует `data.json` (и `index.html` при `--with-index`) в репо
3. Делает `git commit` и `git push origin main`

### Вручную

```bash
cd ~/Library/Mobile\ Documents/com~apple~CloudDocs/\!W/\!обмен/\!restore_perf/

# Только файл перформеров:
python3 generate_data.py Перформеры_re.xlsx

# + файл с реальной выручкой магазинов (точнее):
python3 generate_data.py Перформеры_re.xlsx оффлайн.xlsx
```

Скрипт спросит квартал (например: `Q3 2026`) и создаст `data.json`.

Затем скопируй `data.json` в репо и опубликуй:

```bash
cd ~/Library/Mobile\ Documents/com~apple~CloudDocs/\!W/\!обмен/Codex/restore-dashboard/
cp ../\!restore_perf/data.json .
git add data.json
git commit -m "Update dashboard data Q3 2026"
git push origin main
```

---

## Первая установка

1. Установи Python 3: https://python.org/downloads
2. Установи зависимости:
   ```bash
   pip install pandas openpyxl
   ```
3. Клонируй репо:
   ```bash
   git clone git@github.com:Cryheya/restore-dashboard.git
   ```
4. GitHub Pages уже настроен: Settings → Pages → Source: `main` / `/ (root)`

---

## Пороги перформера

Настраиваются в начале `generate_data.py`:

| Метрика | Порог |
|---|---|
| СБП (доля оплат через СБП) | ≥ 40% |
| АТА | ≥ 60% |
| Оборот | ≥ среднего по грейду (считается автоматически) |

Пороги также можно изменить вживую в разделе **⚙ Настройки** дашборда — без перегенерации данных.

---

## Структура data.json

| Поле | Содержимое |
|---|---|
| `quarter` | Период, например `Q2 2026` |
| `period` | Текстовая подпись, например `Апр — Июн` |
| `avgs` | Средний оборот по грейду (порог), млн |
| `total_stores` | Кол-во магазинов по грейдам |
| `all_staff` | Все ранжированные сотрудники по грейдам |
| `performers` | Только перформеры (все 3 порога выполнены) |
| `near_miss` | «Почти перформеры» (не хватает ровно одного критерия) |
| `stores` | Рейтинг магазинов по выручке |
| `hongkong` | Сводный рейтинг всех продавцов (квалификация по СБП/АТА, без порога оборота) |
| `rd_map` | Маппинг РД → список магазинов (для фильтрации) |

Каждый перформер, занявший место 1–3 в грейде, имеет поле `medal`:
```json
{ "tier": 1, "label": "1 место" }
```
Tier 1 = 🥇, tier 2 = 🥈, tier 3 = 🥉.
