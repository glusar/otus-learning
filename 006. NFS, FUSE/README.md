### Работа с NFS
#### Задание
1. Запустить 2 виртуальных машины (сервер NFS и клиента);
2. На сервере NFS должна быть подготовлена и экспортирована директория;
3. В экспортированной директории должна быть поддиректория с именем upload с правами на запись в неё;
4. Экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab — любым способом);
5. Монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3.

#### Выполнение
Сервер NFS - test-vm - 192.168.1.112
Клиент NFS - test-vm2 - 192.168.1.116

Выполняем настройку сервера:
```
root@test-vm:~# apt install nfs-kernel-server

root@test-vm:~# ss -tulpn | grep -E "2049|111"
udp   UNCONN 0      0                  0.0.0.0:111        0.0.0.0:*    users:(("rpcbind",pid=1958,fd=5),("systemd",pid=1,fd=167))
udp   UNCONN 0      0                     [::]:111           [::]:*    users:(("rpcbind",pid=1958,fd=7),("systemd",pid=1,fd=178))
tcp   LISTEN 0      4096               0.0.0.0:111        0.0.0.0:*    users:(("rpcbind",pid=1958,fd=4),("systemd",pid=1,fd=166))
tcp   LISTEN 0      64                 0.0.0.0:2049       0.0.0.0:*                                                              
tcp   LISTEN 0      4096                  [::]:111           [::]:*    users:(("rpcbind",pid=1958,fd=6),("systemd",pid=1,fd=177))
tcp   LISTEN 0      64                    [::]:2049          [::]:*                                                              

root@test-vm:~# mkdir -p /srv/share/upload

root@test-vm:~# chown -R nobody:nogroup /srv/share

root@test-vm:~# chmod 0777 /srv/share/upload

root@test-vm:~# cat << EOF > /etc/exports 
/srv/share 192.168.1.116/32(rw,sync,root_squash)
EOF

root@test-vm:~# exportfs -r
exportfs: /etc/exports [1]: Neither 'subtree_check' or 'no_subtree_check' specified for export "192.168.1.116/32:/srv/share".
  Assuming default behaviour ('no_subtree_check').
  NOTE: this default has changed since nfs-utils version 1.0.x

root@test-vm:~# exportfs -s
/srv/share  192.168.1.116/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

Выполняем настройку клиента:
```
root@test-vm2:~# apt install nfs-common

root@test-vm2:~# echo "192.168.1.112:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab

root@test-vm2:~# systemctl daemon-reload 

root@test-vm2:~# systemctl restart remote-fs.target

root@test-vm2:/mnt# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=75,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=15837)
192.168.1.112:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.1.112,mountvers=3,mountport=42913,mountproto=udp,local_lock=none,addr=192.168.1.112)
```

Проверяем работу:
```
root@test-vm:/srv/share/upload# touch test_file

root@test-vm2:/mnt/upload# ls -la
total 8
drwxrwxrwx 2 nobody nogroup 4096 Apr 25 10:03 .
drwxr-xr-x 3 nobody nogroup 4096 Apr 25 09:46 ..
-rw-r--r-- 1 root   root       0 Apr 25 10:03 test_file

root@test-vm2:/mnt/upload# touch test_client_file

root@test-vm:/srv/share/upload# ls -la
total 8
drwxrwxrwx 2 nobody nogroup 4096 Apr 25 10:04 .
drwxr-xr-x 3 nobody nogroup 4096 Apr 25 09:46 ..
-rw-r--r-- 1 nobody nogroup    0 Apr 25 10:04 test_client_file
-rw-r--r-- 1 root   root       0 Apr 25 10:03 test_file
```
