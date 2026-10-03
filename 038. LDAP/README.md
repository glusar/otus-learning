### LDAP. Централизованная авторизация и аутентификация 
### Задание
1. Установить FreeIPA
2. Написать Ansible-playbook для конфигурации клиента

### Выполнение
Настройка сервера:  
```
rasul@EniacLin:~/my_projects/vagrant_ldap$ vagrant up
rasul@EniacLin:~/my_projects/vagrant_ldap$ vagrant ssh ipa.otus.lan    
[vagrant@ipa ~]$ sudo -i  
[root@ipa ~]# timedatectl set-timezone Europe/Moscow  
[root@ipa ~]# setenforce 0  
[root@ipa ~]# vi /etc/hosts  
[root@ipa ~]# yum install -y ipa-server
[root@ipa ~]# ipa-server-install
Do you want to configure integrated DNS (BIND)? [no]: no
Server host name [ipa.otus.lan]:
Please confirm the domain name [otus.lan]:
Please provide a realm name [OTUS.LAN]:
Directory Manager password:
Password (confirm):
IPA admin password:
Password (confirm):
NetBIOS domain name [OTUS]:
Do you want to configure chrony with NTP server or pool address? [no]: no
The IPA Master Server will be configured with:
Hostname:       ipa.otus.lan
IP address(es): 192.168.57.10
Domain name:    otus.lan
Realm name:     OTUS.LAN

The CA will be configured with:
Subject DN:   CN=Certificate Authority,O=OTUS.LAN
Subject base: O=OTUS.LAN
Chaining:     self-signed

Continue to configure the system with these values? [no]: yes
```

Настройка клиента выполняется запуском плейбука:  
```
ansible-playbook ansible/provision.yml -i ./ansible/hosts
```

Для примера был создан пользователь в веб-панели FreeIPA и совершен вход:  
```
(ansible) rasul@EniacLin:~/my_projects/vagrant_ldap$ ssh -o IdentitiesOnly=yes -o PreferredAuthentications=password -o PubkeyAuthentication=no rasul@192.168.57.11  
** WARNING: connection is not using a post-quantum key exchange algorithm.  
** This session may be vulnerable to "store now, decrypt later" attacks.  
** The server may need to be upgraded. See https://openssh.com/pq.html  
rasul@192.168.57.11's password:    
Password expired. Change your password now.  
Password expired. Change your password now.  
WARNING: Your password has expired.  
You must change your password now and login again!  
Changing password for user rasul.  
Current Password:    
New password:    
Retype new password:    
passwd: all authentication tokens updated successfully.  
Connection to 192.168.57.11 closed.  
(ansible) rasul@EniacLin:~/my_projects/vagrant_ldap$ ssh -o IdentitiesOnly=yes -o PreferredAuthentications=password -o PubkeyAuthentication=no rasul@192.168.57.11  
** WARNING: connection is not using a post-quantum key exchange algorithm.  
** This session may be vulnerable to "store now, decrypt later" attacks.  
** The server may need to be upgraded. See https://openssh.com/pq.html  
rasul@192.168.57.11's password:    
Last login: Sun Oct  4 00:51:24 2026 from 192.168.57.1  
[rasul@client1 ~]$ sudo -i  
  
We trust you have received the usual lecture from the local System  
Administrator. It usually boils down to these three things:  
  
   #1) Respect the privacy of others.  
   #2) Think before you type.  
   #3) With great power comes great responsibility.  
  
For security reasons, the password you type will not be visible.  
  
[sudo] password for rasul:    
rasul is not allowed to run sudo on client1.  
[rasul@client1 ~]$ cat /etc/hosts  
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4  
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6  
192.168.57.10 ipa.otus.lan ipa  
[rasul@client1 ~]$ id  
uid=644400004(rasul) gid=644400004(rasul) groups=644400004(rasul)  
[rasul@client1 ~]$
```
