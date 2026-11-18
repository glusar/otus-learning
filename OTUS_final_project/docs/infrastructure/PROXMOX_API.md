# Доступ OpenTofu к API Proxmox

Для нового развёртывания используется шаблон 9001.
Для четырёх новых ВМ используются VMID 121–124, хранилище kingston
и мосты vmbr0/vmbr1/vmbr2. Шаблон и рабочие ВМ входят в пул ресурсов
`otus-nextcloud`; права наследуются от пула и сохраняются при удалении ВМ.
VM.Allocate позволяет создавать и удалять гостей в пределах этого пула.
Ресурсы вне проекта в пул не добавлять.

Для доступа используются пользователь `otus-ansible@pve` и токен `provision`.
Команды выполняются при первоначальной подготовке Proxmox.

## 1. Создать роли и пользователя

В **Shell Proxmox**, под root:

```bash
pveum user add otus-ansible@pve --comment 'OTUS Ansible provisioning'

pveum role add OTUSProvision --privs 'Pool.Audit VM.Allocate VM.Audit VM.Monitor VM.PowerMgmt VM.Config.CPU VM.Config.Memory VM.Config.Disk VM.Config.Network VM.Config.Cloudinit VM.Config.Options VM.Config.HWType VM.Config.CDROM'
pveum role add OTUSTemplate --privs 'VM.Audit VM.Clone'
pveum role add OTUSStorage --privs 'Datastore.Audit Datastore.AllocateSpace'
pveum role add OTUSBridge --privs 'SDN.Use'
pveum role add OTUSNode --privs 'Sys.Audit'
```

## 2. Создать API-токен

В **Shell Proxmox**:

```bash
pveum user token add otus-ansible@pve provision --privsep 1
```

Секрет будет показан один раз. Сохранить его в защищённых материалах проекта
и затем в Vault на ПК администратора. Секрет хранится в зашифрованном виде.

Privilege Separation включён: права нужны и пользователю, и токену.
Команды следующего раздела назначают одинаковые роли обоим субъектам.

## 3. Выдать права на пул проекта

```bash
pveum pool add otus-nextcloud --comment 'OTUS Nextcloud project'
pveum acl modify /pool/otus-nextcloud --users otus-ansible@pve --tokens 'otus-ansible@pve!provision' --roles OTUSProvision,OTUSTemplate --propagate 1
```

Выдаём доступ к узлу, хранилищу и мостам.

```bash
pveum acl modify /nodes/pve --users otus-ansible@pve --tokens 'otus-ansible@pve!provision' --roles OTUSNode

pveum acl modify /storage/kingston --users otus-ansible@pve --tokens 'otus-ansible@pve!provision' --roles OTUSStorage

pveum acl modify /sdn/zones/localnetwork/vmbr0 --users otus-ansible@pve --tokens 'otus-ansible@pve!provision' --roles OTUSBridge
pveum acl modify /sdn/zones/localnetwork/vmbr1 --users otus-ansible@pve --tokens 'otus-ansible@pve!provision' --roles OTUSBridge
pveum acl modify /sdn/zones/localnetwork/vmbr2 --users otus-ansible@pve --tokens 'otus-ansible@pve!provision' --roles OTUSBridge
```

Проверить членство в Shell Proxmox:

```bash
pvesh get /pools/otus-nextcloud --output-format json-pretty
pveum user token permissions otus-ansible@pve provision
```


## 4. HTTPS в лабораторном стенде

В `opentofu/provider.tf` задано `insecure = true`.
Соединение идёт по HTTPS, но сертификат API не проверяется.
Копировать CA или сертификат сервера для этой конфигурации не требуется.

## 5. Передать токен OpenTofu

OpenTofu читает полный токен из переменной окружения PROXMOX_VE_API_TOKEN.

Задать переменную можно командой:  

```bash
export PROXMOX_VE_API_TOKEN='otus-ansible@pve!provision='"токен"
```
