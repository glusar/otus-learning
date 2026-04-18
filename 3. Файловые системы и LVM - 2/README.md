### Задание
1. Уменьшить том под / до 8G.
2. Выделить том под /var - сделать в mirror.
3. Выделить том под /home.
4. /home - сделать том для снапшотов.
5. Прописать монтирование в fstab. Попробовать с разными опциями и разными файловыми системами (на выбор).
6. Работа со снапшотами:
	- сгенерить файлы в /home/;
	- снять снапшот;
	- удалить часть файлов;
	- восстановиться со снапшота.
### Уменьшить том под / до 8G

```
root@test-vm:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   20G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 18.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0 18.2G  0 lvm  /
sdb                         8:16   0   10G  0 disk
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    2G  0 disk
sde                         8:64   0    2G  0 disk

root@test-vm:~# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.

root@test-vm:~# vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created

root@test-vm:~# lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.

root@test-vm:~# mkfs.ext4 /dev/vg_root/lv_root
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done
Creating filesystem with 2620416 4k blocks and 655360 inodes
Filesystem UUID: ad1bcdff-4beb-4c83-a436-6498e248979e
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

root@test-vm:~# mount /dev/vg_root/lv_root /mnt

root@test-vm:~# rsync -avxHAX --progress / /mnt

root@test-vm:~# ls /mnt
bin                boot   dev  home  lib.usr-is-merged  lost+found  mnt  proc  run   sbin.usr-is-merged  srv       sys  usr
bin.usr-is-merged  cdrom  etc  lib   lib64              media       opt  root  sbin  snap                swap.img  tmp  var

root@test-vm:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   20G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 18.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0 18.2G  0 lvm  /
sdb                         8:16   0   10G  0 disk
└─vg_root-lv_root         252:1    0   10G  0 lvm  /mnt
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    2G  0 disk
sde                         8:64   0    2G  0 disk

root@test-vm:~# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done

root@test-vm:~# chroot /mnt

root@test-vm:/# grub-mkconfig -o /boot/grub/grub.cfg
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.8.0-110-generic
Found initrd image: /boot/initrd.img-6.8.0-110-generic
Found linux image: /boot/vmlinuz-6.8.0-107-generic
Found initrd image: /boot/initrd.img-6.8.0-107-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done

root@test-vm:/# update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.8.0-110-generic

root@test-vm:/# exit

root@test-vm:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   20G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /mnt/boot
│                                                  /boot
└─sda3                      8:3    0 18.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0 18.2G  0 lvm  /
sdb                         8:16   0   10G  0 disk
└─vg_root-lv_root         252:1    0   10G  0 lvm  /mnt
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    2G  0 disk
sde                         8:64   0    2G  0 disk
root@test-vm:/# exit
root@test-vm:~# reboot


root@test-vm:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   20G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 18.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0 18.2G  0 lvm
sdb                         8:16   0   10G  0 disk
└─vg_root-lv_root         252:1    0   10G  0 lvm  /
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    2G  0 disk
sde                         8:64   0    2G  0 disk

root@test-vm:~# lvremove /dev/ubuntu-vg/ubuntu-lv
Do you really want to remove and DISCARD active logical volume ubuntu-vg/ubuntu-lv? [y/n]: y
  Logical volume "ubuntu-lv" successfully removed.

root@test-vm:~# lvcreate -n ubuntu-vg/ubuntu-lv -L 8G /dev/ubuntu-vg
  Logical volume "ubuntu-lv" created.

root@test-vm:~# mkfs.ext4 /dev/ubuntu-vg/ubuntu-lv
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done
Creating filesystem with 2097152 4k blocks and 524288 inodes
Filesystem UUID: 43699ef8-8416-4f14-9381-069832138296
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

root@test-vm:~# mount /dev/ubuntu-vg/ubuntu-lv /mnt

root@test-vm:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   20G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 18.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0    8G  0 lvm  /mnt
sdb                         8:16   0   10G  0 disk
└─vg_root-lv_root         252:1    0   10G  0 lvm  /
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    2G  0 disk
sde                         8:64   0    2G  0 disk

root@test-vm:~# rsync -avxHAX --progress / /mnt/

root@test-vm:~# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done

root@test-vm:~# chroot /mnt/

root@test-vm:/# grub-mkconfig -o /boot/grub/grub.cfg
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.8.0-110-generic
Found initrd image: /boot/initrd.img-6.8.0-110-generic
Found linux image: /boot/vmlinuz-6.8.0-107-generic
Found initrd image: /boot/initrd.img-6.8.0-107-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done

root@test-vm:/# update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.8.0-110-generic
W: Couldn't identify type of root file system for fsck hook

```

### Выделить том под /var - сделать в mirror
```
root@test-vm:/# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   20G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 18.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0    8G  0 lvm  /
sdb                         8:16   0   10G  0 disk
└─vg_root-lv_root         252:1    0   10G  0 lvm
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    2G  0 disk
sde                         8:64   0    2G  0 disk

root@test-vm:/# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.

root@test-vm:/# vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created

root@test-vm:/# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.

root@test-vm:/# mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done
Creating filesystem with 243712 4k blocks and 60928 inodes
Filesystem UUID: 960d3fda-bc47-4383-9272-c0db5d23d331
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

root@test-vm:/# mount /dev/vg_var/lv_var /mnt

root@test-vm:/# cp -aR /var/* /mnt/

root@test-vm:/# mkdir /tmp/oldvar && mv /var/* /tmp/oldvar

root@test-vm:/# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   20G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 18.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0    8G  0 lvm  /
sdb                         8:16   0   10G  0 disk
└─vg_root-lv_root         252:1    0   10G  0 lvm
sdc                         8:32   0    2G  0 disk
├─vg_var-lv_var_rmeta_0   252:2    0    4M  0 lvm
│ └─vg_var-lv_var         252:6    0  1.8G  0 lvm  /mnt
└─vg_var-lv_var_rimage_0  252:3    0  1.8G  0 lvm
  └─vg_var-lv_var         252:6    0  1.8G  0 lvm  /mnt
sdd                         8:48   0    2G  0 disk
├─vg_var-lv_var_rmeta_1   252:4    0    4M  0 lvm
│ └─vg_var-lv_var         252:6    0  1.8G  0 lvm  /mnt
└─vg_var-lv_var_rimage_1  252:5    0  1.8G  0 lvm
  └─vg_var-lv_var         252:6    0  1.8G  0 lvm  /mnt
sde                         8:64   0    2G  0 disk

root@test-vm:/# umount /mnt

root@test-vm:/# mount /dev/vg_var/lv_var /var

root@test-vm:/# echo "`blkid | grep var: | awk '{print $2}'` \
 /var ext4 defaults 0 0" >> /etc/fstab

 root@test-vm:~# reboot


root@test-vm:~# lvremove /dev/vg_root/lv_root
Do you really want to remove and DISCARD active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed.
root@test-vm:~# vgremove /dev/vg_root
  Volume group "vg_root" successfully removed
root@test-vm:~# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.

root@test-vm:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   20G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 18.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:1    0    8G  0 lvm  /
sdb                         8:16   0   10G  0 disk
sdc                         8:32   0    2G  0 disk
├─vg_var-lv_var_rmeta_0   252:2    0    4M  0 lvm
│ └─vg_var-lv_var         252:6    0  1.8G  0 lvm  /var
└─vg_var-lv_var_rimage_0  252:3    0  1.8G  0 lvm
  └─vg_var-lv_var         252:6    0  1.8G  0 lvm  /var
sdd                         8:48   0    2G  0 disk
├─vg_var-lv_var_rmeta_1   252:4    0    4M  0 lvm
│ └─vg_var-lv_var         252:6    0  1.8G  0 lvm  /var
└─vg_var-lv_var_rimage_1  252:5    0  1.8G  0 lvm
  └─vg_var-lv_var         252:6    0  1.8G  0 lvm  /var
sde                         8:64   0    2G  0 disk
```
### Выделить том под /home
```
root@test-vm:~# lvcreate -n LogVol_Home -L 2G /dev/ubuntu-vg
  Logical volume "LogVol_Home" created.

root@test-vm:~# mkfs.ext4 /dev/ubuntu-vg/LogVol_Home 
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done                            
Creating filesystem with 524288 4k blocks and 131072 inodes
Filesystem UUID: bff339f2-a754-4951-887b-2418c042cde7
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 

root@test-vm:~# mount /dev/ubuntu-vg/LogVol_Home /mnt/

root@test-vm:~# cp -aR /home/* /mnt/

root@test-vm:~# rm -rf /home/*

root@test-vm:~# umount /mnt

root@test-vm:~# mount /dev/ubuntu-vg/LogVol_Home /home/

root@test-vm:~# echo "`blkid | grep Home | awk '{print $2}'` \
 /home ext4 defaults 0 0" >> /etc/fstab
```
### /home - сделать том для снапшотов
Снапшот создан в [[#Работа со снапшотами]]  
### Прописать монтирование в fstab. Попробовать с разными опциями и разными файловыми системами (на выбор)
Создадим на свободном диске новый LV с ФС, а затем пропишем эту ФС в fstab:  
```
root@test-vm:~# mkdir -p /mnt/video

root@test-vm:~# vgcreate vg_video /dev/sdb
  Physical volume "/dev/sdb" successfully created.
  Volume group "vg_video" successfully created

root@test-vm:~# lvcreate -n vg_video/lv_video -l +85%FREE
  Logical volume "lv_video" created.

root@test-vm:~# vgs
  VG        #PV #LV #SN Attr   VSize   VFree  
  ubuntu-vg   1   2   0 wz--n- <18.25g  <8.25g
  vg_var      2   1   0 wz--n-   3.99g 432.00m
  vg_video    1   1   0 wz--n- <10.00g   1.50g

root@test-vm:~# lvs
  LV          VG        Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol_Home ubuntu-vg -wi-ao----  2.00g                                                    
  ubuntu-lv   ubuntu-vg -wi-ao----  8.00g                                                    
  lv_var      vg_var    rwi-aor---  1.78g                                    100.00          
  lv_video    vg_video  -wi-a----- <8.50g    
  
root@test-vm:~# mkfs.xfs /dev/vg_video/lv_video 
meta-data=/dev/vg_video/lv_video isize=512    agcount=4, agsize=556800 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=1
         =                       reflink=1    bigtime=1 inobtcount=1 nrext64=0
data     =                       bsize=4096   blocks=2227200, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=16384, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
Discarding blocks...Done.

root@test-vm:~# echo "`blkid | grep video: | awk '{print $2}'` /mnt/video xfs nofail 0 2" >> /etc/fstab

root@test-vm:~# df -hT
Filesystem                         Type   Size  Used Avail Use% Mounted on
tmpfs                              tmpfs  392M  1.1M  391M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  ext4   7.8G  4.4G  3.1G  60% /
tmpfs                              tmpfs  2.0G     0  2.0G   0% /dev/shm
tmpfs                              tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/mapper/ubuntu--vg-LogVol_Home ext4   2.0G   80K  1.8G   1% /home
/dev/mapper/vg_var-lv_var          ext4   1.8G  631M  1.1G  38% /var
/dev/mapper/vg_video-lv_video      xfs    8.5G  198M  8.3G   3% /mnt/video
/dev/sda2                          ext4   1.7G  200M  1.4G  13% /boot
tmpfs                              tmpfs  392M   12K  392M   1% /run/user/1000
```
### Работа со снапшотами
#### Сгенерить файлы в /home/
```
root@test-vm:~# touch /home/file{1..20}

root@test-vm:~# ls -la /home
total 28
drwxr-xr-x  4 root  root   4096 Apr 18 20:18 .
drwxr-xr-x 23 root  root   4096 Jan  6 13:17 ..
-rw-r--r--  1 root  root      0 Apr 18 20:18 file1
-rw-r--r--  1 root  root      0 Apr 18 20:18 file10
-rw-r--r--  1 root  root      0 Apr 18 20:18 file11
-rw-r--r--  1 root  root      0 Apr 18 20:18 file12
-rw-r--r--  1 root  root      0 Apr 18 20:18 file13
-rw-r--r--  1 root  root      0 Apr 18 20:18 file14
-rw-r--r--  1 root  root      0 Apr 18 20:18 file15
-rw-r--r--  1 root  root      0 Apr 18 20:18 file16
-rw-r--r--  1 root  root      0 Apr 18 20:18 file17
-rw-r--r--  1 root  root      0 Apr 18 20:18 file18
-rw-r--r--  1 root  root      0 Apr 18 20:18 file19
-rw-r--r--  1 root  root      0 Apr 18 20:18 file2
-rw-r--r--  1 root  root      0 Apr 18 20:18 file20
-rw-r--r--  1 root  root      0 Apr 18 20:18 file3
-rw-r--r--  1 root  root      0 Apr 18 20:18 file4
-rw-r--r--  1 root  root      0 Apr 18 20:18 file5
-rw-r--r--  1 root  root      0 Apr 18 20:18 file6
-rw-r--r--  1 root  root      0 Apr 18 20:18 file7
-rw-r--r--  1 root  root      0 Apr 18 20:18 file8
-rw-r--r--  1 root  root      0 Apr 18 20:18 file9
drwx------  2 root  root  16384 Apr 18 20:06 lost+found
drwxr-x---  6 lusar lusar  4096 Apr  4 16:18 lusar

```
#### Снять снапшот
```
root@test-vm:~# lvcreate -L 100M -s -n home_snap /dev/ubuntu-vg/LogVol_Home
  Logical volume "home_snap" created.
  
root@test-vm:~# lvs
  LV          VG        Attr       LSize   Pool Origin      Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol_Home ubuntu-vg owi-aos---   2.00g                                                         
  home_snap   ubuntu-vg swi-a-s--- 100.00m      LogVol_Home 0.01                                   
  ubuntu-lv   ubuntu-vg -wi-ao----   8.00g                                                         
  lv_var      vg_var    rwi-aor---   1.78g                                         100.00          

```
#### Удалить часть файлов
```
root@test-vm:~# rm -f /home/file{11..20}

root@test-vm:~# ls -la /home/
total 28
drwxr-xr-x  4 root  root   4096 Apr 18 20:21 .
drwxr-xr-x 23 root  root   4096 Jan  6 13:17 ..
-rw-r--r--  1 root  root      0 Apr 18 20:18 file1
-rw-r--r--  1 root  root      0 Apr 18 20:18 file10
-rw-r--r--  1 root  root      0 Apr 18 20:18 file2
-rw-r--r--  1 root  root      0 Apr 18 20:18 file3
-rw-r--r--  1 root  root      0 Apr 18 20:18 file4
-rw-r--r--  1 root  root      0 Apr 18 20:18 file5
-rw-r--r--  1 root  root      0 Apr 18 20:18 file6
-rw-r--r--  1 root  root      0 Apr 18 20:18 file7
-rw-r--r--  1 root  root      0 Apr 18 20:18 file8
-rw-r--r--  1 root  root      0 Apr 18 20:18 file9
drwx------  2 root  root  16384 Apr 18 20:06 lost+found
drwxr-x---  6 lusar lusar  4096 Apr  4 16:18 lusar

```
#### Восстановиться со снапшота
```
root@test-vm:~# umount /home

root@test-vm:~# lvconvert --merge /dev/ubuntu-vg/home_snap 
  Merging of volume ubuntu-vg/home_snap started.
  ubuntu-vg/LogVol_Home: Merged: 100.00%

root@test-vm:~# mount /dev/ubuntu-vg/LogVol_Home /home
mount: (hint) your fstab has been modified, but systemd still uses
       the old version; use 'systemctl daemon-reload' to reload.

root@test-vm:~# ls -la /home
total 28
drwxr-xr-x  4 root  root   4096 Apr 18 20:18 .
drwxr-xr-x 23 root  root   4096 Jan  6 13:17 ..
-rw-r--r--  1 root  root      0 Apr 18 20:18 file1
-rw-r--r--  1 root  root      0 Apr 18 20:18 file10
-rw-r--r--  1 root  root      0 Apr 18 20:18 file11
-rw-r--r--  1 root  root      0 Apr 18 20:18 file12
-rw-r--r--  1 root  root      0 Apr 18 20:18 file13
-rw-r--r--  1 root  root      0 Apr 18 20:18 file14
-rw-r--r--  1 root  root      0 Apr 18 20:18 file15
-rw-r--r--  1 root  root      0 Apr 18 20:18 file16
-rw-r--r--  1 root  root      0 Apr 18 20:18 file17
-rw-r--r--  1 root  root      0 Apr 18 20:18 file18
-rw-r--r--  1 root  root      0 Apr 18 20:18 file19
-rw-r--r--  1 root  root      0 Apr 18 20:18 file2
-rw-r--r--  1 root  root      0 Apr 18 20:18 file20
-rw-r--r--  1 root  root      0 Apr 18 20:18 file3
-rw-r--r--  1 root  root      0 Apr 18 20:18 file4
-rw-r--r--  1 root  root      0 Apr 18 20:18 file5
-rw-r--r--  1 root  root      0 Apr 18 20:18 file6
-rw-r--r--  1 root  root      0 Apr 18 20:18 file7
-rw-r--r--  1 root  root      0 Apr 18 20:18 file8
-rw-r--r--  1 root  root      0 Apr 18 20:18 file9
drwx------  2 root  root  16384 Apr 18 20:06 lost+found
drwxr-x---  6 lusar lusar  4096 Apr  4 16:18 lusar

```