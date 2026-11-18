# Развертывание веб-приложения с автоматическим восстановлением посредством Ansible

## Техническое задание
1. В качестве веб-приложения использовать Nextcloud. Не использовать Docker
2. Фронтенд (обратный прокси) и два бэкенда с балансировкой
3. 3 ВМ или больше
4. Логирование - всех сервисов
5. Мониторинг - должны быть уведомления (куда угодно: почта, телеграм, какое-то приложение и т.п.)
6. База данных с репликацией. Также нужно настроить бэкапирование
7. Возможность восстановления любого сервера автоматически (с помощью ручного запуска Ansible плейбука или роли)
8. Обязательно ssl, самоподписанный
9. Selinux можно отключить
10. Настроить DMZ
11. С фронтенда (обратный прокси) нужно ограничить доступы, 80 и 443 доступны, а 22 порт только с определенного адреса (ПК администратора, на котором будут запускаться плейбуки и выполняться другая настройка), т.е. должна быть фильтрация по IP и портам
12. Фронтенд должен работать по https, между фронтендом и бэкендом можно http
13. Бэкенд должен работать на двух ВМ. При потере одного бэкенда, приложение должно продолжать работать за счет второго
14. Должна быть схема проекта


## Общая информация
Стенд состоит из 4 ВМ Ubuntu 24.04. OpenTofu создаёт ВМ из
универсального шаблона, Ansible настраивает их через плейбук site.yml.

| ВМ | VMID | Адрес | Сервисы |
|---|---|---|---|
| proxy | 121 | 172.16.10.10, 10.20.0.10 | Nginx, HTTPS, SSH-доступ, маршрутизация и firewall |
| backend1 | 122 | 10.20.0.11 | Apache/PHP-FPM, Nextcloud, MariaDB/Galera, DRBD, Pacemaker |
| backend2 | 123 | 10.20.0.12 | Тот же набор сервисов |
| observability | 124 | 10.20.0.20 | QNetd, garbd, Prometheus, Grafana, Alertmanager, ntfy, rsyslog, Borg |

MariaDB реплицируется через Galera. Файлы Nextcloud и Redis AOF находятся
на DRBD с ext4. Pacemaker запускает NFS, VIP 10.20.0.100 и Redis на одном
бэкенде. Оба Nextcloud подключаются к NFS и к собственной MariaDB.
Corosync с QDevice/QNetd обеспечивает кворум, diskless SBD использует
виртуальный watchdog i6300esb.

Роли отключают автоматическую установку обновлений Ubuntu: она может
одновременно перезапустить службы кластера. Обновления, включая обновления
безопасности, устанавливаются вручную по одному узлу с проверкой кластера.

## Структура

| Каталог | Содержимое |
|---|---|
| image-build/ | Ручная сборка образа, Cloud-init, подготовка UI Alertmanager и локальные артефакты |
| infrastructure/ | Подготовка Proxmox, API, сети, роутера, DNS |
| opentofu/ | Создание четырёх ВМ |
| inventory/ | Адреса, параметры и локальный зашифрованный Vault |
| roles/ | Роли proxy, backend1, backend2 и observability |
| tasks/, templates/, files/ | Задачи и конфигурации сервисов |

## Архитектура

Четыре ВМ на одном Proxmox. OpenTofu создаёт ВМ из шаблона 9001.
Ansible настраивает каждую ВМ её ролью через site.yml.

- proxy принимает HTTPS и распределяет HTTP-запросы между Apache.
- На каждом бэкенде Nextcloud использует локальную MariaDB.
  Galera объединяет две MariaDB и garbd на observability.
- DRBD реплицирует отдельные диски scsi2 по 4 ГиБ. ext4 монтируется
  только на Primary. NFS экспортирует файлы Nextcloud через VIP 10.20.0.100.
- Redis с AOF, NFS, VIP и фоновые задания следуют за владельцем хранилища.
  UID/GID Redis на обоих узлах закреплены как 6379.
- Corosync использует два голоса бэкендов и QDevice/QNetd.
  Diskless SBD с watchdog i6300esb обеспечивает fencing.
- observability хранит метрики, логи, уведомления и единственный Borg-репозиторий.

## Схемы
### Схема сети
[Схема сети](docs/infrastructure/network-topology.png)

- **SSH и HTTPS из LAN.** Роутер отправляет пакеты к DMZ через Proxmox.
  Proxmox сохраняет адрес клиента, поэтому `proxy` может разрешить SSH
  только с `192.168.1.100`. Ansible открывает SSH через ProxyJump, и
  proxy подключается к внутреннему адресу ВМ. Nginx принимает HTTPS
  в DMZ и обращается к бэкендам через vmbr2.
- **Интернет и DNS для внутренних ВМ.** Пакет идёт через `proxy`, затем
  через Proxmox. При выходе в LAN Proxmox подставляет свой адрес
  `192.168.1.101`. После обратного преобразования ответы во внутреннюю
  сеть идут через `172.16.10.10`.
- **Обмен внутри кластера.** ВМ на `vmbr2` обмениваются пакетами напрямую.
  При отказе `proxy` этот обмен сохраняется, а вход в Nextcloud, SSH
  через ProxyJump и внешний доступ внутренних ВМ прерываются.

### Схема работы
[Работа сервисов](docs/stand-schemes-service-working.png)

## Подготовка

Нужны OpenTofu 1.x, Python 3.12+ и Ansible 2.21+.
Провайдер bpg/proxmox закреплён в opentofu/.terraform.lock.hcl.

1. Подготавливаем внешнюю инфраструктуру по [infrastructure](docs/infrastructure/README.md).
2. Собираем шаблон 9001 по [image-build](docs/image-build/README.md).
3. Подготавливаем локальные секреты, затем создаём ВМ по [OpenTofu](docs/OPENTOFU.md).
4. Дожидаемся Cloud-init, подключаемся по SSH, чтобы ВМ добавились в known_hosts.
5. Из корня проекта запускаем роли.


## Развёртывание
Первый запуск с пустыми дисками обоих бэкендов:

```bash
ansible-playbook site.yml --ask-vault-pass -e otus_initialize=true
```

Повторная настройка всего стенда или одной пересозданной ВМ:

```bash
ansible-playbook site.yml --ask-vault-pass
ansible-playbook site.yml --limit backend2 --ask-vault-pass
ansible-playbook site.yml --limit proxy --ask-vault-pass
ansible-playbook site.yml --limit observability --ask-vault-pass
```

Для одиночного восстановления бэкенда нужны работающий сосед, proxy
и observability. Данные Galera и DRBD синхронизируются с живого бэкенда.
Для новой пустой установки откладываем прежний .secrets/nextcloud-config.php
перед инициализацией. При восстановлении отдельного узла используется
сохранённая конфигурация текущего экземпляра.

## Локальные секреты

На ПК администратора хранятся:

- .secrets/ssh/otus_nextcloud_ed25519 и публичный ключ с расширением .pub.
- inventory/group_vars/all/vault.yml и пароль его шифрования.
- .secrets/nextcloud-config.php, сертификат и ключ proxy, Corosync authkey.
- State OpenTofu и API-токен в переменной PROXMOX_VE_API_TOKEN.

Для создания SSH-ключа и секрета выполняем:

```bash
install -d -m 0700 .secrets/ssh
ssh-keygen -t ed25519 -f .secrets/ssh/otus_nextcloud_ed25519 -C otus-nextcloud-ansible
ansible-vault create inventory/group_vars/all/vault.yml
```

Vault содержит следующие параметры:

| Параметры | Назначение |
|---|---|
| vault_database_password, vault_galera_sst_password, vault_redis_password | Пароли MariaDB, SST и Redis. Для текущих конфигураций используются буквы, цифры, дефис и подчёркивание. |
| vault_nextcloud_admin_password, vault_grafana_admin_password | Начальные пароли администраторов |
| vault_ntfy_publisher_token, vault_ntfy_publisher_hash | Токен ntfy и bcrypt-хеш пароля его служебного пользователя |
| vault_backup_passphrase | Пароль Borg |
| vault_backup_ca_certificate, vault_backup_server_pem | CA-сертификат и PEM сервера Borg с закрытым ключом |
| vault_backup_client_pems | PEM-клиенты с ключами, словарь с ключами backend1 и backend2 |
| vault_pve_api_token_secret | Секрет Proxmox API для ручного использования |

TLS и конфигурация установленного Nextcloud сохраняются Ansible в .secrets/.
Материалы для резервного копирования должны быть подготовлены до запуска ролей.

.gitignore исключает секреты, заметки, state, планы,
скачанные пакеты, образы и локальные кэши. Публичная часть содержит код
и документацию. Внутренние IP-адреса и имена узлов оставлены как параметры
учебного стенда.
