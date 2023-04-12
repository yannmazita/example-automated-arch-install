#!/bin/bash
# shellcheck disable=2317

# ADRESSE PASTEBIN
# https://pastebin.com/raw/GRYpUiK6
# ADRESSE GITHUB
# https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/scripts/post-install_script.sh

# Les variables

# Fonctions
function configurationsReseau()
{
    case $(cat /etc/hostname) in
        "serveur-web1")
            nmcli c add type ethernet con-name admin-net ifname enp0s8 ip4 192.168.0.3/24
            nmcli c add type ethernet con-name intra-net ifname enp0s9 ip4 192.168.2.3/24
            nmcli con up admin-net
            nmcli con up intra-net
            ;;
        "serveur-web2")
            nmcli c add type ethernet con-name admin-net ifname enp0s8 ip4 192.168.0.4/24
            nmcli c add type ethernet con-name intra-net ifname enp0s9 ip4 192.168.2.4/24
            nmcli con up admin-net
            nmcli con up intra-net
            ;;
        "serveur-temps")
            nmcli c add type ethernet con-name admin-net ifname enp0s8 ip4 192.168.0.6/24
            nmcli c add type ethernet con-name intra-net ifname enp0s9 ip4 192.168.2.6/24
            nmcli con up admin-net
            nmcli con up intra-net
            ;;
        "serveur-bdd")
            nmcli c add type ethernet con-name admin-net ifname enp0s8 ip4 192.168.0.5/24
            nmcli c add type ethernet con-name intra-net ifname enp0s9 ip4 192.168.2.5/24
            nmcli con up admin-net
            nmcli con up intra-net
            ;;
        "serveur-load")
            nmcli c add type ethernet con-name admin-net ifname enp0s8 ip4 192.168.0.2/24
            nmcli c add type ethernet con-name intra-net ifname enp0s9 ip4 192.168.2.2/24
            nmcli con up admin-net
            nmcli con up intra-net
            ;;
        "client")
            ;;
        "admin")
            nmcli c add type ethernet con-name admin-net ifname enp0s8 ip4 192.168.0.1/24
            nmcli con up admin-net
            ;;
    esac
}

function installerPaquetsPostInstall()
{
    case $(cat /etc/hostname) in
        "serveur-web1")
            ;;
        "serveur-web2")
            ;;
        "serveur-temps")
            ;;
        "serveur-bdd")
            ;;
        "serveur-load")
            ;;
        "client")
            ;;
        "admin")
            ;;
    esac
}

function configurationsPropes()
{
    case $(cat /etc/hostname) in
        "serveur-web1")
            systemctl enable postgresql.service
            systemctl start postgresql.service
            ;;
        "serveur-web2")
            systemctl enable postgresql.service
            systemctl start postgresql.service
            ;;
        "serveur-temps")
            ;;
        "serveur-bdd")
            cd /tmp || exit # parce que postgre envoie un message d'erreur inutile
            su postgres -c "initdb -D /var/lib/postgres/data --data-checksums"
            curl "https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/config/serveur-bdd/var/lib/postgres/data/pg_hba.conf" -o /var/lib/postgres/data/pg_hba.conf
            curl "https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/config/serveur-bdd/var/lib/postgres/data/postgresql.conf" -o /var/lib/postgres/data/postgresql.conf
            systemctl enable postgresql.service
            systemctl start postgresql.service
            su postgres -c "createuser admin --superuser"
            su postgres -c "createdb baseDeDonnees -O admin"
            systemctl restart postgresql.service
            ;;
        "serveur-load")
            systemctl enable haproxy.service
            ;;
        "client")
            ;;
        "admin")
            ;;
    esac

    systemctl restart postgresql.service
}

configurationsReseau
nmcli connection reload
installerPaquetsPostInstall
configurationsPropes
reboot
