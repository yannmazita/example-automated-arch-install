# Automated Arch Install
Scripts and config files used to automate the installation process of Arch Linux virtual machines according to an educational project.
## Abstract
Several installation profiles are available, each corresponding to a virtual machine instance.
The client connects to serveur-load (load balancer) directing traffic to either serveur-web1 or serveur-web2 (web servers).
Both these servers are connected to a single database serveur-bdd (database server).
Machines have sync their time serveur-temps (time server).
An administration machine can access the servers through its own network (admin-net) insted of the regular network (intra-net).

## Virtual machines
Five virtual machines are currently used in this project:
```commandline
serveur-load, serveur-web1, serveur-web2, serveur-bdd, serveur-temps
```

## Network topology
### Network interfaces
Each virtual machine has 3 network interfaces with known names:
- enp0s3 attached to a bridged adapter (or NAT if network configuration allows)
- enp0s8 attached to an internal network (admin-net)
- enp0s9 attached to an internal network (intra-net)

### IPv4 addressing
Virtual machines in admin-net have these IP addresses:
- 192.168.0.1 (admin)
- 192.168.0.2 (serveur-load)
- 192.168.0.3 (serveur-web1)
- 192.168.0.4 (serveur-web2)
- 192.168.0.5 (serveur-bdd)
- 192.168.0.6 (serveur-temps)

Virtual machines in intra-net have these IP addresses:
- 192.168.2.2 (serveur-load)
- 192.168.2.3 (serveur-web1)
- 192.168.2.4 (serveur-web2)
- 192.168.2.5 (serveur-bdd)
- 192.168.2.6 (serveur-temps)

Client's IP address is unimportant.

## Usage

Configure 5 virtual machines as follow:
- 1 CPU, 2048 MB (RAM), 50 GB dynamically allocated (HDD), EFI activated, Arch Linux ISO in disc drive.
- Boot into a machine with the Arch image.

### Online mode
You will download everything from Arch mirrors.
- Type 
    ```commandline
    loadkeys fr-latin9
    curl -sL $(curl https://pastebin.com/raw/hBYQ2Umm) > install_script.sh
    bash install_script.sh
    ```
- Select the machine you want to install (one of 5 virtual machines) then wait for the machine to restart
- Log in with admin:master
- Post installation begins, type password (master) when prompted
- Once you're greeted with
```commandline
OK !
```
you're ready to go.

### Offline mode
Not really offline, you were provided with an image packing the full base install.
Some python packages and get repos still need to be downloaded.
- Type 
    ```commandline
    loadkeys fr-latin9
    bash /local_files/scripts/install_script_offline.sh
    ```
- Select the machine you want to install (one of 5 virtual machines) then wait for the machine to restart
- Log in with admin:master
- Post installation begins, type password (master) when prompted
- Once you're greeted with
```commandline
OK !
```
you're ready to go.

### Order
As of now, to avoid any issue you have to install the virtual machines in this order:
- serveur-temps
- serveur-bdd (and restart postgresql service)
- serveur-web{1,2} (and start the servers)
- serveur-load

### Web server virtual machines
Starting/Stopping the server is handled by the systemd service gunicorn.service. It automatically starts
on system boot.
After changing data models you can run the command:
```commandline
migrate_server
```

### Database server virtual machines
As of now you HAVE to run
```commandline
sudo systemctl restart postgresql.service
```
to make the PostgreSQL database accessible.

## To do
- Configure SSH access.
- Fix HTTP redirection issues
- Fix the need to -restart- postgresql.service after every boot.
- Domain name
- (DNS server)
- (RAID)

See ./LICENSE for more information about this project's licence.
