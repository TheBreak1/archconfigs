# **ХОЧУ ИГРАТЬ В КРУЖОЧКИ КАК ПРО КАК ГАША КАК ВИДИК СТАНУ 2ДИГИТОМ РОДИТЕЛИ БУДУТ ГОРДИТЬСЯ**

Здесь лежит несколько гайдов по отдельности, если нужно что-то конкретное. Для установки с нуля начните с [Install.md](guides/Install.md) .

Так же здесь лежат уже готовые конфиги для приложений, они ставятся по гайду во время установки, но на всякий расписано, как это сделать самому. Если кто-то умный может настрочить скрипт для раскидки этого добра - лмк @t_brk1

0168:err:mmdevapi:init_driver No driver from L"pulse,alsa,oss,coreaudio" could be initialized. Maybe check dependencies with WINEDEBUG=warn+module.

## Список гайдов
  
  - [Установка Arch Linux](guides/Install.md)
  
  - [Установка рядом с Windows (дуалбут)](guides/Dualboot.md)
  
  - [Список и установка нужного софта](guides/Applist.md)
 
  - [Русская раскладка клавиатуры](guides/rusn9keeb.md)

  - [Установка Wine+osu!stable](guides/osu!wine.md)
  
  - [Конфиг Pipewire](guides/Pipewire.md)
  
  - [Настройка OpenTabletDriver](guides/OTD.md)
  
  - [Конфиг Wooting клавиатур](guides/Wooting.md)

  - [Открытие разделов Linux на Windows и наоборот](FS.md)
  
  - [Создание ссылок на старые установки osu!](Links.md)
 
  - Debloat xd
 
  - MIME файлы для стэйбла и лазера отдельно (Открыть с...)

  - Что-то ещё...


## post-install.sh

Я снова навернул флеш ультра
[[Post install script]]

**WIP ЖИРНЫМИ**

```
git clone https://github.com/TheBreak1/archconfigs.git
cd archconfigs
chmod +x post-install.sh
sudo ./post-install.sh
```

## ТУДУ
- [ ] Отсортировать пакеты по приоритетам (первый, второй, AUR)
- [ ] скрипт для OTD приколов или, если проще, замена файлов
- [ ] скрипт(готовые файлы?) для osu-wine чтоб ничего, по возможности, не писать
- [X] Файлик для настройки вутинга
- [ ] мб такой же файлик под сайо существует?
- [X] перепись ~~населения~~ гайда, чтобы этим гитом пользовались
- [x] добавить сюда osu-wine
- [ ] микрогайд по монтированию диска с кругами и ссылкам
- [ ] микрогайд по деблоту и так почти чистой установки

ЧТО ВПРИНЦИПЕ ДОЛЖНО ДЕЛАТЬСЯ (судя по [гайду](https://telegra.ph/osu-low-latency-guide-02-03))

0. вообще в приоритете я бы поставил paru и остальные проги
1.  конфиги и бинды для i3+rofi, в моём случае Openbox+rofi и GTK3 тема
2.  настройка wine, загрузка стэйбла, скрипт запуска и .desktop файл
3.  опа, кастомный wine
4.  настройка аудио сервера (всё в ~/.config, W)
5.  загрузка/установка OTD
6.  настройки под Wooting 60HE, оно летит в /etc

[**ПОДПИСЫВАЕМСЯ НА ВУДЕКА, ГОВОРИМ СПАСИБО**](https://t.me/vudekosu)

пару слов про гайд на текущий момент (читать с пеной изо рта)

![{61566F31-3E1A-4A73-ABDE-CA31C7E5D3DC}](https://github.com/user-attachments/assets/e0d55c88-7ac1-48a1-844e-2579f28a3dc6)

## Credits

[**Vudek**](https://osu.ppy.sh/users/8816345) -- Изначальный гайд, Конфиги на вутинг и Pipewire.

[**The_Break**](https://osu.ppy.sh/users/8610746) -- Обновление гайда, конфиги Openbox

**???** -- Пропатченый Wine
