# Ручная сборка шаблона Ubuntu 24.04 для Proxmox

Шаблон `9001` (`otus-ubuntu-2404-cached-template`) используется для proxy,
обоих бэкендов и observability. Системный диск — 8 ГиБ на `kingston`,
2 vCPU, 2048 МиБ RAM, Cloud-init и QEMU Guest Agent.

В образ включён кэш внешних артефактов. Cloud-init открывает его по пути
`/var/cache/otus-packages` при первом запуске клона. Установку выполняет
Ansible по ролям. Proxy только получает файлы вместе с образом.

| Артефакт | Где используется |
| --- | --- |
| `nextcloud-34.0.5.tar.bz2` | Оба бэкенда, роли `backend1` и `backend2` |
| `grafana_13.3.0_40412481033_linux_amd64.deb` | observability, роль `observability` |
| `ntfy_2.37.2_linux_amd64.deb` | observability, роль `observability` |
| `alertmanager-ui-0.26.0.tar.gz` | observability, роль `observability` |

## 1. Подготовить файлы на ПК администратора

Команды выполняются из корня проекта. Скачанные пакеты и образы хранятся
в `image-build/artifacts/`, этот каталог исключён из Git. Для сборки нужны
`virt-customize` и `guestfish`. На ПК администратора `guestfish`
поставляется отдельным пакетом, поэтому проверяем обе команды.

```bash
cd OTUS_final_project
sudo apt-get update
sudo apt-get --no-remove install --no-install-recommends guestfs-tools guestfish qemu-utils curl
command -v virt-customize guestfish qemu-img
install -d -m 0700 image-build/artifacts
```

Скачиваем исходный образ Ubuntu в `image-build/artifacts/ubuntu-original.img`.

```bash
curl -fSL --retry 3 -o image-build/artifacts/ubuntu-original.img.part \
  https://cloud-images.ubuntu.com/noble/20261017/noble-server-cloudimg-amd64.img &&
mv image-build/artifacts/ubuntu-original.img.part image-build/artifacts/ubuntu-original.img
```

Скачиваем внешние пакеты для образа.

```bash
curl -fSL --retry 3 -o image-build/artifacts/nextcloud-34.0.5.tar.bz2.part \
  https://download.nextcloud.com/server/releases/nextcloud-34.0.5.tar.bz2 &&
mv image-build/artifacts/nextcloud-34.0.5.tar.bz2.part image-build/artifacts/nextcloud-34.0.5.tar.bz2

curl -fSL -o image-build/artifacts/grafana_13.3.0_40412481033_linux_amd64.deb.part \
  https://dl.grafana.com/grafana/release/13.3.0/grafana_13.3.0_40412481033_linux_amd64.deb &&
mv image-build/artifacts/grafana_13.3.0_40412481033_linux_amd64.deb.part \
  image-build/artifacts/grafana_13.3.0_40412481033_linux_amd64.deb

curl -fSL -o image-build/artifacts/ntfy_2.37.2_linux_amd64.deb.part \
  https://github.com/binwiederhier/ntfy/releases/download/v2.37.2/ntfy_2.37.2_linux_amd64.deb &&
mv image-build/artifacts/ntfy_2.37.2_linux_amd64.deb.part image-build/artifacts/ntfy_2.37.2_linux_amd64.deb
```

Извлекаем готовые файлы UI Alertmanager из релиза и упаковываем их для образа.

```bash
curl -fSL -o image-build/artifacts/alertmanager-0.26.0-source.tar.gz \
  https://codeload.github.com/prometheus/alertmanager/tar.gz/refs/tags/v0.26.0 &&
python3 image-build/prepare-alertmanager-ui.py image-build/artifacts/alertmanager-0.26.0-source.tar.gz
```

Упаковываем UI для кэша образа.

```bash
tar -czf image-build/artifacts/alertmanager-ui-0.26.0.tar.gz \
  -C image-build/artifacts/alertmanager-ui-0.26.0 . &&
rm -r -- image-build/artifacts/alertmanager-ui-0.26.0 image-build/artifacts/alertmanager-0.26.0-source.tar.gz
```

## 2. Вручную подготовить образ

Исходный диск Ubuntu имеет размер 3,5 ГиБ, из которых корневой раздел
занимает около 2,5 ГиБ. Для загрузки пакетов заранее расширяем диск до 8 ГиБ
вместе с корневым разделом и ext4.

Для этой сборки Ubuntu корневой раздел имеет номер 1, а раздел с
`/boot` — 16. Расширяем рабочую копию с сохранением номеров разделов, чтобы GRUB находил /boot.
Для повторной сборки сначала убираем прежнюю рабочую копию с этого пути.

```bash
test ! -e image-build/artifacts/ubuntu-2404-otus-cached.img &&
cp --reflink=auto --sparse=always image-build/artifacts/ubuntu-original.img image-build/artifacts/ubuntu-2404-otus-cached.img &&
qemu-img resize -f qcow2 image-build/artifacts/ubuntu-2404-otus-cached.img 8G
```

```bash
sudo env LIBGUESTFS_BACKEND=direct guestfish --rw --format=qcow2 \
  -a image-build/artifacts/ubuntu-2404-otus-cached.img \
  run : part-expand-gpt /dev/sda : part-resize /dev/sda 1 16775167 \
  : e2fsck /dev/sda1 correct:true : resize2fs /dev/sda1 : part-list /dev/sda &&
sudo env LIBGUESTFS_BACKEND=direct virt-df -h -a image-build/artifacts/ubuntu-2404-otus-cached.img
```

Число `16775167` — конечный сектор раздела 1 для диска 8 ГиБ с секторами
512 байт. В выводе `part-list` должны сохраниться номера 1, 14, 15 и 16.

Устанавливаем Guest Agent из репозитория Ubuntu. Добавляем четыре артефакта как
файлы, чтобы их позже использовал Ansible. Следующий блок выполняется только
после успешного расширения. В выводе `virt-df` на корневом разделе должно
быть несколько гигабайт свободного места.

```bash
sudo env LIBGUESTFS_BACKEND=direct virt-customize \
  -a image-build/artifacts/ubuntu-2404-otus-cached.img \
  --install qemu-guest-agent \
  --run-command 'systemctl enable qemu-guest-agent' \
  --mkdir /opt/otus-package-seed \
  --upload image-build/artifacts/nextcloud-34.0.5.tar.bz2:/opt/otus-package-seed/nextcloud-34.0.5.tar.bz2 \
  --upload image-build/artifacts/grafana_13.3.0_40412481033_linux_amd64.deb:/opt/otus-package-seed/grafana_13.3.0_40412481033_linux_amd64.deb \
  --upload image-build/artifacts/ntfy_2.37.2_linux_amd64.deb:/opt/otus-package-seed/ntfy_2.37.2_linux_amd64.deb \
  --upload image-build/artifacts/alertmanager-ui-0.26.0.tar.gz:/opt/otus-package-seed/alertmanager-ui-0.26.0.tar.gz \
  --upload image-build/cloud-init/otus-package-cache.cfg:/etc/cloud/cloud.cfg.d/95-otus-package-cache.cfg \
  --run-command 'chown -R root:root /opt/otus-package-seed && chmod 0755 /opt/otus-package-seed && chmod 0644 /opt/otus-package-seed/*' \
  --run-command 'chown root:root /etc/cloud/cloud.cfg.d/95-otus-package-cache.cfg && chmod 0644 /etc/cloud/cloud.cfg.d/95-otus-package-cache.cfg' \
  --run-command 'cloud-init clean --logs' \
  --run-command 'printf "uninitialized\n" > /etc/machine-id' \
  --run-command 'ln -sf /etc/machine-id /var/lib/dbus/machine-id'
```

При первом запуске фрагмент Cloud-init создаст ссылку
`/var/cache/otus-packages → /opt/otus-package-seed`. Значение
`uninitialized` позволяет каждому клону получить собственный machine-id.

```bash
sudo env LIBGUESTFS_BACKEND=direct virt-ls -a image-build/artifacts/ubuntu-2404-otus-cached.img -l /opt/otus-package-seed
sudo env LIBGUESTFS_BACKEND=direct virt-cat -a image-build/artifacts/ubuntu-2404-otus-cached.img /etc/cloud/cloud.cfg.d/95-otus-package-cache.cfg
```

## 3. Импортировать образ и создать шаблон 9001

В Shell Proxmox проверяем свободный VMID, доступность `kingston` и место
для временного файла образа. Пул `otus-nextcloud` должен существовать.
Подготовка пула описана в [настройке прав Proxmox](../infrastructure/PROXMOX_API.md).

```bash
pvesh get /cluster/nextid --vmid 9001
pvesm status
df -h /var/lib/vz
install -d -m 0755 /var/lib/vz/template/cloud/otus-ubuntu-2404-cached
```

С ПК администратора загружаем образ и публичный ключ.

```bash
cd OTUS_final_project
scp image-build/artifacts/ubuntu-2404-otus-cached.img \
  .secrets/ssh/otus_nextcloud_ed25519.pub \
  root@192.168.1.101:/var/lib/vz/template/cloud/otus-ubuntu-2404-cached/
```

В Shell Proxmox создаём шаблон 9001.

```bash
qm create 9001 --name otus-ubuntu-2404-cached-template --pool otus-nextcloud \
  --memory 2048 --cores 2 --ostype l26 --scsihw virtio-scsi-pci \
  --net0 virtio,bridge=vmbr0 --agent enabled=1 --serial0 socket --vga serial0 \
  --tags otus-nextcloud
qm set 9001 --scsi0 kingston:0,import-from=/var/lib/vz/template/cloud/otus-ubuntu-2404-cached/ubuntu-2404-otus-cached.img
qm set 9001 --ide2 kingston:cloudinit --boot order=scsi0 --ciuser ansible \
  --ciupgrade 0 --sshkeys /var/lib/vz/template/cloud/otus-ubuntu-2404-cached/otus_nextcloud_ed25519.pub
qm template 9001
qm config 9001
qm cloudinit dump 9001 user
```

В `qm config 9001` проверяем `template: 1`, диск 8 ГиБ на `kingston`,
Cloud-init-диск на `ide2`, пользователя `ansible` и включённый Guest Agent.

## 4. Использовать шаблон

Для новых ВМ OpenTofu использует template_id 9001.
Из корня проекта:

```bash
tofu -chdir=opentofu plan
tofu -chdir=opentofu apply
```

После первого запуска рабочих ВМ дожидаемся завершения Cloud-init
и проверяем доступность кэша:

```bash
sudo cloud-init status --wait
systemctl is-active qemu-guest-agent
ls -lh /var/cache/otus-packages/
```
