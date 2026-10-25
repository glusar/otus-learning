### MySQL: Backup + Репликация 
### Задание
Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы:

```
| bookmaker          |
| competition        |
 market              |
| odds               |
| outcome
```

Требования:  
- Настроить GTID репликацию
- Рабочий Vagrantfile
- Скрины или логи SHOW TABLES
- Конфиги - пример в логе изменения строки и появления строки на реплике

### Результат
Машины поднимаются командой `vagrant up`  
 
#### Шаги на master
```
root@master:~# sudo apt update  
sudo apt install -y curl  
curl -O https://repo.percona.com/apt/percona-release_latest.generic_all.deb  
sudo apt install -y gnupg2 lsb-release ./percona-release_latest.generic_all.deb  
sudo percona-release enable-only ps-97-lts release --scheme https  
sudo apt update  
sudo apt install -y percona-server-server
...
root@master:~# cp /vagrant/conf/conf.d/* /etc/mysql/mysql.conf.d/  
root@master:~# systemctl start mysql  
root@master:~# mysql --no-defaults --protocol=SOCKET -u root -p  
Enter password:    
Welcome to the MySQL monitor.  Commands end with ; or \g.  
Your MySQL connection id is 10  
Server version: 9.7.2-2 Percona Server (GPL), Release '2', Revision '91438a04'  
  
Copyright (c) 2009-2026 Percona LLC and/or its affiliates  
Copyright (c) 2000, 2026, Oracle and/or its affiliates.  
  
Oracle is a registered trademark of Oracle Corporation and/or its  
affiliates. Other names may be trademarks of their respective  
owners.  
  
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.  
  
mysql> SELECT @@server_id;  
+-------------+  
| @@server_id |  
+-------------+  
|           1 |  
+-------------+  
1 row in set (0.001 sec)  
  
mysql> SHOW VARIABLES LIKE 'gtid_mode';  
+---------------+-------+  
| Variable_name | Value |  
+---------------+-------+  
| gtid_mode     | ON    |  
+---------------+-------+  
1 row in set (0.032 sec)  
  
mysql> CREATE DATABASE bet;  
Query OK, 1 row affected (0.029 sec)  
  
mysql> exit  
Bye  
root@master:~# mysql --no-defaults --protocol=SOCKET -u root -p -D bet < /vagrant/bet-224190-percona-9.7.2.sql  
Enter password:    
root@master:~# mysql --no-defaults --protocol=SOCKET -u root -p  
Enter password:    
Welcome to the MySQL monitor.  Commands end with ; or \g.  
Your MySQL connection id is 12  
Server version: 9.7.2-2 Percona Server (GPL), Release '2', Revision '91438a04'  
  
Copyright (c) 2009-2026 Percona LLC and/or its affiliates  
Copyright (c) 2000, 2026, Oracle and/or its affiliates.  
  
Oracle is a registered trademark of Oracle Corporation and/or its  
affiliates. Other names may be trademarks of their respective  
owners.  
  
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.  
  
mysql> USE bet;  
Reading table information for completion of table and column names  
You can turn off this feature to get a quicker startup with -A  
  
Database changed  
mysql> SHOW TABLES;  
+------------------+  
| Tables_in_bet    |  
+------------------+  
| bookmaker        |  
| competition      |  
| events_on_demand |  
| market           |  
| odds             |  
| outcome          |  
| v_same_event     |  
+------------------+  
7 rows in set (0.005 sec)  
  
mysql> CREATE USER 'repl'@'%' IDENTIFIED BY '!OtusLinux2018';  
Query OK, 0 rows affected (0.060 sec)  
  
mysql> SELECT user,host FROM mysql.user where user='repl';  
+------+------+  
| user | host |  
+------+------+  
| repl | %    |  
+------+------+  
1 row in set (0.001 sec)  
  
mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';  
Query OK, 0 rows affected (0.012 sec)  
  
mysql> exit  
Bye  
root@master:~# mysqldump --all-databases --triggers --routines --source-data --ignore-table=bet.events_on_demand --ignore-table=bet.v_same_event -u root -p > master.sql  
Enter password:    
Warning: A partial dump from a server that has GTIDs will by default include the GTIDs of all transactions, even those that changed suppressed parts of the database. If you don't want to restore GTIDs, pass --set-gtid-purged=OFF. To mak  
e a complete dump, pass --all-databases --triggers --routines --events.    
root@master:~# cp ./master.sql /vagrant/  
root@master:~# SELECT @@server_id;  
-bash: SELECT: command not found  
root@master:~# mysql -u root -p  
Enter password:    
Welcome to the MySQL monitor.  Commands end with ; or \g.  
Your MySQL connection id is 16  
Server version: 9.7.2-2 Percona Server (GPL), Release '2', Revision '91438a04'  
  
Copyright (c) 2009-2026 Percona LLC and/or its affiliates  
Copyright (c) 2000, 2026, Oracle and/or its affiliates.  
  
Oracle is a registered trademark of Oracle Corporation and/or its  
affiliates. Other names may be trademarks of their respective  
owners.  
  
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.  
  
mysql> USE bet;  
Reading table information for completion of table and column names  
You can turn off this feature to get a quicker startup with -A  
  
Database changed  
mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');  
Query OK, 1 row affected (0.008 sec)  
  
mysql> SELECT*FROM bookmaker;  
+----+----------------+  
| id | bookmaker_name |  
+----+----------------+  
|  1 | 1xbet          |  
|  4 | betway         |  
|  5 | bwin           |  
|  6 | ladbrokes      |  
|  3 | unibet         |  
+----+----------------+  
5 rows in set (0.001 sec)
```

##### Лог изменения на мастере
```
root@master:~# mysqlbinlog --base64-output=DECODE-ROWS -vv /var/lib/mysql/binlog.000002 | tail -n 20  
SET TIMESTAMP=1792948839/*!*/;  
BEGIN  
/*!*/;  
# at 93890  
#261025 17:20:39 server id 1  end_log_pos 93952 CRC32 0xadf6260d        Table_map: `bet`.`bookmaker` mapped to number 183  
# has_generated_invisible_primary_key=0  
# at 93952  
#261025 17:20:39 server id 1  end_log_pos 93999 CRC32 0x128b48c5        Write_rows: table id 183 flags: STMT_END_F USE_SQL_FOREIGN_KEY_F  
### INSERT INTO `bet`.`bookmaker`  
### SET  
###   @1=1 /* INT meta=0 nullable=0 is_null=0 */  
###   @2='1xbet' /* VARSTRING(1020) meta=1020 nullable=1 is_null=0 */  
# at 93999  
#261025 17:20:39 server id 1  end_log_pos 94030 CRC32 0x7d72187a        Xid = 776  
COMMIT/*!*/;  
SET @@SESSION.GTID_NEXT= 'AUTOMATIC' /* added by mysqlbinlog */ /*!*/;  
DELIMITER ;  
# End of log file  
/*!50003 SET COMPLETION_TYPE=@OLD_COMPLETION_TYPE*/;  
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=0*/;
```
#### Шаги на slave
```
root@slave:~# sudo apt update  
sudo apt install -y curl  
curl -O https://repo.percona.com/apt/percona-release_latest.generic_all.deb  
sudo apt install -y gnupg2 lsb-release ./percona-release_latest.generic_all.deb  
sudo percona-release enable-only ps-97-lts release --scheme https  
sudo apt update  
sudo apt install -y percona-server-server
...
root@slave:~# mysql -u root -p  
Enter password:    
Welcome to the MySQL monitor.  Commands end with ; or \g.  
Your MySQL connection id is 10  
Server version: 9.7.2-2 Percona Server (GPL), Release '2', Revision '91438a04'  
  
Copyright (c) 2009-2026 Percona LLC and/or its affiliates  
Copyright (c) 2000, 2026, Oracle and/or its affiliates.  
  
Oracle is a registered trademark of Oracle Corporation and/or its  
affiliates. Other names may be trademarks of their respective  
owners.  
  
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.  
  
mysql> SELECT @@server_id;  
+-------------+  
| @@server_id |  
+-------------+  
|           1 |  
+-------------+  
1 row in set (0.000 sec)  
  
mysql> exit  
Bye  
root@slave:~# vim /etc/mysql/mysql.conf.d/01-base.cnf  
root@slave:~# cp /vagrant/conf/conf.d/* /etc/mysql/mysql.conf.d/  
root@slave:~# vim /etc/mysql/mysql.conf.d/01-base.cnf  
root@slave:~# vim /etc/mysql/mysql.conf.d/01-base.cnf  
root@slave:~# vim /etc/mysql/mysql.conf.d/05-binlog.cnf  
root@slave:~# cat /etc/mysql/mysql.conf.d/01-base.cnf  
[mysqld]  
pid-file=/var/run/mysqld/mysqld.pid  
log-error=/var/log/mysqld.log  
datadir=/var/lib/mysql  
socket=/var/lib/mysql/mysql.sock  
symbolic-links=0  
  
server-id = 2    
innodb_file_per_table = 1  
skip-name-resolve  
root@slave:~# cat /etc/mysql/mysql.conf.d/05-binlog.cnf    
[mysqld]  
log-bin = mysql-bin  
expire-logs-days = 7  
max-binlog-size = 16M  
binlog-format = "MIXED"  
  
# GTID replication config  
log-slave-updates = On  
gtid-mode = On  
enforce-gtid-consistency = On  
  
# Эта часть только для слэйва - исключаем репликацию таблиц  
replicate-ignore-table=bet.events_on_demand  
replicate-ignore-table=bet.v_same_event  
root@slave:~# cp /vagrant/master.sql ./  
root@slave:~# mysql -u root -p  
Enter password:    
Welcome to the MySQL monitor.  Commands end with ; or \g.  
Your MySQL connection id is 11  
Server version: 9.7.2-2 Percona Server (GPL), Release '2', Revision '91438a04'  
  
Copyright (c) 2009-2026 Percona LLC and/or its affiliates  
Copyright (c) 2000, 2026, Oracle and/or its affiliates.  
  
Oracle is a registered trademark of Oracle Corporation and/or its  
affiliates. Other names may be trademarks of their respective  
owners.  
  
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.  
  
mysql> SOURCE /vagrant/master.sql  
Query OK, 0 rows affected (0.000 sec)
...
mysql> USE bet;  
Database changed  
mysql> SHOW TABLES;  
+---------------+  
| Tables_in_bet |  
+---------------+  
| bookmaker     |  
| competition   |  
| market        |  
| odds          |  
| outcome       |  
+---------------+  

5 rows in set (0.004 sec)
mysql> CHANGE REPLICATION SOURCE TO  
   ->   SOURCE_HOST = '192.168.11.150',  
   ->   SOURCE_PORT = 3306,  
   ->   SOURCE_USER = 'repl',  
   ->   SOURCE_PASSWORD = '!OtusLinux2018',  
   ->   SOURCE_AUTO_POSITION = 1,  
   ->   GET_SOURCE_PUBLIC_KEY = 1;  
Query OK, 0 rows affected, 2 warnings (0.023 sec)  
  
mysql> START REPLICA;  
Query OK, 0 rows affected (0.064 sec)  
  
mysql> SHOW REPLICA STATUS\G  
*************************** 1. row ***************************  
            Replica_IO_State: Connecting to source  
                 Source_Host: 192.168.11.150  
                 Source_User: repl  
                 Source_Port: 3306  
               Connect_Retry: 60  
             Source_Log_File:    
         Read_Source_Log_Pos: 4  
              Relay_Log_File: slave-relay-bin.000001  
               Relay_Log_Pos: 4  
       Relay_Source_Log_File:    
          Replica_IO_Running: Connecting  
         Replica_SQL_Running: Yes  
             Replicate_Do_DB:    
         Replicate_Ignore_DB:    
          Replicate_Do_Table:    
      Replicate_Ignore_Table:    
     Replicate_Wild_Do_Table:    
 Replicate_Wild_Ignore_Table:    
                  Last_Errno: 0  
                  Last_Error:    
                Skip_Counter: 0  
         Exec_Source_Log_Pos: 0  
             Relay_Log_Space: 158  
             Until_Condition: None  
              Until_Log_File:    
               Until_Log_Pos: 0  
          Source_SSL_Allowed: Yes  
          Source_SSL_CA_File:    
          Source_SSL_CA_Path:    
             Source_SSL_Cert:    
           Source_SSL_Cipher:    
              Source_SSL_Key:    
       Seconds_Behind_Source: 0  
Source_SSL_Verify_Server_Cert: No  
               Last_IO_Errno: 2003  
               Last_IO_Error: Error connecting to source 'repl@192.168.11.150:3306'. This was attempt 1/10, with a delay of 60 seconds between attempts. Message: Can't connect to MySQL server on '192.168.11.150:3306' (110)  
              Last_SQL_Errno: 0  
              Last_SQL_Error:    
 Replicate_Ignore_Server_Ids:    
            Source_Server_Id: 0  
                 Source_UUID:    
            Source_Info_File: mysql.slave_master_info  
                   SQL_Delay: 0  
         SQL_Remaining_Delay: NULL  
   Replica_SQL_Running_State: Replica has read all relay log; waiting for more updates  
          Source_Retry_Count: 10  
                 Source_Bind:    
     Last_IO_Error_Timestamp: 261025 17:07:33  
    Last_SQL_Error_Timestamp:    
              Source_SSL_Crl:    
          Source_SSL_Crlpath:    
          Retrieved_Gtid_Set:    
           Executed_Gtid_Set: 06c2e257-d093-11f1-8f27-0800270a4e27:1,  
ca13db31-d093-11f1-a40d-0800270a4e27:1-39  
               Auto_Position: 1  
        Replicate_Rewrite_DB:    
                Channel_Name:    
          Source_TLS_Version:    
      Source_public_key_path:    
       Get_Source_public_key: 1  
           Network_Namespace:    
1 row in set (0.001 sec)  
  
mysql> STOP REPLICA;  
Query OK, 0 rows affected (2.019 sec)  
  
mysql> CHANGE REPLICATION SOURCE TO  
   ->   SOURCE_HOST = '192.168.56.150';  
Query OK, 0 rows affected (0.034 sec)  
  
mysql> START REPLICA;  
Query OK, 0 rows affected (0.054 sec)  
  
mysql> SHOW REPLICA STATUS\G  
*************************** 1. row ***************************  
            Replica_IO_State:    
                 Source_Host: 192.168.56.150  
                 Source_User: repl  
                 Source_Port: 3306  
               Connect_Retry: 60  
             Source_Log_File:    
         Read_Source_Log_Pos: 4  
              Relay_Log_File: slave-relay-bin.000001  
               Relay_Log_Pos: 4  
       Relay_Source_Log_File:    
          Replica_IO_Running: No  
         Replica_SQL_Running: Yes  
             Replicate_Do_DB:    
         Replicate_Ignore_DB:    
          Replicate_Do_Table:    
      Replicate_Ignore_Table:    
     Replicate_Wild_Do_Table:    
 Replicate_Wild_Ignore_Table:    
                  Last_Errno: 0  
                  Last_Error:    
                Skip_Counter: 0  
         Exec_Source_Log_Pos: 0  
             Relay_Log_Space: 158  
             Until_Condition: None  
              Until_Log_File:    
               Until_Log_Pos: 0  
          Source_SSL_Allowed: Yes  
          Source_SSL_CA_File:    
          Source_SSL_CA_Path:    
             Source_SSL_Cert:    
           Source_SSL_Cipher:    
              Source_SSL_Key:    
       Seconds_Behind_Source: 0  
Source_SSL_Verify_Server_Cert: No  
               Last_IO_Errno: 13117  
               Last_IO_Error: Fatal error: The replica I/O thread stops because source and replica have equal MySQL server ids; these ids must be different for replication to work (or the --replicate-same-server-id option must be used  
on replica but this does not always make sense; please check the manual before using it).  
              Last_SQL_Errno: 0  
              Last_SQL_Error:    
 Replicate_Ignore_Server_Ids:    
            Source_Server_Id: 1  
                 Source_UUID:    
            Source_Info_File: mysql.slave_master_info  
                   SQL_Delay: 0  
         SQL_Remaining_Delay: NULL  
   Replica_SQL_Running_State: Replica has read all relay log; waiting for more updates  
          Source_Retry_Count: 10  
                 Source_Bind:    
     Last_IO_Error_Timestamp: 261025 17:09:19  
    Last_SQL_Error_Timestamp:    
              Source_SSL_Crl:    
          Source_SSL_Crlpath:    
          Retrieved_Gtid_Set:    
           Executed_Gtid_Set: 06c2e257-d093-11f1-8f27-0800270a4e27:1,  
ca13db31-d093-11f1-a40d-0800270a4e27:1-39  
               Auto_Position: 1  
        Replicate_Rewrite_DB:    
                Channel_Name:    
          Source_TLS_Version:    
      Source_public_key_path:    
       Get_Source_public_key: 1  
           Network_Namespace:    
1 row in set (0.001 sec)  
  
mysql> STOP REPLICA;  
Query OK, 0 rows affected (0.009 sec)  
  
mysql> SET PERSIST server_id = 2;  
Query OK, 0 rows affected (0.006 sec)  
  
mysql> START REPLICA;  
Query OK, 0 rows affected (0.057 sec)  
  
mysql> SELECT @@server_id  
   -> ;  
+-------------+  
| @@server_id |  
+-------------+  
|           2 |  
+-------------+  
1 row in set (0.001 sec)  
  
mysql> exit  
Bye  
root@slave:~# vim /etc/mysql/mysql.conf.d/01-base.cnf  
root@slave:~# cat /etc/mysql/mysql.conf.d/01-base.cnf  
[mysqld]  
pid-file=/var/run/mysqld/mysqld.pid  
log-error=/var/log/mysqld.log  
datadir=/var/lib/mysql  
socket=/var/lib/mysql/mysql.sock  
symbolic-links=0  
  
server-id = 2    
innodb_file_per_table = 1  
skip-name-resolve  
root@slave:~# mysql -u root -p  
Enter password:    
Welcome to the MySQL monitor.  Commands end with ; or \g.  
Your MySQL connection id is 30  
Server version: 9.7.2-2 Percona Server (GPL), Release '2', Revision '91438a04'  
  
Copyright (c) 2009-2026 Percona LLC and/or its affiliates  
Copyright (c) 2000, 2026, Oracle and/or its affiliates.  
  
Oracle is a registered trademark of Oracle Corporation and/or its  
affiliates. Other names may be trademarks of their respective  
owners.  
  
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.  
  
mysql> SHOW REPLICA STATUS\G  
*************************** 1. row ***************************  
            Replica_IO_State: Waiting for source to send event  
                 Source_Host: 192.168.56.150  
                 Source_User: repl  
                 Source_Port: 3306  
               Connect_Retry: 60  
             Source_Log_File: binlog.000002  
         Read_Source_Log_Pos: 93735  
              Relay_Log_File: slave-relay-bin.000002  
               Relay_Log_Pos: 413  
       Relay_Source_Log_File: binlog.000002  
          Replica_IO_Running: Yes  
         Replica_SQL_Running: Yes  
             Replicate_Do_DB:    
         Replicate_Ignore_DB:    
          Replicate_Do_Table:    
      Replicate_Ignore_Table:    
     Replicate_Wild_Do_Table:    
 Replicate_Wild_Ignore_Table:    
                  Last_Errno: 0  
                  Last_Error:    
                Skip_Counter: 0  
         Exec_Source_Log_Pos: 93735  
             Relay_Log_Space: 624  
             Until_Condition: None  
              Until_Log_File:    
               Until_Log_Pos: 0  
          Source_SSL_Allowed: Yes  
          Source_SSL_CA_File:    
          Source_SSL_CA_Path:    
             Source_SSL_Cert:    
           Source_SSL_Cipher:    
              Source_SSL_Key:    
       Seconds_Behind_Source: 0  
Source_SSL_Verify_Server_Cert: No  
               Last_IO_Errno: 0  
               Last_IO_Error:    
              Last_SQL_Errno: 0  
              Last_SQL_Error:    
 Replicate_Ignore_Server_Ids:    
            Source_Server_Id: 1  
                 Source_UUID: ca13db31-d093-11f1-a40d-0800270a4e27  
            Source_Info_File: mysql.slave_master_info  
                   SQL_Delay: 0  
         SQL_Remaining_Delay: NULL  
   Replica_SQL_Running_State: Replica has read all relay log; waiting for more updates  
          Source_Retry_Count: 10  
                 Source_Bind:    
     Last_IO_Error_Timestamp:    
    Last_SQL_Error_Timestamp:    
              Source_SSL_Crl:    
          Source_SSL_Crlpath:    
          Retrieved_Gtid_Set:    
           Executed_Gtid_Set: 06c2e257-d093-11f1-8f27-0800270a4e27:1,  
ca13db31-d093-11f1-a40d-0800270a4e27:1-39  
               Auto_Position: 1  
        Replicate_Rewrite_DB:    
                Channel_Name:    
          Source_TLS_Version:    
      Source_public_key_path:    
       Get_Source_public_key: 1  
           Network_Namespace:    
1 row in set (0.001 sec)  
  
mysql> SELECT*FROM bookmaker;  
ERROR 1046 (3D000): No database selected  
mysql> USE bet;  
Reading table information for completion of table and column names  
You can turn off this feature to get a quicker startup with -A  
  
Database changed  
mysql> SELECT*FROM bookmaker;  
+----+----------------+  
| id | bookmaker_name |  
+----+----------------+  
|  1 | 1xbet          |  
|  4 | betway         |  
|  5 | bwin           |  
|  6 | ladbrokes      |  
|  3 | unibet         |  
+----+----------------+  
5 rows in set (0.001 sec)
```

##### Лог изменения на реплике
```
root@slave:~# mysqlbinlog --base64-output=DECODE-ROWS -vv /var/lib/mysql/slave-relay-bin.000002 | tail -n 20  
/*!80011 SET @@session.default_collation_for_utf8mb4=255*//*!*/;  
BEGIN  
/*!*/;  
# at 568  
#261025 17:20:39 server id 1  end_log_pos 93952 CRC32 0xadf6260d        Table_map: `bet`.`bookmaker` mapped to number 183  
# has_generated_invisible_primary_key=0  
# at 630  
#261025 17:20:39 server id 1  end_log_pos 93999 CRC32 0x128b48c5        Write_rows: table id 183 flags: STMT_END_F USE_SQL_FOREIGN_KEY_F  
### INSERT INTO `bet`.`bookmaker`  
### SET  
###   @1=1 /* INT meta=0 nullable=0 is_null=0 */  
###   @2='1xbet' /* VARSTRING(1020) meta=1020 nullable=1 is_null=0 */  
# at 677  
#261025 17:20:39 server id 1  end_log_pos 94030 CRC32 0x7d72187a        Xid = 776  
COMMIT/*!*/;  
SET @@SESSION.GTID_NEXT= 'AUTOMATIC' /* added by mysqlbinlog */ /*!*/;  
DELIMITER ;  
# End of log file  
/*!50003 SET COMPLETION_TYPE=@OLD_COMPLETION_TYPE*/;  
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=0*/;
```
#### Инструкция по настройке репликации
```
root@master:~# sudo apt update
sudo apt install -y curl
curl -O https://repo.percona.com/apt/percona-release_latest.generic_all.deb
sudo apt install -y gnupg2 lsb-release ./percona-release_latest.generic_all.deb
sudo percona-release enable-only ps-97-lts release --scheme https
sudo apt update
sudo apt install -y percona-server-server

root@master:~# cp /vagrant/conf/conf.d/* /etc/mysql/mysql.conf.d/

root@master:~# systemctl start mysql

root@master:~# mysql -u root -p

mysql> SELECT @@server_id;

mysql> SHOW VARIABLES LIKE 'gtid_mode';

mysql> CREATE DATABASE bet;

mysql> exit

root@master:~# mysql -u root -p -D bet < /vagrant/bet-224190-percona-9.7.2.sql

root@master:~# mysql -u root -p

mysql> USE bet;

mysql> SHOW TABLES;

mysql> CREATE USER 'repl'@'%' IDENTIFIED BY '!OtusLinux2018';

mysql> SELECT user,host FROM mysql.user where user='repl';

mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

mysql> exit

root@master:~# mysqldump --all-databases --triggers --routines --source-data --ignore-table=bet.events_on_demand --ignore-table=bet.v_same_event -u root -p > master.sql

root@master:~# cp ./master.sql /vagrant/
--------------------------------------------------
ИДЕМ НА РЕПЛИКУ

root@slave:~# sudo apt update
sudo apt install -y curl
curl -O https://repo.percona.com/apt/percona-release_latest.generic_all.deb
sudo apt install -y gnupg2 lsb-release ./percona-release_latest.generic_all.deb
sudo percona-release enable-only ps-97-lts release --scheme https
sudo apt update
sudo apt install -y percona-server-server

cp /vagrant/conf/conf.d/* /etc/mysql/mysql.conf.d/

mysql -u root -p

mysql> SELECT @@server_id;

mysql> exit

root@slave:~# vim /etc/mysql/mysql.conf.d/01-base.cnf
МЕНЯЕМ директиву server-id = 2


root@slave:~# vim /etc/mysql/mysql.conf.d/05-binlog.cnf
РАСКОММЕНТИРУЕМ
#replicate-ignore-table=bet.events_on_demand
#replicate-ignore-table=bet.v_same_event

root@slave:~# systemctl restart mysql

root@slave:~# cp /vagrant/master.sql ./

root@slave:~# mysql -u root -p

mysql> SOURCE /vagrant/master.sql

mysql> SHOW DATABASES LIKE 'bet';

mysql> USE bet;

mysql> SHOW TABLES;

mysql> CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = '192.168.56.150',
  SOURCE_PORT = 3306,
  SOURCE_USER = 'repl',
  SOURCE_PASSWORD = '!OtusLinux2018',
  SOURCE_AUTO_POSITION = 1,
  GET_SOURCE_PUBLIC_KEY = 1;

mysql> START REPLICA;

mysql> SHOW REPLICA STATUS\G

--------------------------------------------------
ПРОВЕРИМ РЕПЛИКАЦИЮ, ИДЕМ НА МАСТЕР

root@master:~# mysql -u root -p

mysql> USE bet;

mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');

mysql> SELECT*FROM bookmaker;

--------------------------------------------------
ИДЕМ НА СЛЕЙВ

SELECT * FROM bookmaker;

```