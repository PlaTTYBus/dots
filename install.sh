#!/usr/bin/env bash

# CREDITS: Yoinked by Iynaix (https://github.com/iynaix/dotfiles/blob/main/install.sh)
# Changes I made:
# - Check for blkdiscard support and skip if not supported
# - Encrypt the pool only for the desktop and tuxedo hosts
# - Create the media datasets from the flake (custom.zfs.tank), on a second disk for hosts with their own tank pool
# - Export zpool at the end of the script to avoid "device busy" errors when rebooting
# - After nixos-install:
#   1. Read the username from the flake
#   2. Save the pasted sops age key to /home/<username>/.config/sops/age/keys.txt
#   3. Clone the flake into /home/<username>/projects/dots
# See README.md for a step by step description

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

# nvme partitions have a "p" between disk and number
function part() {
    if [[ "$1" =~ "nvme" ]]; then
        echo "${1}p$2"
    else
        echo "${1}$2"
    fi
}

# prints the selected disk, the optional second argument is left out of the list
function select_disk() {
    local prompt="$1"
    local exclude="${2:-}"
    local disks=()
    local line selection

    while read -r line; do
        [[ "/dev/${line%% *}" == "$exclude" ]] || disks+=("$line")
    done < <(lsblk -ndo NAME,SIZE,MODEL)

    echo -e "\nAvailable disks:\n" >&2
    for i in "${!disks[@]}"; do
        printf "%d) %s\n" $((i+1)) "${disks[i]}" >&2
    done

    while true; do
        echo "" >&2
        read -rp "$prompt: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#disks[@]} ]; then
            break
        fi
        echo "Invalid selection. Please try again." >&2
    done

    echo "/dev/$(echo "${disks[$selection-1]}" | awk '{print $1}')"
}

function wipe_disk() {
    local disk="$1"

    DISCARD_MAX=$(cat "/sys/block/$(basename "$disk")/queue/discard_max_bytes")
    if [ "$DISCARD_MAX" -gt 0 ]; then
        echo "Discard supported on $disk. Running blkdiscard..."
        sudo blkdiscard -f "$disk"
    else
        echo "Discard not supported on $disk. Skipping blkdiscard."
    fi

    sudo sgdisk --clear "$disk"
}

flake="github:PlaTTYBus/dots"
nix_eval=(nix eval --raw --extra-experimental-features "nix-command flakes pipe-operators" --option tarball-ttl 0)

# the host decides about encryption and whether the media datasets get their own disk
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

echo "Reading the tank pool of $host from the flake"
tank_pool=$("${nix_eval[@]}" "$flake#nixosConfigurations.$host.config.custom.zfs.tank.pool")
echo "Tank pool: $tank_pool"

# in a vm, special case
if [[ -b "/dev/vda" ]]; then
    DISK="/dev/vda"
else
    # listing with the standard lsblk to help with viewing partitions
    lsblk
    DISK=$(select_disk "Enter the number of the disk to install to")
fi

BOOTDISK=$(part "$DISK" 3)
SWAPDISK=$(part "$DISK" 2)
ZFSDISK=$(part "$DISK" 1)

echo "Boot Partition: $BOOTDISK"
echo "SWAP Partition: $SWAPDISK"
echo "ZFS Partition: $ZFSDISK"

# any other pool than zroot lives on its own disk
if [[ "$tank_pool" != "zroot" ]]; then
    TANKDISK=$(select_disk "Enter the number of the disk for the $tank_pool pool" "$DISK")
    TANKZFSDISK=$(part "$TANKDISK" 1)
    echo "$tank_pool Partition: $TANKZFSDISK"
fi

echo ""
do_format=$(yesno "This irreversibly formats $DISK${TANKDISK:+ and $TANKDISK}. Are you sure?")
if [[ $do_format == "n" ]]; then
    exit
fi

echo "Creating partitions"

wipe_disk "$DISK"
sudo sgdisk -n3:1M:+1G -t3:EF00 "$DISK"
sudo sgdisk -n2:0:+16G -t2:8200 "$DISK"
sudo sgdisk -n1:0:0 -t1:BF01 "$DISK"

if [[ -n "${TANKDISK:-}" ]]; then
    wipe_disk "$TANKDISK"
    sudo sgdisk -n1:0:0 -t1:BF01 "$TANKDISK"
fi

# notify kernel of partition changes
sudo sgdisk -p "$DISK" > /dev/null
sleep 5

echo "Creating Swap"
sudo mkswap "$SWAPDISK" --label "SWAP"
sudo swapon "$SWAPDISK"

echo "Creating Boot Disk"
sudo mkfs.fat -F 32 "$BOOTDISK" -n NIXBOOT

pool_options=(
    -o ashift=12
    -o autotrim=on
    -O compression=zstd
    -O acltype=posixacl
    -O atime=off
    -O xattr=sa
    -O normalization=formD
    -O mountpoint=none
)

echo "Creating base zpool"
sudo zpool create -f "${pool_options[@]}" "${encryption_options[@]}" zroot "$ZFSDISK"

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

if [[ "$tank_pool" != "zroot" ]]; then
    echo "Creating the $tank_pool pool"
    tank_options=()
    if [[ ${#encryption_options[@]} -gt 0 ]]; then
        # a key file on the encrypted zroot unlocks the pool at boot, so there is only one passphrase
        key="/etc/zfs/keys/$tank_pool.key"
        sudo install -d -m 700 /mnt/etc/zfs/keys
        sudo dd if=/dev/urandom of="/mnt$key" bs=32 count=1 status=none
        sudo chmod 400 "/mnt$key"
        tank_options=(-O encryption=aes-256-gcm -O keyformat=raw -O keylocation="file:///mnt$key")
    fi
    sudo zpool create -f "${pool_options[@]}" "${tank_options[@]}" "$tank_pool" "$TANKZFSDISK"
    if [[ -n "${key:-}" ]]; then
        # the key is only below /mnt during the install
        sudo zfs set keylocation="file://$key" "$tank_pool"
    fi
fi

# the datasets are mounted into the home directory on boot, see modules/zfs.nix
echo "Creating the tank datasets"
tank_script=$("${nix_eval[@]}" "$flake#nixosConfigurations.$host.config.custom.zfs.tank.createScript")
sudo bash -euo pipefail -c "$tank_script"

echo "Installing NixOS..."
sudo nixos-install --no-root-password --option extra-experimental-features "pipe-operators" --flake "$flake#$host" --option tarball-ttl 0
# sudo nixos-install --no-root-password --option extra-experimental-features "pipe-operators" --flake "/mnt/home/pviel/projects/dots#vmware" --option tarball-ttl 0

# sops-nix needs the age key on first boot to decrypt the user passwords, otherwise no user can log in
echo ""
echo "Setting up the sops age key"

# read the username from the specialArgs set in flake.nix, the flake is already fetched by nixos-install
if ! user=$("${nix_eval[@]}" "$flake#nixosConfigurations.$host._module.specialArgs.user"); then
    read -rp "Could not read the username from the flake, please enter it: " user
fi
echo "Using user: $user"

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

# clone the flake so it is ready at ~/projects/dots (/etc/nixos and nh point there)
echo ""
dots_dir="/mnt/home/$user/projects/dots"
if [[ -e "$dots_dir" ]]; then
    echo "$dots_dir already exists, skipping clone"
else
    echo "Cloning flake to $dots_dir"
    sudo install -d -m 700 -o "$uid" -g "$gid" "/mnt/home/$user"
    sudo install -d -m 755 -o "$uid" -g "$gid" "/mnt/home/$user/projects"
    # fall back to git from nixpkgs in case the iso does not ship it
    git_cmd=(git)
    if ! command -v git >/dev/null 2>&1; then
        git_cmd=(nix shell --extra-experimental-features "nix-command flakes" nixpkgs#git -c git)
    fi
    # clone over https, pushing after boot authenticates with the github token from sops (see github.nix)
    sudo "${git_cmd[@]}" clone https://github.com/PlaTTYBus/dots "$dots_dir"
    sudo chown -R "$uid:$gid" "$dots_dir"
fi

echo ""
echo "Installation complete. It is safe to reboot now."
sudo umount -R /mnt
sudo zpool export zroot
if [[ "$tank_pool" != "zroot" ]]; then
    sudo zpool export "$tank_pool"
fi