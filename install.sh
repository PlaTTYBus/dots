#!/usr/bin/env bash

# CREDITS: Yoinked by Iynaix (https://github.com/iynaix/dotfiles/blob/main/install.sh)
# Changes I made:
# - Check for blkdiscard support and skip if not supported
# - Export zpool at the end of the script to avoid "device busy" errors when rebooting
# - Changed the installation workflow to:
#   1. Clone the flake into tmp dir
#   2. Install NixOS using the flake and the selected host from tmp dir
#   3. Find the flake.nix file and extract the username from it
#   4. Move the flake into /home/<username>/projects/dots
#   5. Fix ownership of the flake directory to the user

# bash <(curl -L https://raw.githubusercontent.com/plattybus/dots/main/install.sh)
# nix eval '.#nixosConfigurations.vmware.config.services.desktopManager.plasma6.enable'


set -o errexit
set -o nounset
set -o pipefail

function yesno() {
    local prompt="$1"

    while true; do
        read -rp "$prompt [y/n] " yn
        case $yn in
            [Yy]* ) echo "y"; return;;
            [Nn]* ) echo "n"; return;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# in a vm, special case
if [[ -b "/dev/vda" ]]; then
    DISK="/dev/vda"
else
    # listing with the standard lsblk to help with viewing partitions
    lsblk

    # Get the list of disks
    mapfile -t disks < <(lsblk -ndo NAME,SIZE,MODEL)

    echo -e "\nAvailable disks:\n"
    for i in "${!disks[@]}"; do
        printf "%d) %s\n" $((i+1)) "${disks[i]}"
    done

    # Get user selection
    while true; do
        echo ""
        read -rp "Enter the number of the disk to install to: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#disks[@]} ]; then
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    # Get the selected disk
    DISK="/dev/$(echo "${disks[$selection-1]}" | awk '{print $1}')"
fi

# if disk contains "nvme", append "p" to partitions
if [[ "$DISK" =~ "nvme" ]]; then
    BOOTDISK="${DISK}p3"
    SWAPDISK="${DISK}p2"
    ZFSDISK="${DISK}p1"
else
    BOOTDISK="${DISK}3"
    SWAPDISK="${DISK}2"
    ZFSDISK="${DISK}1"
fi

echo "Boot Partition: $BOOTDISK"
echo "SWAP Partition: $SWAPDISK"
echo "ZFS Partition: $ZFSDISK"

echo ""
do_format=$(yesno "This irreversibly formats the entire disk. Are you sure?")
if [[ $do_format == "n" ]]; then
    exit
fi

echo "Creating partitions"

DISCARD_MAX=$(cat "/sys/block/$(basename "$DISK")/queue/discard_max_bytes")
if [ "$DISCARD_MAX" -gt 0 ]; then
    echo "Discard supported on $DISK. Running blkdiscard..."
    sudo blkdiscard -f "$DISK"
else
    echo "Discard not supported on $DISK. Skipping blkdiscard."
fi

sudo sgdisk --clear "$DISK"

sudo sgdisk -n3:1M:+1G -t3:EF00 "$DISK"
sudo sgdisk -n2:0:+16G -t2:8200 "$DISK"
sudo sgdisk -n1:0:0 -t1:BF01 "$DISK"

# notify kernel of partition changes
sudo sgdisk -p "$DISK" > /dev/null
sleep 5

echo "Creating Swap"
sudo mkswap "$SWAPDISK" --label "SWAP"
sudo swapon "$SWAPDISK"

echo "Creating Boot Disk"
sudo mkfs.fat -F 32 "$BOOTDISK" -n NIXBOOT

# setup encryption
echo "Available hosts:"
hosts=("desktop" "tuxedo" "vmware")
for i in "${!hosts[@]}"; do
    printf "%d) %s\n" $((i + 1)) "${hosts[i]}"
done

while true; do
    echo
    read -rp "Enter the number of the host to install: " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] &&
       (( selection >= 1 && selection <= ${#hosts[@]} )); then
        host="${hosts[$((selection - 1))]}"
        break
    fi
    echo "Invalid selection."
done

case "$host" in
    desktop|tuxedo)
        echo "Encryption enabled for $host"
        encryption_options=(-O encryption=aes-256-gcm -O keyformat=passphrase -O keylocation=prompt)
        ;;
    *)
        echo "Encryption disabled for $host"
        encryption_options=()
        ;;
esac

echo "Creating base zpool"
sudo zpool create -f \
    -o ashift=12 \
    -o autotrim=on \
    -O compression=zstd \
    -O acltype=posixacl \
    -O atime=off \
    -O xattr=sa \
    -O normalization=formD \
    -O mountpoint=none \
    "${encryption_options[@]}" \
    zroot "$ZFSDISK"

# NOTE: legacy mounts are used so they can be managed by fstab and swapped out via nixos configuration, e.g. for tmpfs
echo "Creating /"
sudo zfs create -o mountpoint=legacy zroot/root
sudo zfs snapshot zroot/root@blank
sudo mount -t zfs zroot/root /mnt

# create the boot partition after creating root
echo "Mounting /boot (efi)"
sudo mount --mkdir "$BOOTDISK" /mnt/boot

echo "Creating /nix"
sudo zfs create -o mountpoint=legacy zroot/nix
sudo mount --mkdir -t zfs zroot/nix /mnt/nix

echo "Creating /cache"
sudo zfs create -o mountpoint=legacy zroot/cache
sudo mount --mkdir -t zfs zroot/cache /mnt/cache

echo "Creating /home"
sudo zfs create -o mountpoint=legacy zroot/home
sudo mount --mkdir -t zfs zroot/home /mnt/home

echo "Creating /tank"
sudo zfs create -o mountpoint=legacy zroot/tank
sudo mount --mkdir -t zfs zroot/tank /mnt/tank

echo "Installing NixOS..."
sudo nixos-install --no-root-password --option extra-experimental-features "pipe-operators" --flake "github:PlaTTYBus/dots#$host" --option tarball-ttl 0
# sudo nixos-install --no-root-password --option extra-experimental-features "pipe-operators" --flake "/mnt/home/pviel/projects/dots#vmware" --option tarball-ttl 0

# sops-nix needs the age key on first boot to decrypt the user passwords, otherwise no user can log in
echo ""
echo "Setting up the sops age key"
user="pviel"
age_dir="/mnt/home/$user/.config/sops/age"
age_keyfile="$age_dir/keys.txt"

# owner as created by nixos-install, fall back to the defaults for the first normal user
uid=$(awk -F: -v u="$user" '$1 == u { print $3 }' /mnt/etc/passwd 2>/dev/null)
gid=$(awk -F: -v u="$user" '$1 == u { print $4 }' /mnt/etc/passwd 2>/dev/null)
uid=${uid:-1000}
gid=${gid:-100}

while true; do
    # -s hides the key while typing / pasting
    read -rsp "Paste the age secret key (AGE-SECRET-KEY-1...), leave empty to skip: " age_key
    echo ""
    # strip surrounding whitespace from pasting
    age_key=$(echo "$age_key" | tr -d '[:space:]')

    if [[ -z "$age_key" ]]; then
        echo "WARNING: no age key saved, secrets (including user passwords) will fail to decrypt on boot."
        echo "Copy the key to $age_keyfile before rebooting."
        break
    fi

    if [[ "$age_key" =~ ^AGE-SECRET-KEY-1[0-9A-Z]{58}$ ]]; then
        # the home directory does not exist yet before first boot, so create the whole tree with the user as owner
        for dir in "/mnt/home/$user" "/mnt/home/$user/.config" "/mnt/home/$user/.config/sops" "$age_dir"; do
            sudo install -d -m 700 -o "$uid" -g "$gid" "$dir"
        done
        # umask so the key is never readable by others, not even briefly
        (umask 077 && printf '%s\n' "$age_key" | sudo tee "$age_keyfile" > /dev/null)
        sudo chown "$uid:$gid" "$age_keyfile"
        sudo chmod 600 "$age_keyfile"
        unset age_key
        echo "Saved age key to $age_keyfile"
        break
    fi

    echo "Invalid age key, it should look like AGE-SECRET-KEY-1 followed by 58 characters. Please try again."
done

echo ""
echo "Installation complete. It is safe to reboot now."
sudo umount -R /mnt
sudo zpool export zroot