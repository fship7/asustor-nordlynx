# OBSOLETE. 
Asustor transitioned to kernel 5.13.x, making this repository obsolete. Unfortunately, they still didnt include wireguard in the kernel...

# asustor-nordlynx
Getting Nordlynx up and running on Asustor ADM 4.0 kernel 5.4.x

## First, we need wireguard
Kernel 5.4.x doesn't natively support wireguard, you need 5.6 for that. That means we will need to build the external kernel module from scratch and install it. Let's take the Ubuntu on Docker route.

### You can download and install the latest release
1. Download the most recent release from the releases tab, for example download it to /volume1/home/admin/wgmodule. Check it.
```bash
sha256sum wireguard.ko
568ae601d69480e2ea07fc11cc4b3c37d092da4e54c63e64bf83dbaaf7db51a1  wireguard.ko
```
2. Copy it to your modules/extra folder.
```bash
sudo mkdir /lib/modules/5.4.x/extra
sudo cp /volume1/home/admin/wgmodule/wireguard.ko /lib/modules/5.4.x/extra
```
3. Load the necessary modules.
```bash
sudo modprobe udp_tunnel
sudo modprobe ip6_udp_tunnel
sudo insmod /lib/modules/5.4.x/extra/wireguard.ko
```
Nice. Your ADM now supports wireguard.

### Or, you can build your own with Docker
0. Install 'Docker-ce' and 'Git' Apps on your ADM.
1. SSH into your ADM and load up a terminal window
2. Clone this repository.
```bash
git clone https://github.com/fship7/asustor-nordlynx.git
cd asustor-nordlynx
sudo docker build -t wireguard-builder .
```
3. Get a shared folder ready. For example, /volume1/home/admin/wgmodule
```bash
mkdir /volume1/home/admin/wgmodule
```
4. Run the docker-compose.yaml stack. It will run then immediately stop. If you made a different shared folder than the one above, you need to edit that part in the docker-compose under 'volumes'.
```bash
sudo docker-compose up
sudo docker-compose down
```
5. Check to make sure you now have a file called 'wireguard.ko' in your shared folder, for example /volume1/home/admin/wgmodule/wireguard.ko. This is the external module for your kernel.
6. Copy the module to your modules/extra folder.
```bash
sudo mkdir /lib/modules/5.4.x/extra
sudo cp /volume1/home/admin/wgmodule/wireguard.ko /lib/modules/5.4.x/extra
```
7. Load the necessary modules.
```bash
sudo modprobe udp_tunnel
sudo modprobe ip6_udp_tunnel
sudo insmod /lib/modules/5.4.x/extra/wireguard.ko
```
Nice. Your ADM now supports wireguard.

## Now, we want to get Nordlynx running.
1. Clone and build bubuntux/nordlynx
2. Use the following Docker compose, which was gleaned from the nordlynx Synology discussion board.
```yaml
version: "3"
services:
  nordlynx:
    image: bubuntux/nordlynx
    container_name: nordlynx
    security_opt: 
      - no-new-privileges:true # might cause problems with container networking...
    cap_add:
      - NET_ADMIN #required
    sysctls:
      - net.ipv6.conf.all.disable_ipv6=1  # Recommended if using ipv4 only
      - net.ipv4.conf.all.src_valid_mark=1
    environment:
      - PRIVATE_KEY=xxx= #required, had to use a ubuntu actual virtual machine to get this 
      - ALLOWED_IPS=0.0.0.0/1,128.0.0.0/1
      - NET_LOCAL=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
      - "POST_UP=ip -4 route add $$(wg | awk -F'[: ]' '/endpoint/ {print $$5}') via $$(ip route | awk '/default/ {print $$3}')"
      - "PRE_DOWN=ip -4 route del $$(route -n | awk '/255.255.255.255/ {print $$1}') via $$(ip route | awk '/default/ {print $$3}')"
    restart: unless-stopped
```
Nice. Now you have Nordlynx running over wireguard on your asustor. As of Apr 2022 it still doesnt work as well for me as the old bubuntux/nordvpn container. Some networking issues.
