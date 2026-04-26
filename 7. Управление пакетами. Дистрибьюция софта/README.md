### Сборка RPM-пакета и создание репозитория

### Задание
1. Создать свой RPM (можно взять свое приложение, либо собрать к примеру Apache с определенными опциями);
2. Создать свой репозиторий и разместить там ранее собранный RPM;
3. Реализовать это все либо в Vagrant, либо развернуть у себя через Nginx и дать ссылку на репозиторий.

#### Создать свой RPM
Установим утилиты для сборки:  
```
[root@localhost ~]# dnf install -y wget rpmdevtools rpm-build createrepo yum-utils cmake gcc git nano
```

Загружаем исходники nginx:  
```
[root@localhost rpm]# mkdir rpm && cd rpm

[root@localhost rpm]# yumdownloader --source nginx
```

Распакуем исходники (появится каталог `rpmbuild`): 
```
[root@localhost rpm]# rpm -Uvh nginx*.src.rpm
```

Установим зависимости, нужные для сборки nginx (читается SPEC-файл пакета):
```
[root@localhost rpm]# yum-builddep nginx
```

Скачаем исходный код модуля ngx_brotil: 
```
[root@localhost rpm]# cd /root

[root@localhost ~]# git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli

[root@localhost ~]# cd ngx_brotli/deps/brotli

[root@localhost brotli]# mkdir out && cd out
```

Собираем модуль:
```
[root@localhost out]# cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
-- The C compiler identification is GNU 14.3.1
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /bin/cc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Build type is 'Release'
-- Performing Test BROTLI_EMSCRIPTEN
-- Performing Test BROTLI_EMSCRIPTEN - Failed
-- Compiler is not EMSCRIPTEN
-- Looking for log2
-- Looking for log2 - not found
-- Looking for log2
-- Looking for log2 - found
-- Configuring done (0.7s)
-- Generating done (0.0s)
CMake Warning:
  Manually-specified variables were not used by the project:

    CMAKE_CXX_FLAGS


-- Build files have been written to: /root/ngx_brotli/deps/brotli/out

[root@localhost out]# cmake --build . --config Release -j 2 --target brotlienc

[root@localhost out]# cd /root
```

Находим в .spec файле секцию %build и условие с "configure", добавляем: `--add-module=/root/ngx_brotli \`
```
[root@localhost ~]# vi rpmbuild/SPECS/nginx.spec
```

Собираем RPM-пакет:
```
[root@localhost out]# cd ~/rpmbuild/SPECS/

[root@localhost SPECS]# rpmbuild -ba nginx.spec -D 'debug_package %{nil}'
```
- `-b` - режим сборки
- `-a` - all, выполнить все: распаковка исходников, компиляция, установка во временную директорию, упаковка в RPM
- `-D` — определить макрос RPM
- `debug_package %{nil}` — отключает создание debug-пакета

Проверяем, что пакеты сбораны:  
```
[root@localhost SPECS]# cd /root
[root@localhost ~]# ll rpmbuild/RPMS/x86_64/
total 2248
-rw-r--r--. 1 root root   32943 Apr 26 01:12 nginx-1.26.3-2.el10.1.x86_64.rpm
-rw-r--r--. 1 root root 1138520 Apr 26 01:12 nginx-core-1.26.3-2.el10.1.x86_64.rpm
-rw-r--r--. 1 root root  896046 Apr 26 01:12 nginx-mod-devel-1.26.3-2.el10.1.x86_64.rpm
-rw-r--r--. 1 root root   21328 Apr 26 01:12 nginx-mod-http-image-filter-1.26.3-2.el10.1.x86_64.rpm
-rw-r--r--. 1 root root   33354 Apr 26 01:12 nginx-mod-http-perl-1.26.3-2.el10.1.x86_64.rpm
-rw-r--r--. 1 root root   20152 Apr 26 01:12 nginx-mod-http-xslt-filter-1.26.3-2.el10.1.x86_64.rpm
-rw-r--r--. 1 root root   55133 Apr 26 01:12 nginx-mod-mail-1.26.3-2.el10.1.x86_64.rpm
-rw-r--r--. 1 root root   88629 Apr 26 01:12 nginx-mod-stream-1.26.3-2.el10.1.x86_64.rpm
```

Скопируем в общий каталог и установим пакеты:
```
[root@localhost ~]# cp ~/rpmbuild/RPMS/noarch/* ~/rpmbuild/RPMS/x86_64/

[root@localhost ~]# cd ~/rpmbuild/RPMS/x86_64

[root@localhost x86_64]# yum localinstall *.rpm

[root@localhost x86_64]# systemctl start nginx

[root@localhost x86_64]# systemctl status nginx
```

#### Создать свой репозиторий и разместить там ранее собранный RPM
Создадим каталог repo и скопируем туда RPM-пакеты:
```
[root@localhost x86_64]# mkdir /usr/share/nginx/html/repo

[root@localhost x86_64]# cp ~/rpmbuild/RPMS/x86_64/*.rpm /usr/share/nginx/html/repo/
```

Создаем репозиторий:  
```
[root@localhost x86_64]# createrepo /usr/share/nginx/html/repo/
Directory walk started
Directory walk done - 10 packages
Temporary output repo path: /usr/share/nginx/html/repo/.repodata/
Pool started (with 5 workers)
Pool finished
```

Настроим nginx для работы с репозиторием:  
```
[root@localhost x86_64]# vi /etc/nginx/nginx.conf
```

Настроим NGINX, добавив директивы в блок server:
```
index index.html index.htm;
autoindex on;

[root@localhost x86_64]# nginx -t

[root@localhost x86_64]# nginx -s reload
```

Проверим, что nginx работает:  
```
rasul@EniacLin:~$ curl -a http://192.168.1.117/repo/
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          25-Apr-2026 22:42                   -
<a href="nginx-1.26.3-2.el10.1.x86_64.rpm">nginx-1.26.3-2.el10.1.x86_64.rpm</a>                   25-Apr-2026 22:03               32943
<a href="nginx-all-modules-1.26.3-2.el10.1.noarch.rpm">nginx-all-modules-1.26.3-2.el10.1.noarch.rpm</a>       25-Apr-2026 22:03                9357
<a href="nginx-core-1.26.3-2.el10.1.x86_64.rpm">nginx-core-1.26.3-2.el10.1.x86_64.rpm</a>              25-Apr-2026 22:03             1138520
<a href="nginx-filesystem-1.26.3-2.el10.1.noarch.rpm">nginx-filesystem-1.26.3-2.el10.1.noarch.rpm</a>        25-Apr-2026 22:03               11090
<a href="nginx-mod-devel-1.26.3-2.el10.1.x86_64.rpm">nginx-mod-devel-1.26.3-2.el10.1.x86_64.rpm</a>         25-Apr-2026 22:03              896046
<a href="nginx-mod-http-image-filter-1.26.3-2.el10.1.x86_64.rpm">nginx-mod-http-image-filter-1.26.3-2.el10.1.x86..&gt;</a> 25-Apr-2026 22:03               21328
<a href="nginx-mod-http-perl-1.26.3-2.el10.1.x86_64.rpm">nginx-mod-http-perl-1.26.3-2.el10.1.x86_64.rpm</a>     25-Apr-2026 22:03               33354
<a href="nginx-mod-http-xslt-filter-1.26.3-2.el10.1.x86_64.rpm">nginx-mod-http-xslt-filter-1.26.3-2.el10.1.x86_..&gt;</a> 25-Apr-2026 22:03               20152
<a href="nginx-mod-mail-1.26.3-2.el10.1.x86_64.rpm">nginx-mod-mail-1.26.3-2.el10.1.x86_64.rpm</a>          25-Apr-2026 22:03               55133
<a href="nginx-mod-stream-1.26.3-2.el10.1.x86_64.rpm">nginx-mod-stream-1.26.3-2.el10.1.x86_64.rpm</a>        25-Apr-2026 22:03               88629
<a href="percona-release-latest.noarch.rpm">percona-release-latest.noarch.rpm</a>                  21-Aug-2025 11:39               28532
</pre><hr></body>
</html>

```

Подключим репозиторий:  
```
[root@localhost x86_64]# cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```

Проверяем:
```
[root@localhost x86_64]# yum repolist enabled | grep otus
otus                             otus-linux
```

Добавим другой пакет в репозиторий: 
```
[root@localhost x86_64]# cd /usr/share/nginx/html/repo/

[root@localhost repo]# wget https://repo.percona.com/yum/percona-release-latest.noarch.rpm
```

Обновим метаданные репозитория:  
```
[root@localhost repo]# createrepo --update /usr/share/nginx/html/repo/
```

Установим этот пакет на хосте:
```
[root@localhost repo]# yum clean all

[root@localhost repo]# yum makecache

[root@localhost repo]# yum list | grep otus
percona-release.noarch                                 1.0-32                             otus

[root@localhost repo]# yum install -y percona-release.noarch
```
#### Реализовать это все либо в Vagrant, либо развернуть у себя через Nginx и дать ссылку на репозиторий
Так как публичного IP нет, то прикладываю скриншот с открытым репозиторием:  
![[../_attachments/localhost_screen_repo.png]]