# Ручная настройка мостов Proxmox

## Что должно получиться

| Мост | Назначение | Адрес Proxmox | Физический порт |
|---|---|---|---|
| vmbr0 | Существующее управление и LAN | 192.168.1.101/24 | enp5s0 |
| vmbr1 | DMZ | 172.16.10.1/24 | Нет |
| vmbr2 | Внутренняя сеть ВМ | Нет | Нет |


## 1. Открыть Shell и посмотреть текущую сеть

Открыть **pve → Shell** в GUI либо подключиться с ПК администратора:

```bash
ssh root@192.168.1.101
```

Далее команды выполняются под root на Proxmox:

```bash
ip -br addr
ip route
cat /etc/network/interfaces
pvesh get /nodes/pve/network --output-format json-pretty
```

## 2. Сохранить резервную копию

В той же Shell-сессии:

```bash
otus_network_backup="/root/interfaces.before-otus-$(date +%Y%m%d-%H%M%S)"
cp -a /etc/network/interfaces "$otus_network_backup"
printf '%s\n' "$otus_network_backup"
```

Сохранить напечатанный путь: это копия настроек до изменения.

## 3. Добавить мосты в основной файл

Открыть файл:

```bash
nano /etc/network/interfaces
```

Сохранить существующие настройки. В конец файла добавить:

```text
# BEGIN OTUS NEXTCLOUD BRIDGES
auto vmbr1
iface vmbr1 inet static
    address 172.16.10.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    post-up /usr/sbin/sysctl -q -w net.ipv6.conf.vmbr1.disable_ipv6=1

auto vmbr2
iface vmbr2 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    post-up /usr/sbin/sysctl -q -w net.ipv6.conf.vmbr2.disable_ipv6=1
# END OTUS NEXTCLOUD BRIDGES
```

`bridge-ports none` создаёт мост без физического подключения. На `vmbr2`
не назначается IPv4-адрес хоста. Команды `post-up` выключают IPv6 на новых
мостах, чтобы на `vmbr2` не появлялся и link-local адрес.

Мосты записываются именно в `/etc/network/interfaces`: парсер GUI Proxmox
не показывает определения из подключаемых файлов `interfaces.d`.


## 4. Проверить синтаксис и поднять мосты

Сначала выполнить:

```bash
ifup --syntax-check vmbr1 vmbr2
```

Для возврата файла до активации можно использовать резервную копию в той же Shell-сессии:

```bash
cp -a "$otus_network_backup" /etc/network/interfaces
```

После успешной проверки выполнить:

```bash
ifup vmbr1 vmbr2
```

Команда применяет настройки только этих двух мостов. Перезагружать сервер
или перезапускать всю службу сети не требуется.

## 5. Проверить результат

```bash
ip -br addr show vmbr0
ip -br addr show vmbr1
ip -br addr show vmbr2
bridge link show
sysctl net.ipv4.ip_forward
pvesh get /nodes/pve/network --output-format json-pretty
```

Ожидается:

- `vmbr0` сохранил `192.168.1.101/24`, основной маршрут не изменился.
- `vmbr1` имеет адрес `172.16.10.1/24`.
- У `vmbr2` нет IP-адресов.
- `enp5s0` остался подключён к `vmbr0`, а не к новым мостам.
- Оба новых моста присутствуют в API и после обновления страницы **pve → Network**.
- `net.ipv4.ip_forward = 0`, если этап маршрутизации ещё не выполнялся.

У пустого моста без подключённых ВМ может не быть carrier: это само по себе
не означает ошибку. Проверять наличие моста, адреса и конфигурацию.

После подготовки сети создаём [шаблон](../image-build/README.md).
IPv4 forwarding здесь не включается: сначала нужно настроить firewall
и разрешённые направления маршрутизации по плану проекта.

## Схема сети

[схема_сети](network-topology.png)

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

## Доступ через DMZ

Перед развёртыванием ВМ подготавливаем маршрут до DMZ и доступ к консоли
Proxmox. На ПК администратора проверяем `ip -4 route get 172.16.10.10`.
Ожидается LAN-интерфейс и адрес источника `192.168.1.100`. При использовании VPN направьте трафик DMZ через LAN.

На домашнем роутере добавляем статический маршрут
`172.16.10.0/24 via 192.168.1.101`. На Proxmox нужны IPv4 forwarding,
обратный маршрут `10.20.0.0/24 via 172.16.10.10` и SNAT для этих двух
подсетей при выходе через `vmbr0`. Согласуем правила с действующим
firewall Proxmox и сохраняем их в его текущей системе настройки.

Маршрутизацию, firewall и SSH forwarding на proxy настраивает его роль
в site.yml. После развёртывания проверяем SSH через proxy к внутренним ВМ,
DNS через 192.168.1.111 и исходящий HTTPS.
