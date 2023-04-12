# Automated Arch Install
Scripts and config files used to automate the installation process of Arch Linux virtual machine according to an educational project.
## Abstract
Automated educational Arch Linux install. Several installation profiles are available, each corresponding to a virtual machine instance.
A client connects to the serveur-load (load balancer) directing traffic to either serveur-web1 or serveur-web2 (web servers).
Both these servers are a connected to a single database serveur-bdd (database server).
Machines have their time synced with serveur-temps (time server).

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

See ./LICENSE for more information about this project's licence.
