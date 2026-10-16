<div align="center">

# dots

**A multi-host NixOS flake with a dynamically themed Wayland desktop**

[![NixOS](https://img.shields.io/badge/NixOS-unstable-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![Flakes](https://img.shields.io/badge/Nix-flakes-7EBAE4?style=for-the-badge&logo=snowflake&logoColor=white)](https://wiki.nixos.org/wiki/Flakes)
[![Wayland](https://img.shields.io/badge/Wayland-umbriel-FFBC00?style=for-the-badge&logo=wayland&logoColor=black)](https://github.com/noctalia-dev/umbriel)
[![Secrets](https://img.shields.io/badge/secrets-sops--nix-2E3440?style=for-the-badge&logo=gnuprivacyguard&logoColor=white)](https://github.com/Mic92/sops-nix)

</div>

---

## Features

### System
- **Multiple hosts from one flake**: a desktop, a laptop and a VMware VM share the same modules
- **Feature flags**: modules are enabled per host through tags (`gui`, `wm`, `laptop`, `vm`) with [lamina](https://github.com/iynaix/lamina)
- **ZFS on root**: zstd compression, autotrim, monthly scrubs and optional native encryption (desktop and laptop)
- **Automatic snapshots with rotation**: [sanoid](https://github.com/jimsalterjrs/sanoid) snapshots `/home` (hourly, daily, weekly, monthly) and `/tank`
- **Secrets with [sops-nix](https://github.com/Mic92/sops-nix)**: user passwords, SSH keys and GitHub tokens are encrypted with age and decrypted at boot
- **Pinned inputs with [tack](https://github.com/manic-systems/tack)**: inputs are pinned in `.tack/` instead of `flake.lock`, with support for patching inputs (`patcher.nix`)
- **One-command installer**: partitions, formats, installs, deploys the age key and clones this repo (see [Installation](#installation))

### Desktop
- **[Umbriel](https://github.com/noctalia-dev/umbriel)**: a scrolling Wayland compositor, configured entirely from Nix
- **[Noctalia shell](https://github.com/noctalia-dev/noctalia)**: bar, launcher, control center, notifications, lock screen and the noctalia greeter with autologin
- **Dynamic colorschemes**: noctalia derives a color palette from the wallpaper and applies it everywhere:
  - GTK theme (recolored Tokyo Night), Tela icons and the Simp1e cursor
  - Qt through qt5ct/qt6ct and Kvantum
  - Ghostty, btop, cava, yazi and umbriel itself
- **Ghostty as a background service**: windows open instantly, and the terminal keeps running when the last window is closed
- **Wallpapers** are picked from `~/Pictures/Wallpapers` and rotate automatically

### User environment
- **[hjem](https://github.com/feel-co/hjem) + [hjem-rum](https://github.com/snugnug/hjem-rum)** instead of home-manager to manage dotfiles
- **Wrapped programs** with [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules): fish, git, starship and more carry their config with them
- **Neovim** configured with [nvf](https://github.com/notashelf/nvf)
- **Starship prompt** showing host, directory, git status, last command duration and local IP
- **Git over HTTPS** authenticated with a GitHub token from sops, so no SSH passphrases

### Hosts

| Host      | Type    | Tags                    | Disk encryption |
| --------- | ------- | ----------------------- | --------------- |
| `desktop` | Desktop | `gui` `wm`              | yes             |
| `tuxedo`  | Laptop  | `gui` `wm` `laptop`     | yes             |
| `vmware`  | VM      | `gui` `wm` `vm`         | no              |

The `vm` tag applies VMware-specific fixes: a patched wlroots for the `vmwgfx` driver, a software cursor and `Alt` as the modifier key.

---

## Installation

> [!WARNING]
> The installer **wipes the entire selected disk**.

### Prerequisites

- A UEFI machine or VM, booted from a [NixOS ISO](https://nixos.org/download/)
- A working internet connection
- Your **age secret key** (`AGE-SECRET-KEY-1…`) to decrypt the secrets. It is the private key line from `~/.config/sops/age/keys.txt` on an existing machine.

> [!TIP]
> To install over SSH, which makes pasting the age key easier, set a password for the live user with `passwd` and connect with `ssh nixos@<ip>`.

### Run the installer

```sh
bash <(curl -L https://raw.githubusercontent.com/plattybus/dots/main/install.sh)
```

### What `install.sh` does

1. **Selects the disk.** In a VM with `/dev/vda` it is chosen automatically, otherwise you pick one from a list.
2. **Asks for confirmation** before anything is written.
3. **Wipes the disk.** `blkdiscard` runs when the disk supports it.
4. **Partitions the disk** (GPT, `p` suffix for NVMe):

   | Partition | Size      | Type       | Label     |
   | --------- | --------- | ---------- | --------- |
   | 3         | 1 GiB     | EFI (vfat) | `NIXBOOT` |
   | 2         | 16 GiB    | swap       | `SWAP`    |
   | 1         | remainder | ZFS        |           |

5. **Creates swap and the boot filesystem.**
6. **Selects the host** to install. `desktop` and `tuxedo` get native ZFS encryption; you set the passphrase here and enter it on every boot.
7. **Creates the `zroot` pool** with `ashift=12`, zstd compression, autotrim, POSIX ACLs and `atime=off`.
8. **Creates and mounts the datasets** (all legacy mounts, managed by NixOS):

   | Dataset       | Mountpoint | Purpose                                                    |
   | ------------- | ---------- | ---------------------------------------------------------- |
   | `zroot/root`  | `/`        | root, with an empty `@blank` snapshot                      |
   | `zroot/nix`   | `/nix`     | the Nix store                                              |
   | `zroot/cache` | `/cache`   | caches that are never snapshotted                          |
   | `zroot/home`  | `/home`    | home directories, snapshotted by sanoid                    |
   | `zroot/tank`  | `/tank`    | bulk data, snapshotted by sanoid                           |

9. **Installs NixOS** with `nixos-install` from `github:PlaTTYBus/dots#<host>`.
10. **Reads the username** from the flake (`specialArgs.user` in `flake.nix`). If that fails, it asks for it.
11. **Asks for your age key** (input is hidden) and saves it to `~/.config/sops/age/keys.txt` on the new system, owned by the user with mode `600`. Without it, sops can't decrypt the user passwords and you can't log in.
12. **Clones this repo** to `~/projects/dots` over HTTPS, so `/etc/nixos`, `nh` and the `dots` alias work right away.
13. **Unmounts everything and exports the pool**, so the reboot is clean.

Reboot. You are logged in automatically and land in umbriel.

---

## Usage

| Task                         | Command                                                     |
| ---------------------------- | ----------------------------------------------------------- |
| Rebuild the current host     | `nh os switch`                                              |
| Rebuild a specific host      | `sudo nixos-rebuild switch --flake ~/projects/dots#<host>`  |
| Update all inputs            | `tack update`                                               |
| Edit secrets                 | `sops modules/hosts/secrets.json`                           |
| Format all Nix files         | `nix fmt`                                                   |
| Show a program's final config| `<program>-config`, e.g. `umbriel-config` (see `config-list`) |
| Jump to the flake            | `dots`                                                      |

### Adding a secret

1. Run `sops modules/hosts/secrets.json` and add the new key.
2. Declare it in a module: `sops.secrets.<name>.owner = user;`
3. Use it through `config.sops.secrets.<name>.path`. Secrets are decrypted to `/run/secrets` at boot.

### Adding a host

1. Create `modules/hosts/<name>/` with a `default.nix` and a `hardware.nix`. Use `nixos-generate-config --no-filesystems --show-hardware-config` on the new machine for the hardware part.
2. Add the host with its tags to `hostInfo` and `nixosConfigurations` in `flake.nix`.
3. Add it to the `hosts` list in `install.sh`, and to the encryption case if it should be encrypted.
4. Push, then install with the steps above.

---

## Repository layout

```
.
├── flake.nix            # hosts, tags and flake outputs
├── inputs-patched.nix   # pinned inputs with patches applied
├── install.sh           # installer
├── lib.nix              # helper functions (lib.custom)
├── .tack/               # input pins managed by tack
├── patches/             # patches for flake inputs
└── modules/
    ├── hosts/           # per-host config and encrypted secrets.json
    ├── gui/             # umbriel, noctalia, ghostty, gtk, qt, ...
    ├── shell/           # fish, git, neovim, starship, nix settings, ...
    ├── hardware/        # audio, bluetooth, gpu, monitors, ...
    └── *.nix            # system-wide modules (zfs, sops, users, ssh, ...)
```

---

## Credits

This configuration is heavily inspired by and partly based on **[iynaix/dotfiles](https://github.com/iynaix/dotfiles)** by [@iynaix](https://github.com/iynaix). Thank you for sharing such a well-structured setup. In particular:

- **`install.sh`**: the partitioning and ZFS layout come from his installer
- **[lamina](https://github.com/iynaix/lamina)**: the module system behind the per-host tags
- **`lib.nix`** and **`print-config`**: helper functions and the `<program>-config` commands
- **The umbriel, noctalia and dynamic theming setup**, plus [focal](https://github.com/iynaix/focal), [wfetch](https://github.com/iynaix/wfetch) and the Helium package

Also built on the work of:

- [noctalia-dev](https://github.com/noctalia-dev) for umbriel and the noctalia shell
- [Mic92/sops-nix](https://github.com/Mic92/sops-nix), [feel-co/hjem](https://github.com/feel-co/hjem), [snugnug/hjem-rum](https://github.com/snugnug/hjem-rum) and [BirdeeHub/nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules)
- [jfly/flake-input-patcher](https://github.com/jfly/flake-input-patcher), which `patcher.nix` is adapted from
