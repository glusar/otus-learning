### Практические навыки работы с ZFS
### Задание
1. Определить алгоритм с наилучшим сжатием:
	- определить, какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);
	- создать 4 файловых системы, на каждой применить свой алгоритм сжатия;
	- для сжатия использовать либо текстовый файл, либо группу файлов.
2. Определить настройки пула.  
    С помощью команды zfs import собрать pool ZFS.  
    Командами zfs определить настройки:
	- размер хранилища;
	- тип pool;
	- значение recordsize;
	- какое сжатие используется;
	- какая контрольная сумма используется.
3. Работа со снапшотами:
	- скопировать файл из удаленной директории;
	- восстановить файл локально. zfs receive;
	- найти зашифрованное сообщение в файле secret_message.

### Выполнение
#### 1. Определение алгоритма с наилучшим сжатием
```
root@test-vm:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   20G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 18.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0 18.2G  0 lvm  /
sdb                         8:16   0    1G  0 disk
sdc                         8:32   0    1G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    1G  0 disk
sdf                         8:80   0    1G  0 disk
sdg                         8:96   0    1G  0 disk
sdh                         8:112  0    1G  0 disk
sdi                         8:128  0    1G  0 disk

root@test-vm:~# apt install zfsutils-linux
```

Создадим пулы:
```
root@test-vm:~# zpool create otus1 mirror /dev/sdb /dev/sdc

root@test-vm:~# zpool create otus2 mirror /dev/sdd /dev/sde

root@test-vm:~# zpool create otus3 mirror /dev/sdf /dev/sdg

root@test-vm:~# zpool create otus4 mirror /dev/sdh /dev/sdi

root@test-vm:~# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   960M   114K   960M        -         -     0%     0%  1.00x    ONLINE  -
otus2   960M   111K   960M        -         -     0%     0%  1.00x    ONLINE  -
otus3   960M   114K   960M        -         -     0%     0%  1.00x    ONLINE  -
otus4   960M   111K   960M        -         -     0%     0%  1.00x    ONLINE  -
```

ZFS поддерживает gzip, zle, lzjb, lz4, создадим 4 dataset и применим эти типы сжатия на каждую:
```
root@test-vm:~# zfs set compression=lzjb otus1

root@test-vm:~# zfs set compression=lz4 otus2

root@test-vm:~# zfs set compression=gzip-9 otus3

root@test-vm:~# zfs set compression=zle otus4

root@test-vm:~# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done

root@test-vm:~# ls -l /otus*
/otus1:
total 22123
-rw-r--r-- 1 root root 41227642 Apr 20 12:04 pg2600.converter.log

/otus2:
total 18019
-rw-r--r-- 1 root root 41227642 Apr 20 12:04 pg2600.converter.log

/otus3:
total 10972
-rw-r--r-- 1 root root 41227642 Apr 20 12:04 pg2600.converter.log

/otus4:
total 40290
-rw-r--r-- 1 root root 41227642 Apr 20 12:04 pg2600.converter.log

root@test-vm:~# zfs list
NAME    USED  AVAIL  REFER  MOUNTPOINT
otus1  21.8M   810M  21.6M  /otus1
otus2  17.8M   814M  17.6M  /otus2
otus3  10.9M   821M  10.7M  /otus3
otus4  39.5M   793M  39.4M  /otus4

root@test-vm:~# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.82x                  -
otus2  compressratio         2.23x                  -
otus3  compressratio         3.66x                  -
otus4  compressratio         1.00x                  -

```
Видно, что лучше всего сжатие отработало с gzip-9 на otus3 - файл занимает 10.9M  
#### 2. Определение настроек пула
```
root@test-vm:~# wget -O archieve.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'

root@test-vm:~# tar -xzvf archieve.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb

root@test-vm:~# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
        (Note that they may be intentionally disabled if the
        'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                         ONLINE
          mirror-0                   ONLINE
            /root/zpoolexport/filea  ONLINE
            /root/zpoolexport/fileb  ONLINE

```

Импортируем pool ZFS:  
```
root@test-vm:~# zpool import -d zpoolexport/ otus
root@test-vm:~# zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
        The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(7) for details.
config:

        NAME                         STATE     READ WRITE CKSUM
        otus                         ONLINE       0     0     0
          mirror-0                   ONLINE       0     0     0
            /root/zpoolexport/filea  ONLINE       0     0     0
            /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
...

```

Определим размер хранилища - 480 МБ:  
```
root@test-vm:~# zpool list otus
NAME   SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus   480M  2.09M   478M        -         -     0%     0%  1.00x    ONLINE  -

```

Определим тип pool - mirror-0:  
```
root@test-vm:~# zpool status otus
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
        The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(7) for details.
config:

        NAME                         STATE     READ WRITE CKSUM
        otus                         ONLINE       0     0     0
          mirror-0                   ONLINE       0     0     0
            /root/zpoolexport/filea  ONLINE       0     0     0
            /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```

Определим значение recordsize - 128 КБ:  
```
root@test-vm:~# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
```

Определим какое сжатие используется - zle:  
```
root@test-vm:~# zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local
```

Определим какая контрольная сумма используется - sha256:  
```
root@test-vm:~# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```

#### 3. Работа со снапшотами
```
root@test-vm:~# wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
```

Восстановим файл:  
```
root@test-vm:~# zfs receive otus/test@today < otus_task2.file
```

Найдем сообщение и прочитаем:  
```
root@test-vm:~# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message

root@test-vm:~# cat /otus/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/
```