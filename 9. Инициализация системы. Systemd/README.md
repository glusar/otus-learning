### Инициализация системы. Systemd 
### Задание
1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).
2. Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта ([https://gist.github.com/cea2k/1318020](https://gist.github.com/cea2k/1318020 "https://gist.github.com/cea2k/1318020")).
3. Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.

### Выполнение
#### 1. Написать service
Лог файл для наблюдения:  
```
root@test-vm:~# cat /var/log/watchlog.log  
2026-05-17T16:15:01.243644+00:00 test-vm CRON[1739]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)  
2026-05-17T16:15:01.248344+00:00 test-vm CRON[1739]: pam_unix(cron:session): session closed for user root  
2026-05-17T16:17:01.252467+00:00 test-vm CRON[1742]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)  
2026-05-17T16:17:01.255737+00:00 test-vm CRON[1742]: pam_unix(cron:session): session closed for user root  
2026-05-17T16:25:01.262581+00:00 test-vm CRON[1752]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)  
2026-05-17T16:25:01.265593+00:00 test-vm CRON[1752]: pam_unix(cron:session): session closed for user root  
2026-05-17T16:35:01.273356+00:00 test-vm CRON[1762]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0) 
ALERT  
2026-05-17T16:35:01.276663+00:00 test-vm CRON[1762]: pam_unix(cron:session): session closed for user root  
2026-05-17T16:45:01.283539+00:00 test-vm CRON[1776]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)  
2026-05-17T16:45:01.286962+00:00 test-vm CRON[1776]: pam_unix(cron:session): session closed for user root  
2026-05-17T16:55:01.293775+00:00 test-vm CRON[1784]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)  
2026-05-17T16:55:01.296769+00:00 test-vm CRON[1784]: pam_unix(cron:session): session closed for user root
```

Файл с переменными:  
```
root@test-vm:~# cat /etc/default/watchlog  
WORD="ALERT"  
LOG="/var/log/watchlog.log"  
```

Скрипт для парсинга лог-файла:
```
root@test-vm:~# cat /opt/watchlog.sh  
#!/bin/bash  
  
WORD=$1  
LOG=$2  
DATE=`date`  
  
if grep $WORD $LOG &> /dev/null  
then  
logger "$DATE: I found word, Master!"  
else  
exit 0  
fi  
```

Сервис для запуска скрипта:  
```
root@test-vm:~# cat /etc/systemd/system/watchlog.service  
[Unit]  
Description=My watchlog service  
  
[Service]  
Type=oneshot  
EnvironmentFile=/etc/default/watchlog  
ExecStart=/opt/watchlog.sh $WORD $LOG  
```

Таймер для запуска сервиса:  
```
root@test-vm:~# cat /etc/systemd/system/watchlog.timer    
[Unit]  
Description=Run watchlog script every 30 second  
  
[Timer]  
OnBootSec=30  
AccuracySec=1s  
OnUnitActiveSec=30  
Unit=watchlog.service  
  
[Install]  
WantedBy=timers.target  
```

Запуск:  
```
root@test-vm:~# chmod +x /opt/watchlog.sh  
root@test-vm:~# systemctl daemon-reload  
root@test-vm:~# systemctl start watchlog.timer  
root@test-vm:~# tail -n 1000 /var/log/syslog | grep word  
2026-05-17T15:10:31.164082+00:00 test-vm root: Sun May 17 07:10:31 PM +04 2026: I found word, Master!  
2026-05-17T15:11:02.168854+00:00 test-vm root: Sun May 17 07:11:02 PM +04 2026: I found word, Master!  
2026-05-17T15:11:33.163339+00:00 test-vm root: Sun May 17 07:11:33 PM +04 2026: I found word, Master!
```
#### 2. Установить spawn-fcgi и создать unit-файл
Установка spawn-fcgi:  
```
root@test-vm:~# apt install spawn-fcgi php php-cgi php-cli apache2 libapache2-mod-fcgid -y
```

Файл с переменными:  
```
root@test-vm:~# mkdir -p /etc/spawn-fcgi

root@test-vm:~# cat /etc/spawn-fcgi/fcgi.conf
SOCKET=/run/php-fcgi.sock
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"
```

Юнит-файл сервиса основанного на https://gist.github.com/cea2k/1318020:  
```
root@test-vm:~# cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```

Запуск и проверка:  
```
root@test-vm:~# systemctl daemon-reload 
root@test-vm:~# systemctl start spawn-fcgi.service 
root@test-vm:~# systemctl status spawn-fcgi.service 
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; preset: enabled)
     Active: active (running) since Sun 2026-05-17 21:45:24 +04; 2s ago
   Main PID: 11640 (php-cgi)
      Tasks: 33 (limit: 4601)
     Memory: 14.6M (peak: 15.0M)
        CPU: 39ms
     CGroup: /system.slice/spawn-fcgi.service
             ├─11640 /usr/bin/php-cgi
             ├─11641 /usr/bin/php-cgi
             ├─11642 /usr/bin/php-cgi
             ├─11643 /usr/bin/php-cgi
             ├─11644 /usr/bin/php-cgi
             ├─11645 /usr/bin/php-cgi
             ├─11646 /usr/bin/php-cgi
             ├─11647 /usr/bin/php-cgi
             ├─11648 /usr/bin/php-cgi
             ├─11649 /usr/bin/php-cgi
             ├─11650 /usr/bin/php-cgi
             ├─11651 /usr/bin/php-cgi
             ├─11652 /usr/bin/php-cgi
             ├─11653 /usr/bin/php-cgi
             ├─11654 /usr/bin/php-cgi
             ├─11655 /usr/bin/php-cgi
             ├─11656 /usr/bin/php-cgi
             ├─11657 /usr/bin/php-cgi
             ├─11658 /usr/bin/php-cgi
             ├─11659 /usr/bin/php-cgi
             ├─11660 /usr/bin/php-cgi
             ├─11661 /usr/bin/php-cgi
             ├─11662 /usr/bin/php-cgi
             ├─11663 /usr/bin/php-cgi
             ├─11664 /usr/bin/php-cgi
             ├─11665 /usr/bin/php-cgi
             ├─11666 /usr/bin/php-cgi
             ├─11667 /usr/bin/php-cgi
             ├─11668 /usr/bin/php-cgi
             ├─11669 /usr/bin/php-cgi
             ├─11670 /usr/bin/php-cgi
             ├─11671 /usr/bin/php-cgi
             └─11672 /usr/bin/php-cgi

May 17 21:45:24 test-vm systemd[1]: Started spawn-fcgi.service - Spawn-fcgi startup service by Otus.
```


#### 3. Доработать unit-файл Nginx
Установим nginx:  
```
root@test-vm:~# apt install nginx -y
```

Конфиг шаблонного сервиса:  
```
root@test-vm:~# cat /etc/systemd/system/nginx@.service
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx-%I.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-%I.conf -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx-%I.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

Конфиги nginx:  
```
root@test-vm:~# cat /etc/nginx/nginx-first.conf 
pid /run/nginx-first.pid;
events {}  

http {

        server {
                listen 9001;
        }
#include /etc/nginx/sites-enabled/*;

}

root@test-vm:~# cat /etc/nginx/nginx-second.conf 
pid /run/nginx-second.pid;
events {}  

http {

        server {
                listen 9002;
        }
#include /etc/nginx/sites-enabled/*;

}
```

Стартуем сервисы и проверяем:  
```
root@test-vm:~# systemctl start nginx@first.service 
root@test-vm:~# systemctl start nginx@second.service 
root@test-vm:~# systemctl status nginx@second.service 
● nginx@second.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/etc/systemd/system/nginx@.service; disabled; preset: enabled)
     Active: active (running) since Mon 2026-05-18 00:34:04 +04; 7s ago
       Docs: man:nginx(8)
    Process: 13088 ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-second.conf -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 13090 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 13091 (nginx)
      Tasks: 2 (limit: 4601)
     Memory: 1.5M (peak: 1.7M)
        CPU: 11ms
     CGroup: /system.slice/system-nginx.slice/nginx@second.service
             ├─13091 "nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;"
             └─13092 "nginx: worker process"

May 18 00:34:04 test-vm systemd[1]: Starting nginx@second.service - A high performance web server and a reverse proxy server...
May 18 00:34:04 test-vm systemd[1]: Started nginx@second.service - A high performance web server and a reverse proxy server.

root@test-vm:~# ss -tnulp | grep nginx
tcp   LISTEN 0      511                0.0.0.0:9001      0.0.0.0:*    users:(("nginx",pid=13068,fd=4),("nginx",pid=13067,fd=4))
tcp   LISTEN 0      511                0.0.0.0:9002      0.0.0.0:*    users:(("nginx",pid=13092,fd=4),("nginx",pid=13091,fd=4))

root@test-vm:~# ps afx | grep nginx
  13107 pts/1    S+     0:00                          \_ grep --color=auto nginx
  13067 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-first.conf -g daemon on; master_process on;
  13068 ?        S      0:00  \_ nginx: worker process
  13091 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;
  13092 ?        S      0:00  \_ nginx: worker process
```