### Задание 1
1. Запустить nginx на нестандартном порту 3-мя разными способами
	- переключатели setsebool;
	- добавление нестандартного порта в имеющийся тип;
	- формирование и установка модуля SELinux.

#### Выполнение
Процесс создания машины
```
    selinux:
    selinux: Complete!
    selinux: Job for nginx.service failed because the control process exited with error code.
    selinux: See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
    selinux: × nginx.service - The nginx HTTP and reverse proxy server
    selinux:      Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
    selinux:      Active: failed (Result: exit-code) since Sat 2026-06-20 19:30:15 UTC; 11ms ago
    selinux:     Process: 5359 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    selinux:     Process: 5360 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
    selinux:         CPU: 14ms
    selinux:
    selinux: Jun 20 19:30:15 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
    selinux: Jun 20 19:30:15 selinux nginx[5360]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    selinux: Jun 20 19:30:15 selinux nginx[5360]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
    selinux: Jun 20 19:30:15 selinux nginx[5360]: nginx: configuration file /etc/nginx/nginx.conf test failed
    selinux: Jun 20 19:30:15 selinux systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
    selinux: Jun 20 19:30:15 selinux systemd[1]: nginx.service: Failed with result 'exit-code'.
    selinux: Jun 20 19:30:15 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
The SSH command responded with a non-zero exit status. Vagrant
assumes that this means the command failed. The output for this command
should be in the log above. Please read the output to determine what
went wrong.
```

Заходим на ВМ и проверяем nginx
```
rasul@EniacLin:~/myfiles/vagrant$ vagrant ssh
[fog][WARNING] Unrecognized arguments: libvirt_ip_command
[vagrant@selinux ~]$ systemctl status firewalld
○ firewalld.service - firewalld - dynamic firewall daemon
     Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; preset: enabled)
     Active: inactive (dead)
       Docs: man:firewalld(1)

[vagrant@selinux ~]$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

##### Способ 1
Проверяем selinux и логи
```
[vagrant@selinux ~]$ sudo -i
[root@selinux ~]# getenforce
Enforcing
[root@selinux ~]# sealert -a /var/log/audit/audit.log
100% done
found 1 alerts in /var/log/audit/audit.log
--------------------------------------------------------------------------------

SELinux is preventing /usr/sbin/nginx from name_bind access on the tcp_socket port 4881.

*****  Plugin bind_ports (92.2 confidence) suggests   ************************

If you want to allow /usr/sbin/nginx to bind to network port 4881
Then you need to modify the port type.
Do
# semanage port -a -t PORT_TYPE -p tcp 4881
    where PORT_TYPE is one of the following: http_cache_port_t, http_port_t, jboss_management_port_t, jboss_messaging_port_t, ntop_port_t, puppet_port_t.

*****  Plugin catchall_boolean (7.83 confidence) suggests   ******************

If you want to allow nis to enabled
Then you must tell SELinux about this by enabling the 'nis_enabled' boolean.

Do
setsebool -P nis_enabled 1

*****  Plugin catchall (1.41 confidence) suggests   **************************

If you believe that nginx should be allowed name_bind access on the port 4881 tcp_socket by default.
Then you should report this as a bug.
You can generate a local policy module to allow this access.
Do
allow this access for now by executing:
# ausearch -c 'nginx' --raw | audit2allow -M my-nginx
# semodule -X 300 -i my-nginx.pp


Additional Information:
Source Context                system_u:system_r:httpd_t:s0
Target Context                system_u:object_r:unreserved_port_t:s0
Target Objects                port 4881 [ tcp_socket ]
Source                        nginx
Source Path                   /usr/sbin/nginx
Port                          4881
Host                          <Unknown>
Source RPM Packages           nginx-core-1.20.1-28.el9_8.2.alma.1.x86_64
Target RPM Packages
SELinux Policy RPM            selinux-policy-targeted-38.1.75-2.el9_8.noarch
Local Policy RPM              selinux-policy-targeted-38.1.75-2.el9_8.noarch
Selinux Enabled               True
Policy Type                   targeted
Enforcing Mode                Enforcing
Host Name                     selinux
Platform                      Linux selinux 5.14.0-427.28.1.el9_4.x86_64 #1 SMP
                              PREEMPT_DYNAMIC Fri Aug 2 03:44:10 EDT 2024 x86_64
                              x86_64
Alert Count                   1
First Seen                    2026-06-20 19:30:15 UTC
Last Seen                     2026-06-20 19:30:15 UTC
Local ID                      7c3ec80d-0789-4be3-a8b3-6f1e5be747ce

Raw Audit Messages
type=AVC msg=audit(1781983815.974:745): avc:  denied  { name_bind } for  pid=5360 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0


type=SYSCALL msg=audit(1781983815.974:745): arch=x86_64 syscall=bind success=no exit=EACCES a0=6 a1=555e990d86b0 a2=10 a3=7ffc48ed8f90 items=0 ppid=1 pid=5360 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm=nginx exe=/usr/sbin/nginx subj=system_u:system_r:httpd_t:s0 key=(null)ARCH=x86_64 SYSCALL=bind AUID=unset UID=root GID=root EUID=root SUID=root FSUID=root EGID=root SGID=root FSGID=root

Hash: nginx,httpd_t,unreserved_port_t,tcp_socket,name_bind

```

Берем строчку с ошибкой nginx и анализируем с помощью audit2why
```
[root@selinux ~]# grep 1781983815.974:745 /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1781983815.974:745): avc:  denied  { name_bind } for  pid=5360 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
```

Переключаем политику с помощью setsebool
```
[root@selinux ~]# setsebool -P nis_enabled 1
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Sat 2026-06-20 19:52:23 UTC; 4s ago
    Process: 5463 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 5464 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 5465 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 5466 (nginx)
      Tasks: 3 (limit: 12101)
     Memory: 2.9M
        CPU: 51ms
     CGroup: /system.slice/nginx.service
             ├─5466 "nginx: master process /usr/sbin/nginx"
             ├─5467 "nginx: worker process"
             └─5468 "nginx: worker process"

Jun 20 19:52:23 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 20 19:52:23 selinux nginx[5464]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 20 19:52:23 selinux nginx[5464]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 20 19:52:23 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
[root@selinux ~]# getsebool -a | grep nis_enabled
nis_enabled --> on
```

Отключаем политику
```
[root@selinux ~]# setsebool -P nis_enabled off
[root@selinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
```

##### Способ 2
Ищем подходящий тип
```
[root@selinux ~]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```

Добавляем в тип нужный порт
```
[root@selinux ~]# semanage port -a -t http_port_t -p tcp 4881
[root@selinux ~]# semanage port -l | grep http_port_t
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Sun 2026-06-21 11:41:00 UTC; 3s ago
    Process: 5733 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 5734 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 5736 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 5737 (nginx)
      Tasks: 3 (limit: 12101)
     Memory: 2.9M
        CPU: 27ms
     CGroup: /system.slice/nginx.service
             ├─5737 "nginx: master process /usr/sbin/nginx"
             ├─5738 "nginx: worker process"
             └─5739 "nginx: worker process"

Jun 21 11:41:00 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 21 11:41:00 selinux nginx[5734]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 21 11:41:00 selinux nginx[5734]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 21 11:41:00 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```

Удаляем порт из типа
```
[root@selinux ~]# semanage port -d -t http_port_t -p tcp 4881
[root@selinux ~]# semanage port -l | grep http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
[root@selinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
[root@selinux ~]# systemctl start nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
```

##### Способ 3
Создаем модуль с помощью audit2allow на основе данных из лога
```
[root@selinux ~]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:
```

Устанавливаем модуль
```
semodule -i nginx.pp

[root@selinux ~]# semodule -i nginx.pp
[root@selinux ~]# systemctl start nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Sun 2026-06-21 14:47:08 UTC; 3s ago
    Process: 5944 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 5945 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 5946 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 5947 (nginx)
      Tasks: 3 (limit: 12101)
     Memory: 2.9M
        CPU: 27ms
     CGroup: /system.slice/nginx.service
             ├─5947 "nginx: master process /usr/sbin/nginx"
             ├─5948 "nginx: worker process"
             └─5949 "nginx: worker process"

Jun 21 14:47:08 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 21 14:47:08 selinux nginx[5945]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 21 14:47:08 selinux nginx[5945]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 21 14:47:08 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```

Удаляем модуль
```
[root@selinux ~]# semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
```

### Задание 2
2. Обеспечить работоспособность приложения при включенном selinux
	- развернуть приложенный стенд [https://github.com/Nickmob/vagrant_selinux_dns_problems](https://github.com/Nickmob/vagrant_selinux_dns_problems); 
	- выяснить причину неработоспособности механизма обновления зоны (см. README);
	- предложить решение (или решения) для данной проблемы;
	- выбрать одно из решений для реализации, предварительно обосновав выбор;
	- реализовать выбранное решение и продемонстрировать его работоспособность.

#### Выполнение
После развертывания стенда выполняю обновление зоны, но получаю ошибку: 
```
###############################
### Welcome to the DNS lab! ###
###############################

- Use this client to test the enviroment
- with dig or nslookup. Ex:
    dig @192.168.50.10 ns01.dns.lab

- nsupdate is available in the ddns.lab zone. Ex:
    nsupdate -k /etc/named.zonetransfer.key
    server 192.168.50.10
    zone ddns.lab 
    update add www.ddns.lab. 60 A 192.168.50.15
    send

- rndc is also available to manage the servers
    rndc -c ~/rndc.conf reload

###############################
### Enjoy! ####################
###############################
Last login: Mon Jun 22 19:39:39 2026 from 192.168.121.1
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit
```

Смотрю логи, но там нет ошибок, связанных с dns:  
```
[vagrant@client ~]$ sudo -i
[root@client ~]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1782157140.327:748): avc:  denied  { dac_read_search } for  pid=3499 comm="20-chrony-dhcp" capability=2  scontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tcontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tclass=capability permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

type=AVC msg=audit(1782157140.327:748): avc:  denied  { dac_override } for  pid=3499 comm="20-chrony-dhcp" capability=1  scontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tcontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tclass=capability permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

```

В логах на сервере есть странная ошибка, связанная с isc-net:
```
[root@ns01 ~]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1782157141.489:750): avc:  denied  { dac_read_search } for  pid=3504 comm="20-chrony-dhcp" capability=2  scontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tcontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tclass=capability permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

type=AVC msg=audit(1782157141.489:750): avc:  denied  { dac_override } for  pid=3504 comm="20-chrony-dhcp" capability=1  scontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tcontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tclass=capability permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

type=AVC msg=audit(1782310439.861:1786): avc:  denied  { read } for  pid=8783 comm="systemd-coredum" dev="nsfs" ino=4026531841 scontext=system_u:system_r:systemd_coredump_t:s0 tcontext=system_u:object_r:nsfs_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

type=AVC msg=audit(1782414735.815:1861): avc:  denied  { write } for  pid=8461 comm="isc-net-0000" name="dynamic" dev="vda4" ino=34081148 scontext=system_u:system_r:named_t:s0 tcontext=unconfined_u:object_r:named_conf_t:s0 tclass=dir permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

```

Сравним зону localhost с конфигами в /etc/named:  
```
[root@ns01 ~]# ls -laZ /var/named/named.localhost 
-rw-r-----. 1 root named system_u:object_r:named_zone_t:s0 152 Jun 10 13:05 /var/named/named.localhost
[root@ns01 ~]# ls -laZ /etc/named
total 28
drw-rwx---.  3 root named system_u:object_r:named_conf_t:s0      121 Jun 22 19:39 .
drwxr-xr-x. 85 root root  system_u:object_r:etc_t:s0            8192 Jun 25 18:57 ..
drw-rwx---.  2 root named unconfined_u:object_r:named_conf_t:s0   56 Jun 22 19:39 dynamic
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      784 Jun 22 19:39 named.50.168.192.rev
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      610 Jun 22 19:39 named.dns.lab
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      609 Jun 22 19:39 named.dns.lab.view1
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      657 Jun 22 19:39 named.newdns.lab
```

Есть разница в метках: named_conf_t и named_zone_t. Если поискать какая метка у директории /var/named, то видно:
```
[root@ns01 ~]# semanage fcontext -l | grep named
...
/etc/named(/.*)?                                   all files          system_u:object_r:named_conf_t:s0 
/etc/named\.caching-nameserver\.conf               regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.conf                                   regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.rfc1912.zones                          regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.root\.hints                            regular file       system_u:object_r:named_conf_t:s0 
/etc/rc\.d/init\.d/named                           regular file       system_u:object_r:named_initrc_exec_t:s0 
/etc/rc\.d/init\.d/named-sdb                       regular file       system_u:object_r:named_initrc_exec_t:s0 
/etc/rc\.d/init\.d/unbound                         regular file       system_u:object_r:named_initrc_exec_t:s0 
/etc/rndc.*                                        regular file       system_u:object_r:named_conf_t:s0 
...
/var/named(/.*)?                                   all files          system_u:object_r:named_zone_t:s0 
...

```
Надо изменить метку для /etc/named на named_zone_t.  

Переключателей для политики нет, а создавать модуль особой необходимости нет, можно просто изменить тип:  
```
[root@ns01 ~]# semanage fcontext -a -t named_zone_t "/etc/named(/.*)?"
[root@ns01 ~]# restorecon -Rv /etc/named
Relabeled /etc/named from system_u:object_r:named_conf_t:s0 to system_u:object_r:named_zone_t:s0
Relabeled /etc/named/named.dns.lab from system_u:object_r:named_conf_t:s0 to system_u:object_r:named_zone_t:s0
Relabeled /etc/named/named.dns.lab.view1 from system_u:object_r:named_conf_t:s0 to system_u:object_r:named_zone_t:s0
Relabeled /etc/named/dynamic from unconfined_u:object_r:named_conf_t:s0 to unconfined_u:object_r:named_zone_t:s0
Relabeled /etc/named/dynamic/named.ddns.lab from system_u:object_r:named_conf_t:s0 to system_u:object_r:named_zone_t:s0
Relabeled /etc/named/dynamic/named.ddns.lab.view1 from system_u:object_r:named_conf_t:s0 to system_u:object_r:named_zone_t:s0
Relabeled /etc/named/named.newdns.lab from system_u:object_r:named_conf_t:s0 to system_u:object_r:named_zone_t:s0
Relabeled /etc/named/named.50.168.192.rev from system_u:object_r:named_conf_t:s0 to system_u:object_r:named_zone_t:s0
[root@ns01 ~]# ls -laZ /etc/named
total 28
drw-rwx---.  3 root named system_u:object_r:named_zone_t:s0      121 Jun 22 19:39 .
drwxr-xr-x. 85 root root  system_u:object_r:etc_t:s0            8192 Jun 25 18:57 ..
drw-rwx---.  2 root named unconfined_u:object_r:named_zone_t:s0   56 Jun 22 19:39 dynamic
-rw-rw----.  1 root named system_u:object_r:named_zone_t:s0      784 Jun 22 19:39 named.50.168.192.rev
-rw-rw----.  1 root named system_u:object_r:named_zone_t:s0      610 Jun 22 19:39 named.dns.lab
-rw-rw----.  1 root named system_u:object_r:named_zone_t:s0      609 Jun 22 19:39 named.dns.lab.view1
-rw-rw----.  1 root named system_u:object_r:named_zone_t:s0      657 Jun 22 19:39 named.newdns.lab
```

Проверка на клиенте, всё работает:  
```
[root@client ~]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
[root@client ~]# dig @192.168.50.10 www.ddns.lab

; <<>> DiG 9.16.23-RH <<>> @192.168.50.10 www.ddns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 33803
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 6a7669231390b349010000006a3d8bb9e27d7e99b4aacc79 (good)
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A

;; ANSWER SECTION:
www.ddns.lab.           60      IN      A       192.168.50.15

;; Query time: 2 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Thu Jun 25 20:12:41 UTC 2026
;; MSG SIZE  rcvd: 85

```