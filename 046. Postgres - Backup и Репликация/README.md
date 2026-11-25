### Postgres: Backup + Репликация 
### Задание

- настроить hot_standby репликацию с использованием слотов
- настроить правильное резервное копирование

Требования:  
- Vagrantfile, который будет разворачивать виртуальные машины
- Плейбук Ansible
- Конфигурационные файлы postgresql.conf, pg_hba.conf и recovery.conf,
- Конфиг barman, либо скрипт резервного копирования.

### Результат
Для развертывания стенда нужно выполнить:  
```
vagrant up
```

#### Проверка репликации  
node1:
```
postgres=# \l  
                                 List of databases  
  Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges      
-----------+----------+----------+-------------+-------------+-----------------------  
otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
(4 rows)  
  
postgres=# CREATE DATABASE my_test;  
CREATE DATABASE  
postgres=# \l  
                                 List of databases  
  Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges      
-----------+----------+----------+-------------+-------------+-----------------------  
my_test   | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
(5 rows)
```

node2:
```
postgres=# \l  
                                 List of databases  
  Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges      
-----------+----------+----------+-------------+-------------+-----------------------  
otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
(4 rows)  
  
postgres=# \l  
                                 List of databases  
  Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges      
-----------+----------+----------+-------------+-------------+-----------------------  
my_test   | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
(5 rows)
```


#### Проверка barman
```
root@barman:~# psql -h 192.168.57.11 -U barman -d postgres  
Password for user barman:    
psql (14.24 (Ubuntu 14.24-0ubuntu0.22.04.1))  
Type "help" for help.  
  
postgres=#    
\q  
root@barman:~# psql -h 192.168.57.11 -U barman -c "IDENTIFY_SYSTEM" replication=1  
Password for user barman:    
     systemid       | timeline |  xlogpos  | dbname    
---------------------+----------+-----------+--------  
7711998627006054580 |        1 | 0/4000CD8 |    
(1 row)  
  
root@barman:~# barman switch-wal node1  
The WAL file 000000010000000000000004 has been closed on server 'node1'  
root@barman:~# barman cron  
Starting WAL archiving for server node1  
root@barman:~# barman check node1  
Server node1:  
       PostgreSQL: OK  
       superuser or standard user with backup privileges: OK  
       PostgreSQL streaming: OK  
       wal_level: OK  
       replication slot: OK  
       directories: OK  
       retention policy settings: OK  
       backup maximum age: FAILED (interval provided: 4 days, latest backup age: No available backups)  
       backup minimum size: OK (0 B)  
       wal maximum age: OK (no last_wal_maximum_age provided)  
       wal size: OK (0 B)  
       compression settings: OK  
       failed backups: OK (there are 0 failed backups)  
       minimum redundancy requirements: FAILED (have 0 backups, expected at least 1)  
       pg_basebackup: OK  
       pg_basebackup compatible: OK  
       pg_basebackup supports tablespaces mapping: OK  
       systemid coherence: OK (no system Id stored on disk)  
       pg_receivexlog: OK  
       pg_receivexlog compatible: OK  
       receive-wal running: OK  
       archiver errors: OK  
root@barman:~# barman backup node1  
Starting backup using postgres method for server node1 in /var/lib/barman/node1/base/20261125T205848  
Backup start at LSN: 0/5000060 (000000010000000000000005, 00000060)  
Starting backup copy via pg_basebackup for 20261125T205848  
WARNING: pg_basebackup does not copy the PostgreSQL configuration files that reside outside PGDATA. Please manually  
backup the following files:  
       /etc/postgresql/14/main/postgresql.conf  
       /etc/postgresql/14/main/pg_hba.conf  
       /etc/postgresql/14/main/pg_ident.conf  
  
Copy done (time: 1 second)  
Finalising the backup.  
This is the first backup for server node1  
WAL segments preceding the current backup have been found:  
       000000010000000000000004 from server node1 has been removed  
Backup size: 41.8 MiB  
Backup end at LSN: 0/7000000 (000000010000000000000006, 00000000)  
Backup completed (start time: 2026-11-25 20:58:48.988001, elapsed time: 1 second)  
Processing xlog segments from streaming for node1  
       000000010000000000000005  
       000000010000000000000006
```

#### Проверка восстановления
node1:  
```
postgres=# \l  
                                 List of databases  
  Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges      
-----------+----------+----------+-------------+-------------+-----------------------  
my_test   | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
(5 rows)  
  
postgres=# DROP DATABASE otus;  
DROP DATABASE  
postgres=# DROP DATABASE my_test;  
DROP DATABASE  
postgres=# \l  
                                 List of databases  
  Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges      
-----------+----------+----------+-------------+-------------+-----------------------  
postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
(3 rows)
```

barman:  
```
root@barman:~# barman list-backup node1  
node1 20261125T205848 - Wed Nov 25 17:58:50 2026 - Size: 41.8 MiB - WAL Size: 0 B  
root@barman:~# barman recover node1 20261125T205848 /var/lib/postgresql/14/main/ --remote-ssh-comman "ssh postgres@  
192.168.57.11"  
The authenticity of host '192.168.57.11 (192.168.57.11)' can't be established.  
ED25519 key fingerprint is SHA256:CifvuKnCFUxaTaHjJPvXJRQcfQVeROGRu5rhIY1FQYs.  
This key is not known by any other names  
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes  
Starting remote restore for server node1 using backup 20261125T205848  
Destination directory: /var/lib/postgresql/14/main/  
Remote command: ssh postgres@192.168.57.11  
Copying the base backup.  
Copying required WAL segments.  
Generating archive status files  
Identify dangerous settings in destination directory.  
  
WARNING  
The following configuration files have not been saved during backup, hence they have not been restored.  
You need to manually restore them in order to start the recovered PostgreSQL instance:  
  
   postgresql.conf  
   pg_hba.conf  
   pg_ident.conf  
  
Recovery completed (start time: 2026-11-25 21:11:29.790083, elapsed time: 6 seconds)  
  
Your PostgreSQL server has been successfully prepared for recovery!
```

node1:
```
postgres=#    
\q  
root@node1:~# systemctl restart postgresql  
root@node1:~# sudo -u postgres psql  
could not change directory to "/root": Permission denied  
psql (14.24 (Ubuntu 14.24-0ubuntu0.22.04.1))  
Type "help" for help.  
  
postgres=# \l  
                                 List of databases  
  Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges      
-----------+----------+----------+-------------+-------------+-----------------------  
my_test   | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
otus      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |    
template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +  
          |          |          |             |             | postgres=CTc/postgres  
(5 rows)
```