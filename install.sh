#!/usr/bin/env bash

# CREDITS: Yoinked by Iynaix (https://github.com/iynaix/dotfiles/blob/main/install.sh)
# Changes I made:
# - Check for blkdiscard support and skip if not supported
# - Export zpool at the end of the script to avoid "device busy" errors when rebooting
# - Changed the installation workflow to:
#   1. Clone the flake into tmp dir
#   2. Install NixOS using the flake and the selected host from tmp dir
#   3. Find the nixos.nix file and extract the username from it
#   4. Move the flake into /persist/home/<username>/projects/dots
#   5. Fix ownership of the flake directory to the user

# sh <(curl -L https://raw.githubusercontent.com/plattybus/dots/main/install.sh)


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
use_encryption=$(yesno "Use encryption? (Encryption must also be enabled within host config with boot.zfs.requestEncryptionCredentials = true)")
if [[ $use_encryption == "y" ]]; then
    encryption_options=(-O encryption=aes-256-gcm -O keyformat=passphrase -O keylocation=prompt)
else
    encryption_options=()
fi

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

echo "Creating /persist"
sudo zfs create -o mountpoint=legacy zroot/persist
sudo mount --mkdir -t zfs zroot/persist /mnt/persist

repo="${repo:-github:PlaTTYBus/dots}"
hosts=("tuxedo" "vmware")

# tmpdir="$(mktemp -d)"

# echo "Cloning flake repository..."
# git clone "$repo" "$tmpdir"

echo "Available hosts:"
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

echo "Installing NixOS..."

sudo nixos-install --no-root-password --option extra-experimental-features "pipe-operators" --flake "$repo/${git_rev:-main}#$host" --option tarball-ttl 0

# nixos_file="$(find "$tmpdir" -name nixos.nix | head -n1)"
# sudo nixos-install --no-root-password --option extra-experimental-features "pipe-operators" --flake .#vmware --option tarball-ttl 0
# if [[ -z "$nixos_file" ]]; then
#     echo "Failed to locate nixos.nix"
#     exit 1
# fi
#
# username=$(
#     grep -m1 'user ? "' "$nixos_file" | cut -d'"' -f2
# )
#
# if [[ -z "$username" ]]; then
#     echo "Failed to determine username from $nixos_file"
#     exit 1
# fi

# target="/mnt/persist/home/$username/projects/dots"

# Remove this when preservation is introduced, as it will be handled by the flake itself
# echo "Creating target directory..."
# sudo mkdir -p "$(dirname "$target")"

# echo "Moving flake to $target..."
# sudo mv "$tmpdir" "$target"

# echo "Fixing ownership..."
# sudo chown -R 1000:100 "$target"

# echo "Unmounting partitions and exporting zpool"
# sudo umount -R /mnt
# sudo zpool export zroot

echo "Installation complete. It is now safe to reboot."