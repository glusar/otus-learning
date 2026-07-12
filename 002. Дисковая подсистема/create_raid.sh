#!/usr/bin/env bash
set -e

echo "Enter RAID name: "
read RAID_NAME

echo "Enter the RAID level you want to create (only digit): "
read RAID_LEVEL

echo "Enter the disks (use a space to separate). Example: /dev/sdb /dev/sdc "
read -a RAID_DISK

echo "Enter RAID device, example: /dev/md0 "
read RAID_DEVICE

# Чистим диски
mdadm --zero-superblock --force ${RAID_DISK[@]}
wipefs --all --force ${RAID_DISK[@]}

mdadm --create --verbose "$RAID_DEVICE" --level="$RAID_LEVEL" --raid-devices="${#RAID_DISK[@]}" "${RAID_DISK[@]}"

while grep -qE 'resync|recovery' /proc/mdstat; do
    clear
    cat /proc/mdstat
    sleep 2
done

mkfs.ext4 $RAID_DEVICE
mkdir -p /mnt/$RAID_NAME
mount $RAID_DEVICE /mnt/$RAID_NAME

# Добавляем в mdadm.conf информацию о RAID и его идентификаторе
mdadm --detail --scan >> /etc/mdadm/mdadm.conf

# Добавление в fstab
UUID=$(blkid -s UUID -o value $RAID_DEVICE)
echo "UUID=$UUID $MOUNT_POINT ext4 defaults 0 0" >> /etc/fstab

echo "RAID successfully created!"
