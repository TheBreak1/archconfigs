# **ХОЧУ ИГРАТЬ В КРУЖОЧКИ КАК ПРО КАК ГАША КАК ВИДИК СТАНУ 2ДИГИТОМ РОДИТЕЛИ БУДУТ ГОРДИТЬСЯ**

Здесь лежит несколько гайдов по отдельности, если нужно что-то конкретное. Для установки с нуля начните с [Install.md](guides/Install.md) .

Так же здесь лежат уже готовые конфиги для приложений, они ставятся по гайду во время установки, но на всякий расписано, как это сделать самому. Ведутся работы по автоматизации - лмк @t_brk1

0168:err:mmdevapi:init_driver No driver from L"pulse,alsa,oss,coreaudio" could be initialized. Maybe check dependencies with WINEDEBUG=warn+module.

## Список гайдов
  
  - [Установка Arch Linux](guides/Install.md)
  
  - [Установка рядом с Windows (дуалбут)](guides/Dualboot.md)
  
  - [Список и установка нужного софта](guides/Applist.md)
 
  - [Русская раскладка клавиатуры](guides/rusn9keeb.md)

  - [Установка Wine+osu!stable](guides/osu!wine.md)
  
  - [Конфиг Pipewire](guides/Pipewire.md)
  
  - [Настройка OpenTabletDriver](guides/OTD.md)
  
  - [Конфиг Wooting клавиатур (сделано скриптом)](guides/Wooting.md)

  - [Открытие разделов Linux на Windows и наоборот](guides/FS.md)
  
  - [Создание ссылок на старые установки osu!](guides/Links.md)
 
  - Debloat xd
 
  - MIME файлы для стэйбла и лазера отдельно (Открыть с...)

  - Что-то ещё...


## Установочный скрипт

**WIP ЖИРНЫМИ**

Пока наворачивается флеш ультра ведётся работа над набором скриптов, чтобы всё автоматизировать. Фундамент в качестве загрузки репозитория и меню выбора скриптов уже есть. Для запуска \\/ \\/ \\/

```
curl -sSL https://raw.githubusercontent.com/TheBreak1/archconfigs/main/scripts/start.sh | sudo bash
```
dev branch
```
curl -sSL https://raw.githubusercontent.com/TheBreak1/archconfigs/dev/scripts/start.sh | sudo bash
```

Сначала качается стартовый скрипт, который выгружает репозиторий, ставит самую базу для работы в терминале и запускает `menu.sh`, через который уже на выбор стартует всё остальное.

## ТУДУ

### СКРИПТЫ
- [X] start.sh - загрузка репы и запуск menu.sh
- [ ]     url покороче
- [ ]     тарболы куда-то закинуть, долго качает
- [ ]     по возможности переделать всё под запуск с archiso
- [X] menu.sh - выбор скриптов с репозитория
- [X] i3.sh - установка i3 чётко по гайду
- [ ]     можно лучше тк автоматика
- [x] openbox.sh - десктопоподобное на базе Openbox + пара прог
- [ ]     подчистить перенос
- [ ]     валлпапер?
- [ ]     rEFInd
- [ ] stable.sh - установка osu!stable, вайна для х32 и ещё вайна
- [ ]     плохо начал, надо переписать с перезапусками скрипта от других лиц
- [ ] pipewire.sh - Переброс конфигов pipewire, спс что гайд обновил
- [ ]     глянуть, как подменку кинуть
- [ ]     pipewire-media-session is deprecated and will soon be removed from the repositories. Please use "wireplumber" instead.
- [ ] otd.sh - установка OpenTabletDriver
- [ ]     разобраться с правами
- [x] wooting.sh - переброс udev правил под Wooting
- [ ]     А под сайо возможно подобное устроить?

### ГАЙДЫ
- [ ] Applist.md - снести к херам
- [x] Dualboot.md - я доволен, тестил на железе
- [x] FS.md - 0 движений в консоли, спасибо скрипт
- [x] Install.md - обновить под реалии скрипта и уменьшить движения = не ставить проги через archinstall
- [ ] Links.md - не добил под стэйбл, сорь
- [ ] osu!wine.md - вообще под копирку надо
- [ ] OTD.md - тоже
- [ ] Pipewire.md - тоже
- [ ] rusn9keeb.md - легаси, впихнуто в конфиги, надо удалить
- [ ] микрогайд по деблоту и так почти чистой установки


[**ПОДПИСЫВАЕМСЯ НА ВУДЕКА, ГОВОРИМ СПАСИБО**](https://t.me/vudekosu)

## Credits

[**Vudek**](https://osu.ppy.sh/users/8816345) -- Изначальный гайд

[**The_Break**](https://osu.ppy.sh/users/8610746) -- Обновление гайда, конфиги Openbox

**???** -- Пропатченый Wine
