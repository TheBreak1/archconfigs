1. Открываем файл `~/.config/openbox/autostart` с помощью *nano* или *l3afpad*
2. В конце добавляем строчку:
```
setxkbmap -layout us,ru -variant -option grp:alt_shift_toggle,terminate &
```
1. Сохраняем, разлогиниваемся (а лучше вообще перезапускаемся) и заходим обратно.

Если у вас нет папки openbox то копируем её из `/etc/xdg`

### [Всё дай в круги поиграть](osu!wine.md)