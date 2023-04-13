#!/bin/bash

###################################################################################
#
# NE LANCER QUE DANS UNE MACHINE VIRTUELLE
#
###################################################################################

# ADRESSE PASTEBIN
# https://pastebin.com/raw/hBYQ2Umm (lien github)
# ADRESSE GITHUB
# https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/scripts/install_script.sh

# Les variables

hostname=""
typeMachine=0   # 1=serveur web 1, 2=serveur web 2, 3=serveur temps, 4=serveur bdd, 5=load balancer, 6=routeur1, 7=routeur2, 8=client, 9=admin

efiPart="/dev/sda1"    # on sait que l'on a que des disques (durs) sata, pas de SSD NVMe /dev/nvme0n1(p1)
swapPart="/dev/sda2"
rootPart="/dev/sda3"
varPart="/dev/sda4"
homePart="/dev/sda5"

#paquetsCommuns="base base-devel linux linux-firmware sudo ssh gnupg ffmpegthumbnailer fd flake8 fzf grub efibootmgr htop i3-wm imv fakeroot kitty less tree mediainfo mktemp unzip tar man bsdtar bat pdftoppm glow w3m i3-wm jgmenu flex linux-headers lua-language-server man-db meson neofetch networkmanager nm-connection-editor nnn ripgrep pinentry trash-cli shellcheck python python-poetry pyright npm shellharden taplo-cli texinfo ttf-jetbrains-mono-nerd otf-fira-sans ttf-amiri adobe-source-han-sans-otc-fonts wget xorg-server xorg-xinit zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting virtualbox-guest-utils nvim"
#paquetsCommuns="base base-devel linux linux-firmware sudo grub efibootmgr man networkmanager virtualbox-guest-utils zsh zsh-completions zsh-syntax-highlighting"
paquetsServeurWeb="postgresql python-poetry"
paquetsServeurBDD="postgresql"
paquetsLoadBalancer="haproxy"

# Les fonctions

function choisirTypeInstallation()
{
    typeMachine="$(dialog --stdout --menu "Choisir type d'installation" 0 0 0 1 "Serveur web1" 2 "Serveur web2" 3 "Serveur temps" 4 "Serveur BDD" 5 "Load balancer" 6 "Client" 7 "Admin")"
    case $typeMachine in
        1)
            hostname="serveur-web1"
            ;;
        2)
            hostname="serveur-web2"
            ;;
        3)
            hostname="serveur-temps"
            ;;
        4)
            hostname="serveur-bdd"
            ;;
        5)
            hostname="serveur-load"
            ;;
        6)
            hostname="client"
            ;;
        7)
            hostname="admin"
            ;;
    esac
}

function preparerDisques()
{
    parted --script /dev/sda -- mklabel gpt \
        mkpart ESP fat32 1Mib 301MiB \
        set 1 boot on \
        mkpart primary linux-swap 301Mib 1255Mib \
        mkpart primary ext4 1255MiB 20329Mib \
        mkpart primary ext4 20329Mib 39403Mib \
        mkpart primary ext4 39403Mib 100%

    mkfs.fat -F32 "$efiPart"
    mkswap "$swapPart"
    mkfs.ext4 "$rootPart"
    mkfs.ext4 "$varPart"
    mkfs.ext4 "$homePart"

    mount "$rootPart" /mnt
    swapon "$swapPart"
    mount --mkdir "$efiPart" /mnt/efi
    mount --mkdir "$varPart" /mnt/var
    mount --mkdir "$homePart" /mnt/home
}

function installerPaquets()
{
    #pacstrap -K /mnt base base-devel linux linux-firmware
    pacstrap -K /mnt base base-devel linux linux-firmware sudo grub efibootmgr mkinitcpio man networkmanager virtualbox-guest-utils zsh zsh-completions zsh-syntax-highlighting neovim git ntp
}

function configurerSysteme()
{
    genfstab -U /mnt >> /mnt/etc/fstab
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    arch-chroot /mnt hwclock --systohc
    arch-chroot /mnt printf "en_GB.UTF-8 UTF-8\nen_US.UTF-8 UTF-8\nfr_FR.UTF-8 UTF-8" > /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    arch-chroot /mnt echo "LANG=en_GB.UTF-8" > /mnt/etc/locale.conf
    arch-chroot /mnt echo "KEYMAP=fr-latin9" > /mnt/etc/vconsole.conf
    arch-chroot /mnt echo "$hostname" > /mnt/etc/hostname

    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    arch-chroot /mnt printf "GRUB_DEFAULT=0\nGRUB_TIMEOUT=5\nGRUB_DISTRIBUTOR=\"Arch\"\nGRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"\nGRUB_CMDLINE_LINUX=\"\"\nGRUB_PRELOAD_MODULES=\"part_gpt part_msdos\"\nGRUB_TIMEOUT_STYLE=menu\nGRUB_TERMINAL_INPUT=console\nGRUB_GFXMODE=640*480*32\nGRUB_GFXPAYLOAD_LINUX=keep\nGRUB_DISABLE_RECOVERY=true\nGRUB_DISABLE_OS_PROBER=true" > /mnt/etc/default/grub

    arch-chroot /mnt useradd -mU -s /usr/bin/zsh -G vboxsf,wheel "admin"
    arch-chroot /mnt chsh -s /usr/bin/zsh
    ######################################### danger ############################################
    echo "admin:master" | chpasswd --root /mnt   
    echo "root:master" | chpasswd --root /mnt   
    echo "root ALL=(ALL) NOPASSWD:ALL" >> /mnt/etc/sudoers.d/99_sudo_include_file
    echo "%wheel ALL=(ALL:ALL) ALL" >> /mnt/etc/sudoers.d/99_sudo_include_file

    arch-chroot /mnt systemctl enable NetworkManager.service
    arch-chroot /mnt systemctl start NetworkManager.service
    arch-chroot /mnt printf "[main]\nno-auto-default=enp0s8,enp0s9" > /mnt/etc/NetworkManager/conf.d/00-configuration.conf
}

function installerPaquetsPropres()
{
        case $typeMachine in
        1)
            arch-chroot /mnt pacman -S --noconfirm "$paquetsServeurWeb"
            ;;
        2)
            arch-chroot /mnt pacman -S --noconfirm "$paquetsServeurWeb"
            ;;
        3)
            ;;
        4)
            arch-chroot /mnt pacman -S --noconfirm "$paquetsServeurBDD"
            ;;
        5)
            arch-chroot /mnt pacman -S --noconfirm "$paquetsLoadBalancer"
            ;;
        6)
            ;;
        7)
            ;;
    esac
}

function configurerVirtualBoxGuest()
{
    # Chargement des modules de Virtual Box au démarrage.
    arch-chroot /mnt VBoxClient-all
    arch-chroot /mnt systemctl enable vboxservice.service
}

# Le programme principal

timedatectl
pacman -Sy --noconfirm dialog
choisirTypeInstallation
preparerDisques
installerPaquets
configurerSysteme
installerPaquetsPropres
configurerVirtualBoxGuest

umount -R /mnt
reboot
