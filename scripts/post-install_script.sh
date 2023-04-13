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
        "admin")
            ;;
    esac
}

function deployerServeurWeb()
{
    sudo mkdir /serv
    sudo chown "$USER:$USER" /serv
    cd /serv || exit
    git clone https://github.com/yannmazita/example-server.git
    cd example-server || exit
    echo "SECRET_KEY = '$(openssl rand -hex 40)'" > src/my_website/.env
    poetry install
    poetry run python src/my_website/manage.py migrate
    poetry run python src/my_website/manage.py runserver 0.0.0.0:8000 &
}

function configurationsPropres()
{
    case $(cat /etc/hostname) in
        "serveur-web1")
            sudo curl "https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/config/serveur-web1/etc/ntp.conf" -o /etc/ntp.conf
            sudo systemctl start ntpd.service
            sudo systemctl enable ntpd.service

            deployerServeurWeb
            ;;
        "serveur-web2")
            sudo curl "https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/config/serveur-web2/etc/ntp.conf" -o /etc/ntp.conf
            sudo systemctl start ntpd.service
            sudo systemctl enable ntpd.service

            deployerServeurWeb
            ;;
        "serveur-temps")
            sudo curl "https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/config/serveur-temps/etc/ntp.conf" -o /etc/ntp.conf
            sudo systemctl start ntpd.service
            sudo systemctl enable ntpd.service
            ;;
        "serveur-bdd")
            cd /tmp || exit # parce que postgre envoie un message d'erreur inutile
            sudo su postgres -c "initdb -D /var/lib/postgres/data --data-checksums"
            sudo curl "https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/config/serveur-bdd/var/lib/postgres/data/pg_hba.conf" -o /var/lib/postgres/data/pg_hba.conf
            sudo curl "https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/config/serveur-bdd/var/lib/postgres/data/postgresql.conf" -o /var/lib/postgres/data/postgresql.conf
            sudo systemctl start postgresql.service
            sudo systemctl enable postgresql.service
            sudo su postgres -c "createuser admin --superuser"
            sudo su postgres -c "createdb baseDeDonnees -O admin"

            sudo curl "https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/config/serveur-bdd/etc/ntp.conf" -o /etc/ntp.conf
            sudo systemctl start ntpd.service
            sudo systemctl enable ntpd.service
            ;;
        "serveur-load")
            sudo curl "https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/config/serveur-load/etc/haxproxy/haproxy.cfg" -o /etc/haproxy/haproxy.cfg
            sudo systemctl start haproxy.service
            sudo systemctl enable haproxy.service
            
            sudo curl "https://raw.githubusercontent.com/yannmazita/example-automated-arch-install/main/config/serveur-load/etc/ntp.conf" -o /etc/ntp.conf
            sudo systemctl start ntpd.service
            sudo systemctl enable ntpd.service
            ;;
        "admin")
            ;;
    esac
}

configurationsReseau
nmcli connection reload
installerPaquetsPostInstall
configurationsPropres

echo "OK !"
