#!/bin/bash
# shellcheck disable=2317

# Fonctions

function verifierPostInstall()
{
    if (( $(cat /etc/post-install) == 1 ))
    then
        exit
    fi 
}

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
    poetry run python src/my_website/manage.py createsuperuser --noinput
    # shellcheck disable=2164
    cd
}

function configurationsPropres()
{
    case $(cat /etc/hostname) in
        "serveur-web1")
            sudo cp /local_files/config/serveur-web1/etc/ntp.conf /etc/ntp.conf
            sudo systemctl start ntpd.service
            sudo systemctl enable ntpd.service

            deployerServeurWeb

            sudo cp /local_files/config/serveur-web1/etc/systemd/system/gunicorn.service
            sudo systemctl start gunicorn.service
            sudo systemctl enable gunicorn.service
            ;;
        "serveur-web2")
            sudo cp /local_files/config/serveur-web2/etc/ntp.conf /etc/ntp.conf
            sudo systemctl start ntpd.service
            sudo systemctl enable ntpd.service

            deployerServeurWeb

            sudo cp /local_files/config/serveur-web2/etc/systemd/system/gunicorn.service
            sudo systemctl start gunicorn.service
            sudo systemctl enable gunicorn.service
            ;;
        "serveur-temps")
            sudo cp /local_files/config/serveur-temps/etc/ntp.conf /etc/ntp.conf
            sudo systemctl start ntpd.service
            sudo systemctl enable ntpd.service
            ;;
        "serveur-bdd")
            cd /tmp || exit # parce que postgre envoie un message d'erreur inutile
            sudo su -l postgres -c "initdb -D /var/lib/postgres/data --data-checksums"
            sudo cp /local_files/config/serveur-bdd/var/lib/postgres/data/pg_hba.conf /var/lib/postgres/data/pg_hba.conf
            sudo cp /local_files/config/serveur-bdd/var/lib/postgres/data/postgresql.conf /var/lib/postgres/data/postgresql.conf
            sudo systemctl start postgresql.service
            sudo systemctl enable postgresql.service
            sudo su -l postgres -c "createuser admin --superuser"
            sudo su -l postgres -c "createdb baseDeDonnees -O admin"
            ;;
        "serveur-load")
            sudo cp /local_files/config/serveur-temps/etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
            sudo systemctl start haproxy.service
            sudo systemctl enable haproxy.service
            
            sudo cp /local_files/config/serveur-web1/etc/ntp.conf /etc/ntp.conf
            sudo systemctl start ntpd.service
            sudo systemctl enable ntpd.service
            ;;
        "admin")
            sudo systemctl start zabbix-server-pgsql.service
            sudo systemctl enable zabbix-server-pgsql.service
            ;;
    esac
}

verifierPostInstall
configurationsReseau
nmcli connection reload
installerPaquetsPostInstall
configurationsPropres
echo "1" | sudo tee /etc/post-install 1&>/dev/null

echo "OK !"
