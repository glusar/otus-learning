### Vagrant

### Задание
1. Подготовка окружения:
	- Убедитесь, что установлен VirtualBox и Vagrant.
	- Создайте директорию для проекта.
2. Создать базовую виртуальную машину:
    - Использовать можно любой образ.
    - Настроите память ВМ: 1024 МБ.
3. Добавление дисков:
    - Добавьте пару виртуальных диска размером 1 ГБ каждый.
4. Настройка сети:
    - Настройте проброс 80 порта с гостевой системы на порт 8080 хостовой системы.
5. Провижининг:
	 Напишите провижининг, который:
	- Форматирует добавленные диски в файловую систему ext4.
	- Создает точки монтирования /mnt/disk1 и /mnt/disk2.
	- Монтирует диски в указанные директории.
	- Добавляет записи в /etc/fstab для автоматического монтирования при загрузке.
### Результат
Vagrantfile находится в текущей директории  

Проверка дисков и портов:  
```bash
vagrant@vagrant-test:~$ df -h
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                               97M  964K   96M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv   31G  4.5G   25G  16% /
tmpfs                              481M     0  481M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          2.0G  103M  1.7G   6% /boot
vagrant                            228G  122G  107G  54% /vagrant
/dev/sdb                           974M   24K  907M   1% /mnt/disk1
/dev/sdc                           974M   24K  907M   1% /mnt/disk2
tmpfs                               97M   16K   97M   1% /run/user/1000
vagrant@vagrant-test:~$ ss -tulpn | grep 80
tcp   LISTEN 0      511           0.0.0.0:80        0.0.0.0:*          
tcp   LISTEN 0      511              [::]:80           [::]:*          
vagrant@vagrant-test:~$ 
logout
rasul@EniacLin:~/my_projects/vagrant$ ss -tulpn | grep 80
udp   UNCONN 212480 0            0.0.0.0:5353       0.0.0.0:*    users:(("kdeconnectd",pid=2226,fd=40))
udp   UNCONN 212480 0                  *:5353             *:*    users:(("kdeconnectd",pid=2226,fd=41))
tcp   LISTEN 0      10           0.0.0.0:8080       0.0.0.0:*                                          
tcp   LISTEN 0      511                *:80               *:*                                          
rasul@EniacLin:~/my_projects/vagrant$ 
```

Проверка проброса портов:  
![](../_attachments/test_vagrant_nginx.png)