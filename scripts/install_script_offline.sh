#!/bin/bash

###################################################################################
#
# NE LANCER QUE DANS UNE MACHINE VIRTUELLE
#
###################################################################################

# Les variables

hostname=""
typeMachine=0   # 1=serveur web 1, 2=serveur web 2, 3=serveur temps, 4=serveur bdd, 5=load balancer, 6=admin

efiPart="/dev/sda1"    # on sait que l'on a que des disques (durs) sata, pas de SSD NVMe /dev/nvme0n1(p1)
swapPart="/dev/sda2"
rootPart="/dev/sda3"
varPart="/dev/sda4"
homePart="/dev/sda5"

# Les fonctions

function choisirTypeMachine()
{
    while [[ ! $typeMachine =~ ^(1|2|3|4|5|6)$ ]]
    do
        echo "1) Serveur web 1, 2) Serveur web 2, 3) Serveur temps, 4) Serveur BDD, 5) Load Balancer, 6) Admin"
        # shellcheck disable=2162
        read -p "Choisir le type [1-6]: " typeMachine
    done

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
    case $typeMachine in
        1)
            pacstrap -K /mnt base base-devel linux linux-firmware sudo grub efibootmgr mkinitcpio man networkmanager virtualbox-guest-utils zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions neovim git ntp openssh gnupg postgresql python-poetry zabbix-agent
            ;;
        2)
            pacstrap -K /mnt base base-devel linux linux-firmware sudo grub efibootmgr mkinitcpio man networkmanager virtualbox-guest-utils zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions neovim git ntp openssh gnupg postgresql python-poetry zabbix-agent
            ;;
        3)
            pacstrap -K /mnt base base-devel linux linux-firmware sudo grub efibootmgr mkinitcpio man networkmanager virtualbox-guest-utils zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions neovim git ntp openssh gnupg zabbix-server zabbix-frontend-php mysql lighttpd php-legacy php-legacy-cgi php-legacy-gd fping
            ;;
        4)
            pacstrap -K /mnt base base-devel linux linux-firmware sudo grub efibootmgr mkinitcpio man networkmanager virtualbox-guest-utils zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions neovim git ntp openssh gnupg postgresql zabbix-agent
            ;;
        5)
            pacstrap -K /mnt base base-devel linux linux-firmware sudo grub efibootmgr mkinitcpio man networkmanager virtualbox-guest-utils zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions neovim git ntp openssh gnupg haproxy zabbix-agent
            ;;
        6)
            pacstrap -K /mnt base base-devel linux linux-firmware sudo grub efibootmgr mkinitcpio man networkmanager virtualbox-guest-utils zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions neovim git ntp openssh gnupg xfce4 xorg-server xorg-xinit
            ;;
    esac
}

function configurerSysteme()
{
    genfstab -U /mnt >> /mnt/etc/fstab
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    arch-chroot /mnt hwclock --systohc
    printf 'en_GB.UTF-8 UTF-8
en_US.UTF-8 UTF-8
fr_FR.UTF-8 UTF-8
' > /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=en_GB.UTF-8" > /mnt/etc/locale.conf
    echo "KEYMAP=fr-latin9" > /mnt/etc/vconsole.conf
    echo "$hostname" > /mnt/etc/hostname

    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    printf 'GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="Arch"
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
GRUB_CMDLINE_LINUX=""
GRUB_PRELOAD_MODULES="part_gpt part_msdos"
GRUB_TIMEOUT_STYLE=menu
GRUB_TERMINAL_INPUT=console
GRUB_GFXMODE=640*480*32
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_RECOVERY=true
GRUB_DISABLE_OS_PROBER=true
' > /mnt/etc/default/grub

    arch-chroot /mnt useradd -mU -s /usr/bin/zsh -G vboxsf,wheel "admin"
    arch-chroot /mnt chsh -s /usr/bin/zsh
    ######################################### danger ############################################
    echo "admin:master" | chpasswd --root /mnt   
    echo "root:master" | chpasswd --root /mnt   
    echo "@includedir /etc/sudoers.d" >> /mnt/etc/sudoers
    echo "%wheel ALL=(ALL:ALL) ALL" >> /mnt/etc/sudoers.d/99_sudo_include_file

    arch-chroot /mnt systemctl enable NetworkManager.service
    printf '[main]
no-auto-default=enp0s8,enp0s9
' > /mnt/etc/NetworkManager/conf.d/00-configuration.conf
}

configurerZsh()
{
    echo "# empty" > /mnt/home/admin/.zshrc
    arch-chroot /mnt chown admin:admin /home/admin/.zshrc
    case $(cat /mnt/etc/hostname) in
        "serveur-web1")
            #echo "#empty" > /mnt/home/admin/.zshrc
            cp /local_files/config/serveur-web1/etc/zsh/zshrc /mnt/etc/zsh/zshrc
            cp /local_files/config/serveur-web1/etc/zsh/zshenv /mnt/etc/zsh/zshenv
            cp /local_files/config/serveur-web1/etc/zsh/zsh_keybindings /mnt/etc/zsh/zsh_keybindings
            cp /local_files/config/serveur-web1/etc/zsh/zsh_programs /mnt/etc/zsh/zsh_programs
            ;;
        "serveur-web2")
            #echo "#empty" > /mnt/home/admin/.zshrc
            cp /local_files/config/serveur-web2/etc/zsh/zshrc /mnt/etc/zsh/zshrc
            cp /local_files/config/serveur-web2/etc/zsh/zshenv /mnt/etc/zsh/zshenv
            cp /local_files/config/serveur-web2/etc/zsh/zsh_keybindings /mnt/etc/zsh/zsh_keybindings
            cp /local_files/config/serveur-web2/etc/zsh/zsh_programs /mnt/etc/zsh/zsh_programs
            ;;
        "serveur-temps")
            #echo "#empty" > /mnt/home/admin/.zshrc
            cp /local_files/config/serveur-temps/etc/zsh/zshrc /mnt/etc/zsh/zshrc
            cp /local_files/config/serveur-temps/etc/zsh/zshenv /mnt/etc/zsh/zshenv
            cp /local_files/config/serveur-temps/etc/zsh/zsh_keybindings /mnt/etc/zsh/zsh_keybindings
            cp /local_files/config/serveur-temps/etc/zsh/zsh_programs /mnt/etc/zsh/zsh_programs
            ;;
        "serveur-bdd")
            #echo "#empty" > /mnt/home/admin/.zshrc
            cp /local_files/config/serveur-bdd/etc/zsh/zshrc /mnt/etc/zsh/zshrc
            cp /local_files/config/serveur-bdd/etc/zsh/zshenv /mnt/etc/zsh/zshenv
            cp /local_files/config/serveur-bdd/etc/zsh/zsh_keybindings /mnt/etc/zsh/zsh_keybindings
            cp /local_files/config/serveur-bdd/etc/zsh/zsh_programs /mnt/etc/zsh/zsh_programs
            ;;
        "serveur-load")
            #echo "#empty" > /mnt/home/admin/.zshrc
            cp /local_files/config/serveur-load/etc/zsh/zshrc /mnt/etc/zsh/zshrc
            cp /local_files/config/serveur-load/etc/zsh/zshenv /mnt/etc/zsh/zshenv
            cp /local_files/config/serveur-load/etc/zsh/zsh_keybindings /mnt/etc/zsh/zsh_keybindings
            cp /local_files/config/serveur-load/etc/zsh/zsh_programs /mnt/etc/zsh/zsh_programs
            ;;
        "admin")
            cp /local_files/config/serveur-web1/etc/zsh/zshrc /mnt/etc/zsh/zshrc
            cp /local_files/config/serveur-web1/etc/zsh/zshenv /mnt/etc/zsh/zshenv
            cp /local_files/config/serveur-web1/etc/zsh/zsh_keybindings /mnt/etc/zsh/zsh_keybindings
            cp /local_files/config/serveur-web1/etc/zsh/zsh_programs /mnt/etc/zsh/zsh_programs
            ;;
    esac
}

function configurationsPropres()
{
    mkdir /mnt/home/admin/bin
    case $typeMachine in
        1)
            echo "export DJANGO_SUPERUSER_USERNAME='admin'" >> /mnt/etc/zsh/zshenv
            echo "export DJANGO_SUPERUSER_PASSWORD='master'" >> /mnt/etc/zsh/zshenv
            echo "export DJANGO_SUPERUSER_EMAIL='admin@admin.admin'" >> /mnt/etc/zsh/zshenv
            arch-chroot /mnt chmod u+x /home/admin/bin/{migrate_server,run_server}
            ;;
        2)
            echo "export DJANGO_SUPERUSER_USERNAME='admin'" >> /mnt/etc/zsh/zshenv
            echo "export DJANGO_SUPERUSER_PASSWORD='master'" >> /mnt/etc/zsh/zshenv
            echo "export DJANGO_SUPERUSER_EMAIL='admin@admin.admin'" >> /mnt/etc/zsh/zshenv
            arch-chroot /mnt chmod u+x /home/admin/bin/{migrate_server,run_server}
            ;;
    esac
}

function configurerVirtualBoxGuest()
{
    # Chargement des modules de Virtual Box au démarrage.
    arch-chroot /mnt VBoxClient-all
    arch-chroot /mnt systemctl enable vboxservice.service
}

function preparerPostInstallation()
{
    echo "exec bash /home/admin/post-install_script.sh" >> /mnt/etc/zsh/zprofile
    # shellcheck disable=2016
    cp /local_files/scripts/post-install_script_offline.sh /mnt/home/admin/
    arch-chroot /mnt chmod u+x /home/admin/post-install_script_offline.sh

    echo "0" > /mnt/etc/post-install
}

# Le programme principal

timedatectl
choisirTypeMachine
preparerDisques
installerPaquets
configurerSysteme
configurerZsh
configurationsPropres
configurerVirtualBoxGuest
preparerPostInstallation

cp -r /local_files /mnt/
cp -r /local_files/config/serveur-web1/admin/bin /mnt/home/admin/
arch-chroot /mnt chmod u+x /home/admin/bin/{migrate_server,run_server}
arch-chroot /mnt chown -R admin:admin /home/admin/
umount -R /mnt
reboot
