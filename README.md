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

Configure every virtual machine except the admin machine as follows:
- 1 CPU, 2048 MB (RAM), 50 GB dynamically allocated (HDD), EFI activated, Arch Linux ISO in disc drive.
- Boot into a machine with the Arch image.

Any Arch Linux image should work. You might have been provided with an Arch image.

The admin machine should have the same configuration AND at least 32MB of VRAM and 3GB or RAM if you plan to use the GUI.

### Offline mode
Not really offline. Base packages will be installed from the image, speeding up the process.
Post-installation still requires an active and unrestricted Internet connection (bridge) to download
python packages and clone git repos.
You cannot use this mode with a regular Arch Linux image.
- Type 
    ```commandline
    loadkeys fr-latin9
    bash /local_files/scripts/install_script_offline.sh
    ```
- Select the machine you want to install (one of 6 virtual machines) then wait for the machine to restart
- Log in with admin:master
- Post installation begins, type the password (master) when prompted
- (On the serveur-temps machine you will then have to type the password "test" 5 times)
- Once you're greeted with
```commandline
OK !
```
you're ready to go.

### Online mode
You have to use this mode if you're using an Arch Linux image from the Internet.
You can still use this setup process with the Arch Linux image provided (the process will be sped up)
- Type 
    ```commandline
    loadkeys fr-latin9
    curl -sL $(curl https://pastebin.com/raw/hBYQ2Umm) > install_script.sh
    bash install_script.sh
    ```
- Select the machine you want to install (one of 6 virtual machines) then wait for the machine to restart
- Log in with admin:master
- Post installation begins, type the password (master) when prompted
- (On the serveur-temps machine you will then have to type the password "test" 5 times)
- Once you're greeted with
```commandline
OK !
```
you're ready to go.

### Order
As of now, to avoid any issue you have to install the virtual machines in this order:
- serveur-temps
- serveur-bdd (and restart postgresql service)
- serveur-web{1,2} (web servers are automatically deployed and started up)
- serveur-load
- admin

### Database server virtual machines
As of now you HAVE to run
```commandline
sudo systemctl restart postgresql.service
```
to make the PostgreSQL database accessible.
Failure to run this command BEFORE setting up the web servers WILL result in broken web server virtual machines.

### Web server virtual machines
Starting/Stopping the server is handled by the systemd service gunicorn.service. It automatically starts on system boot.
Example command to stop the server:
```commandline
sudo systemctl stop gunicorn.service
```
After changing data models you can run the command:
```commandline
migrate_server
```

### Admin virtual machine
To start the GUI use the command:
```commandline
startxfce4
```

## To do
- Configure SSH access.
- Fix the need to -restart- postgresql.service after every boot.
- (RAID)

See ./LICENSE for more information about this project's licence.
