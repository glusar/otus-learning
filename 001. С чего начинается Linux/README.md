### Обновление ядра системы
#### Задание
1. Запустить ВМ c Ubuntu.
2. Обновить ядро ОС на новейшую стабильную версию из mainline-репозитория.
3. Оформить отчет в README-файле в GitHub-репозитории.
#### Основные команды и вывод
```bash
lusar@test-vm:~$ uname -r
6.8.0-107-generic

lusar@test-vm:~$ mkdir kernel && cd kernel

lusar@test-vm:~/kernel$ wget https://kernel.ubuntu.com/mainline/v6.19.10/amd64/linux-headers-6.19.10-061910-generic_6.19.10-061910.202603251147_amd64.deb

lusar@test-vm:~/kernel$ wget https://kernel.ubuntu.com/mainline/v6.19.10/amd64/linux-headers-6.19.10-061910_6.19.10-061910.202603251147_all.deb

lusar@test-vm:~/kernel$ wget https://kernel.ubuntu.com/mainline/v6.19.10/amd64/linux-image-unsigned-6.19.10-061910-generic_6.19.10-061910.202603251147_amd64.deb

lusar@test-vm:~/kernel$ wget https://kernel.ubuntu.com/mainline/v6.19.10/amd64/linux-modules-6.19.10-061910-generic_6.19.10-061910.202603251147_amd64.deb

lusar@test-vm:~/kernel$ sudo dpkg -i *.deb

lusar@test-vm:~/kernel$ ls -al /boot
total 301248
drwxr-xr-x  4 root root     4096 Apr  4 16:36 .
drwxr-xr-x 23 root root     4096 Jan  6 13:17 ..
-rw-------  1 root root 10815061 Mar 25 11:47 System.map-6.19.10-061910-generic
-rw-------  1 root root  9125925 Mar 13 13:27 System.map-6.8.0-107-generic
-rw-------  1 root root  9114947 Nov 18 11:26 System.map-6.8.0-90-generic
-rw-r--r--  1 root root   306720 Mar 25 11:47 config-6.19.10-061910-generic
-rw-r--r--  1 root root   287601 Mar 13 13:27 config-6.8.0-107-generic
-rw-r--r--  1 root root   287416 Nov 18 11:26 config-6.8.0-90-generic
drwxr-xr-x  5 root root     4096 Apr  4 16:37 grub
lrwxrwxrwx  1 root root       33 Apr  4 16:36 initrd.img -> initrd.img-6.19.10-061910-generic
-rw-r--r--  1 root root 80518163 Apr  4 16:36 initrd.img-6.19.10-061910-generic
-rw-r--r--  1 root root 76340035 Apr  4 16:25 initrd.img-6.8.0-107-generic
-rw-r--r--  1 root root 74600179 Jan  6 11:47 initrd.img-6.8.0-90-generic
lrwxrwxrwx  1 root root       28 Apr  4 16:36 initrd.img.old -> initrd.img-6.8.0-107-generic
drwx------  2 root root    16384 Feb  8  2025 lost+found
lrwxrwxrwx  1 root root       30 Apr  4 16:36 vmlinuz -> vmlinuz-6.19.10-061910-generic
-rw-------  1 root root 16978432 Mar 25 11:47 vmlinuz-6.19.10-061910-generic
-rw-------  1 root root 15042952 Mar 13 17:46 vmlinuz-6.8.0-107-generic
-rw-------  1 root root 15006088 Nov 18 11:46 vmlinuz-6.8.0-90-generic
lrwxrwxrwx  1 root root       25 Apr  4 16:36 vmlinuz.old -> vmlinuz-6.8.0-107-generic

lusar@test-vm:~/kernel$ sudo vim /etc/default/grub
```

**Заметка:** файле `/etc/default/grub` меняем настройки на следующие:
```bash
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=3
```

```bash
lusar@test-vm:~/kernel$ sudo update-grub
lusar@test-vm:~/kernel$ sudo grub-set-default 0
lusar@test-vm:~/kernel$ sudo reboot now
lusar@test-vm:~$ uname -r
6.19.10-061910-generic
```
