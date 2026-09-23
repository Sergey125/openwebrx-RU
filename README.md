OpenWebRX+ (русская сборка)
=========

Форк [OpenWebRX+](https://github.com/luarvique/openwebrx) с добавленной русской локализацией интерфейса и несколькими дополнительными функциями. Репозиторий: https://github.com/Sergey125/openwebrx-RU

## Что добавлено в этом форке

Все функции включаются и настраиваются на странице `Settings → General → Custom Russian UI features` — без правки конфигурационных файлов вручную.

* **Перевод интерфейса на русский** — переводятся подписи меню, кнопки, подсказки на главной странице приёмника и (отдельным, более полным словарём) на странице администрирования `/settings`. Значения полей (введённые данные, URL, позывные, пароли) не переводятся — затрагивается только видимый текст интерфейса.
* **Переключатель языка RU/EN** — кнопка на странице позволяет посетителю переключаться между русским и английским, выбор запоминается в браузере.
* **Кнопка «Сообщить о проблеме»** — плавающая кнопка, отправляющая отчёт (что не работает, комментарий, текущая частота и профиль) на заданный вебхук.
* **Голосование слушателей перед сменой профиля SDR** — если приёмник слушают несколько человек одновременно, смена профиля запрашивает подтверждение у остальных слушателей через заданный вебхук.
* **Уведомление о запуске приёмника** — если данные с SDR не идут дольше нескольких секунд после подключения, показывается уведомление «приёмник запускается».
* **Скрытие ссылки на вход в администрирование** — опционально прячет ссылку на `/settings` с главной страницы.

Разворачивается как обычный Docker-стек — см. [Dockerfile](Dockerfile) и [docker-compose.yml](docker-compose.yml) (например, через [Dockge](https://github.com/louislam/dockge)). Образ собирается поверх официального [slechev/openwebrxplus-softmbe](https://hub.docker.com/r/slechev/openwebrxplus-softmbe) — наши изменения накладываются как патч ([patches/ru-localization.patch](patches/ru-localization.patch)), а не подменяют файлы целиком, поэтому обновления апстрима продолжают подхватываться автоматически (сборка идёт ежедневно по расписанию, см. [.github/workflows/docker-build.yml](.github/workflows/docker-build.yml)). Если апстрим настолько поменяет один из затронутых файлов, что патч перестанет накладываться, сборка упадёт с понятной ошибкой вместо того, чтобы молча затереть их изменения.

### Как обновить патч после правки исходников

Если меняете `htdocs/index.html`, `htdocs/include/header.include.html`, `owrx/config/defaults.py`, `owrx/controllers/settings/general.py` или `owrx/controllers/template.py` — патч нужно перегенерировать:

```bash
# 1. Вытащить оригиналы (какими они сейчас есть в свежем базовом образе)
docker pull slechev/openwebrxplus-softmbe:latest
mkdir -p /tmp/orig
for f in htdocs/index.html htdocs/include/header.include.html owrx/config/defaults.py \
         owrx/controllers/settings/general.py owrx/controllers/template.py; do
  docker run --rm --entrypoint cat slechev/openwebrxplus-softmbe:latest \
    "/usr/lib/python3/dist-packages/$f" > "/tmp/orig/$(basename "$f")"
done

# 2. Собрать диффы в один патч (a/ = оригинал, b/ = наша версия из репозитория)
rm -rf /tmp/pdiff && mkdir -p /tmp/pdiff
python3 - <<'PY'
import os, shutil
files = {
  "index.html": "htdocs/index.html",
  "header.include.html": "htdocs/include/header.include.html",
  "defaults.py": "owrx/config/defaults.py",
  "general.py": "owrx/controllers/settings/general.py",
  "template.py": "owrx/controllers/template.py",
}
for key, rel in files.items():
    for side, src in (("a", f"/tmp/orig/{key}"), ("b", rel)):
        dst = f"/tmp/pdiff/{side}/{rel}"
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy(src, dst)
PY
cd /tmp/pdiff && diff -ruN a b > "$OLDPWD/patches/ru-localization.patch"
cd "$OLDPWD"
```

Затем `docker build` локально, чтобы убедиться, что патч применяется чисто, и закоммитить обновлённый `patches/ru-localization.patch`.

---

Ниже — исходное описание проекта OpenWebRX+ (переведено с английского).

Это **улучшенная версия** онлайн-приёмника OpenWebRX. Готовые пакеты OpenWebRX+ доступны в [репозитории пакетов](https://luarvique.github.io/ppa/). Готовые образы дисков — на [странице релизов](https://github.com/luarvique/openwebrx/releases). Черновик [документации](https://fms.komkon.org/OWRX/) OpenWebRX+ уже доступен. Новости, поддержка и общее обсуждение — в [Telegram-канале](https://t.me/openwebrx) и связанном [чате](https://t.me/openwebrx_chat). Функции OpenWebRX+, которых нет в оригинальной версии:
* Декодеры AIS, SSTV, FAX, FLEX, POCSAG, HFDL, VDL2, ADSB, ACARS, ISM, RDS, SAM, SITOR-B, RTTY и CW.
* Декодеры DTMF, EEA, EIA, CCIR и несколько декодеров ZVEY SELCALL.
* Фоновое декодирование SSTV и FAX с браузером принятых изображений.
* Встроенный чат между пользователями приёмника.
* Встроенный рекордер принимаемого звука.
* Встроенный сканер по закладкам.
* Возможность администратора видеть подключения пользователей и банить нарушителей.
* Настраиваемое подавление шума на основе спектрального вычитания.
* Настраиваемый шаг перестройки.
* Автоматически создаваемые закладки для коротковолнового вещания.
* Автоматически создаваемые закладки для ближайших любительских ретрансляторов.
* Панорамирование и масштабирование водопада на сенсорных устройствах.
* Управление полосой пропускания колесом мыши.
* Улучшенная настройка в режиме CW.
* Более надёжная работа устройств SDRPlay.
* Карта показывает другие публичные веб-SDR по всему миру.
* Карта показывает коротковолновые вещательные станции по всему миру.
* Карта показывает положение воздушных судов, полученное через ADSB, VDL2, HFDL.
* Карта показывает ближайшие любительские ретрансляторы.
* Более подробная информация на карте: расстояния, пути APRS, погода и т.д.
* Поддержка настраиваемого тайм-аута сеанса со страницей политики использования.
* Поддержка протокола HTTPS (требуется сертификат).
* Сворачиваемая панель приёмника с настраиваемой прозрачностью.
* Отображение спектра.

Оригинальный OpenWebRX
=========

OpenWebRX — многопользовательское SDR-приёмное ПО с веб-интерфейсом.

![OpenWebRX](https://www.openwebrx.de/gfx/openwebrx-screenshot.png)

Возможности:

- Демодуляторы на основе [csdr](https://github.com/jketterl/csdr) (AM/FM/SSB/CW/BPSK31/BPSK63)
- Полосу пропускания фильтра можно задать через интерфейс
- Активно использует возможности HTML5: WebSocket, Web Audio API, Canvas
- Работает в Google Chrome, Chromium и Mozilla Firefox
- Поддерживает широкий спектр [SDR-оборудования](https://github.com/jketterl/openwebrx/wiki/Supported-Hardware#sdr-devices)
- Возможна одновременная работа нескольких SDR-устройств
- Демодуляторы на основе [digiham](https://github.com/jketterl/digiham) (DMR, YSF, Pocsag, D-Star, NXDN)
- Демодуляторы на основе [wsjt-x](https://wsjt.sourceforge.io/) (FT8, FT4, WSPR, JT65, JT9, FST4,
  FST4W)
- Демодуляция APRS-пакетов на основе [direwolf](https://github.com/wb2osz/direwolf)
- Поддержка [JS8Call](http://js8call.com/)
- Поддержка [DRM](https://github.com/jketterl/openwebrx/wiki/DRM-demodulator-notes)
- Поддержка [FreeDV](https://github.com/jketterl/openwebrx/wiki/FreeDV-demodulator-notes)
- Поддержка M17 на основе [m17-cxx-demod](https://github.com/mobilinkd/m17-cxx-demod)

## Установка

Доступны следующие способы установки приёмника:

- Образы SD-карт для Raspberry Pi
- Репозиторий Debian
- Docker-образы
- Установка вручную

Подробности по каждому способу — в [руководстве по установке на wiki](https://github.com/jketterl/openwebrx/wiki/Setup-Guide).

## Сообщество

Если возникли проблемы с установкой или настройкой приёмника, есть отличная идея, которую хотите увидеть реализованной,
или просто хочется пообщаться на темы OpenWebRX — заходите в
[нашу группу groups.io](https://groups.io/g/openwebrx).

Если хотите пообщаться напрямую с разработчиками, операторами приёмников или другими пользователями — заходите в
[наш Discord-сервер](https://discord.gg/gnE9hPz).

## Советы по использованию

Водопад можно масштабировать колесом мыши. Также его можно перетаскивать для панорамирования.

Границы фильтра можно перетаскивать за края, изменяя полосу пропускания.

Если удерживать Shift, можно перетаскивать центральную линию (BFO) или всю полосу целиком (PBS).

## Лицензия

OpenWebRX распространяется под лицензией Affero GPL v3
([краткое описание](https://tldrlegal.com/license/gnu-affero-general-public-license-v3-(agpl-3.0))).

OpenWebRX также доступен по коммерческой лицензии по запросу. Для вопросов лицензирования пишите на адрес
*&lt;randras@sdr.hu&gt;*.
