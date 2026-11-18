# ВМ через OpenTofu, настройка через Ansible

Для проекта используем **OpenTofu**, команды начинаются с `tofu`.
Он создаёт ВМ через API Proxmox. После этого Ansible подключается к гостевым
ОС по SSH и настраивает сервисы. Шаблон 9001 и мосты подготавливаются вручную. [Сборка шаблона](../image-build/README.md).

Инструкция описывает создание четырёх ВМ из шаблона 9001.

## 1. Установить OpenTofu на ПК администратора

Команды для Ubuntu. OpenTofu устанавливается на тот же ПК, где работает Ansible.

Скачать официальный установщик:

```bash
cd /tmp
curl --proto '=https' --tlsv1.2 -fsSL \
  https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
```

Установить из официального APT-репозитория:

```bash
bash /tmp/install-opentofu.sh --install-method deb
tofu version
```

Допускаются версии OpenTofu от 1.11.4 до 2.0.
Провайдер bpg/proxmox 0.78.0 закреплён в versions.tf.
`tofu init` установит её автоматически.

## 2. Подготовить Proxmox

Мосты, маршруты, пул, API-токен и шаблон подготавливаются один раз
по [инструкции инфраструктуры](../infrastructure/README.md).
Для развёртывания нужны шаблон 9001, пул otus-nextcloud и права
пользователя otus-ansible@pve.

## 3. Проверить VMID для нового стенда

При развёртывании с пустым state убедиться, что VMID 121–124 свободны.

```bash
qm list
```

Если VMID заняты, а state пуст, сначала восстановить рабочий state
или разобраться, какие ВМ занимают эти ID.

## 4. Открыть каталог конфигурации и ввести токен

На **ПК администратора**:

```bash
cd OTUS_final_project/opentofu
```

Вводим секрет API-токена, полученный при подготовке Proxmox.

```bash
export PROXMOX_VE_API_TOKEN='otus-ansible@pve!provision='"токен"
```

Проверка TLS-сертификата API выключена (`insecure = true`). SSH на Proxmox этому набору ресурсов не требуется:
готовый шаблон клонируется через API, файлы/snippets на узел не загружаются.

## 5. Инициализировать проект

В том же терминале, из каталога `opentofu`:

```bash
tofu init
tofu validate
```

`init` нужен при первом запуске и после изменения версии провайдера.
Он не создаёт ВМ. При успешном validate будет сообщение
`Success! The configuration is valid.`

## 6. Создать четыре ВМ

Из каталога opentofu:

```bash
tofu plan -parallelism=1
tofu apply -parallelism=1
tofu output
```

Для пустого state план должен содержать создание ВМ 121–124.
Параметры ВМ заданы в файлах proxy.tf, backend1.tf, backend2.tf,
observability.tf. Параллелизм 1 ограничивает нагрузку при клонировании.

## 7. Подготовить SSH и запустить Ansible

```bash
cd OTUS_final_project
ssh -i .secrets/ssh/otus_nextcloud_ed25519 ansible@172.16.10.10
```

Внутри ВМ дожидаемся Cloud-init и завершаем SSH-сеанс:

```bash
cloud-init status --wait
exit
```

Подключаемся к backend1 через proxy:

```bash
ssh -i .secrets/ssh/otus_nextcloud_ed25519 \
  -o 'ProxyCommand=ssh -i .secrets/ssh/otus_nextcloud_ed25519 -o IdentitiesOnly=yes -W %h:%p ansible@172.16.10.10' \
  ansible@10.20.0.11
```
Повторяем для backend2 по адресу 10.20.0.12 и observability по адресу 10.20.0.20.
Из корня проекта в активном окружении Ansible запускаем:

```bash
ansible-playbook site.yml --ask-vault-pass -e otus_initialize=true
```

Параметр otus_initialize=true используется для первого запуска
с пустыми дисками обоих бэкендов. Повторная настройка:

```bash
ansible-playbook site.yml --ask-vault-pass
```

## Где редактировать параметры

| Файл | Назначение |
|---|---|
| `opentofu/proxy.tf` | proxy 121, 1 CPU, 1 ГиБ RAM, ОС 12 ГиБ, DMZ и внутренняя сеть |
| `opentofu/backend1.tf` | backend1 122, 2 CPU, 6 ГиБ RAM, диски 20/8/4 ГиБ |
| `opentofu/backend2.tf` | backend2 123, такие же ресурсы |
| `opentofu/observability.tf` | observability 124, 2 CPU, 4 ГиБ RAM, ОС 48 ГиБ |
| `opentofu/provider.tf` | Адрес API и настройка проверки сертификата |
| `opentofu/variables.tf` | VMID шаблона и путь к публичному SSH-ключу |
| `opentofu/versions.tf` | Допустимая версия OpenTofu и закреплённый провайдер |
| `inventory/hosts.yml` | Адреса и группы для Ansible |
