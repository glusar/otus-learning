### Управление процессами
### Задание
**Вариант 1. Реализация аналога ps ax**
- Создайте скрипт, который получает информацию о процессах через файловую систему /proc.
- Реализуйте вывод не менее следующих полей: PID, PPID, состояние процесса, имя или команда запуска.
- Проверьте работу скрипта на запущенной системе.
- Зафиксируйте пример результата работы.

Ожидаемый результат:  
рабочий скрипт, выводящий список процессов по данным из /proc.  

### Скрипт
Для запуска достаточно сделать скрипт `psax.sh` исполняемым и запустить:  
```bash
chmod +x ./psax.sh
./psax.sh
```

Пример вывода скрипта:
```
----------------------


PID = 78

PPID =  2

Status =        I (idle)

Command =       kworker/u17

----------------------


PID = 78579

PPID =  3424

Status =        S (sleeping)

Command = /snap/firefox/8387/usr/lib/firefox/firefox -contentproc -isForBrowser -prefsHandle 0:47466 -prefMapHandle 1:287389 -jsInitHandle 2:156120 -parentBuildID 20260526003452 -sandboxReporter 3 -chrootClient 4 -ipcHandle 5 -initialChannelId {834c9b88-14ca-456a-b16f-e34c615bc756} -parentPid 3013 -crashReporter 6 -crashHelper 7 -greomni /snap/firefox/8387/usr/lib/firefox/omni.ja -appomni /snap/firefox/8387/usr/lib/firefox/browser/omni.ja -appDir /snap/firefox/8387/usr/lib/firefox/browser 291 tab 

----------------------


PID = 8

PPID =  2

Status =        I (idle)

Command =       kworker/R-netns

----------------------


PID = 833

PPID =  2

Status =        S (sleeping)

Command =       nvidia-modeset/kthread_q

----------------------
```