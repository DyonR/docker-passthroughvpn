# VPN Passthrough Container with support for WireGuard and OpenVPN
[![Docker Pulls](https://img.shields.io/docker/pulls/dyonr/passthroughvpn)](https://hub.docker.com/r/dyonr/passthroughvpn)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/dyonr/passthroughvpn/latest)](https://hub.docker.com/r/dyonr/passthroughvpn)

Docker container which runs Debian Bullseye with a WireGuard or OpenVPN with iptables killswitch to prevent IP leakage when the tunnel goes down.
This Docker runs nothing but Debian Bullseye with a VPN connection, but it's intended use is to route other containers with no VPN or proxy capability through this one to protect you IP.  
  
## Example usages
* Hosting a (game) server service, but you do not want to expose your IP  
  * This would likely only be possible if your VPN provider supports portforwarding  
* Containers that download online content, but have no 'vpn' version  
  
## USAGE WARNING
* **ANY CONTAINER THAT GETS ROUTED THROUGH THIS CONTAINER WILL (BRIEFLY) USE YOUR REAL IP. THIS IS BECAUSE THE PASSTHROUGHVPN CONTAINER NEEDS TO ESTABLISH A CONNECTION WITH THE VPN FIRST. TILL THAT IS DONE, THE CONTAINER(S) YOU PASSTHROUGH THIS CONTAINER WILL EXPOSE YOUR REAL IP. DO NOT USE THIS CONTAINER IF YOU WISH TO EXPOSE YOUR REAL IP FOR NOT A SINGLE SECOND. NORMALLY ESTABLISHING A VPN CONNECTION WILL TAKE A COUPLE SECONDS. HOWEVER, IF YOUR VPN PROVIDER IS UNREACHABLE, IT WILL KEEP ON USING YOUR REAL IP.** This is different than using any of my other 'vpn' containers, since with those the application (for example qBittorrent or Jackett) will start AFTER establishing the connection. By using this container, you will have a connection before connecting to the VPN.
* If the container loses connection, and RESTART_CONTAINER is set to `yes` this container will restart when the connection is lost. Because of this, the Dockers you route through this one will also lose connection. Therefore you need to either restart them manually or use my `restart-passed-through-containers` script in combination with [CA User Scripts](https://forums.unraid.net/topic/48286-plugin-ca-user-scripts/). Information about how to install this script can be found here: [**Installing the auto-restart script**](https://github.com/DyonR/docker-passthroughvpn#installing-the-auto-restart-script)

## Container info
* Base: Debian bullseye-slim
* IP tables killswitch to prevent IP leaking when VPN connection fails, which reboots the container
* Created with [Unraid](https://unraid.net/) in mind

# Scenarios  
Scenario One: You wish to download online content via another container that has no 'vpn' variant or proxy capability.  
Scenario Two: You wish to host a (game, Plex) server/service, but would want to protect your (home) IP.  
  
## Scenario One (Downloading Scenario)  
This scenario will only protect your IP. For example when you wish to download content. For this scenario you would need two things:  
* A container that runs a service that downloads stuff. In this example I will use ich777/jdownloader2 ([Docker Hub](https://hub.docker.com/r/ich777/jdownloader2), [GitHub](https://github.com/ich777/docker-jdownloader2)).  
* This passthrough container.  
  
Extra info; In this example, jDownloader2 uses port 8080, and without passing it through the passthroughvpn container, it would be accessible via http://192.168.0.100:8080/vnc.html?autoconnect=true  
Honestly, the port numbers can get quite messy. I will do my best to describe the infrastructure.  
The _jDownloader2 container_ has a web interface on port 8080.
This port is [exposed by the Docker container](https://docs.docker.com/engine/reference/builder/#expose). This is **NOT** the port mapping.  

### Scenario One (Instructions - Unraid)  

#### Installing the passthroughvpn container  
1. At the `Apps` section of Unraid search for `passthroughvpn`, you will see an app matching this name from my repository (Dyon's Repository).  
2. Configure the container to your liking, please refer to the [**Environment Variables**](https://github.com/DyonR/docker-passthroughvpn#environment-variables) section below. Do not forget to correct the **LAN_NETWORK** variable.  
3. The container will not yet successfully start, since there is no OpenVPN or WireGuard config added yet. This will be done in a later step. For now it will be stuck in a reboot loop.
  
#### Configuring the containers
1. Open the 'Edit' page of the **_jDownloader2 container_**  
2. In the top right change the slider from `Basic View` to `Advanced View`.  
3. Look in the first section for the setting *Extra Parameters*, and add `--net=container:passthroughvpn`. It is possible that some containers already have something filled in here already, you can still add the `--net=container` after it, for example: `--restart unless-stopped --net=container:passthroughvpn` is valid and how it should be done.  
4. In the first section, set the `Network Type` to `None`.  
5. Apply the changes to the _jDownloader2 container_. (The container will be inaccessible for now).  
6. Open the 'Edit' page of the **_passthroughvpn container_**.  
7. In the top right change the slider from `Basic View` to `Advanced View`.  
8. Select the `Add another Path, Port, Variable, Label or Device` completely at the bottom and follow the example below:  
**Config Type**: `Port`  
**Name**: `jDownloader2 Web interface`  
**Container Port**: `8080`  
**Host Port**: `8012`  
**Description**: Web interface for jDownloader2.  
9. **Note how I set the container port to 8080 (the exposed port) but the host port to 8012.** This means I would need to access the web interface on 192.168.0.100:8012 instead of 192.168.0.100:8080 how it used to be. You can set the Host Port to 8080 also.  
10. Repeat step 8. for all desired ports, for example if there are multiple ports / web interfaces needed.  
11. Look for the `ADDITIONAL_PORTS` environment variable, add as example the following:  
`8012,8080`  
This are all container ports and host ports you have added in step 8.  
12. Apply the changes to the _passthroughvpn container_.  
13. The container will most likely not start or end in a boot loop, since there is no OpenVPN or WireGuard config added.  
14. From your VPN Provider obtain your OpenVPN config with username and password or WireGuard config. WireGuard is recommended.  
15. **OpenVPN only**: Open the 'Edit' page of the **_passthroughvpn container_**.  
16. **OpenVPN only**: Enter the VPN username and password at the correct environment variable fields (`VPN_USERNAME` and `VPN_PASSWORD`)  
17. Set the `VPN_TYPE` to either `openvpn` or `wireguard`, depending on which you choose.  
18. Apply the changes to the _passthroughvpn container_.  
19. jDownloader2 should now be accessible via http://192.168.0.100:8012/vnc.html?autoconnect=true  
  
---

## Scenario Two (Hosting Scenario)  
For this scenario you would need three things.  
- A (static) IP from a VPN service (or your own external OpenVPN server).  
   - I can personally recommend [Windscribe's Static IPs feature](https://windscribe.com/features/static-ips).
- A container that runs the service that you wish to have publicly accessible without exposing your (home) IP.  
- This passthrough container.  
  
In the example below, I will refer to a _game server container_, but this could as well be a Plex or plain webserver container.
Honestly, the port numbers can get quite messy. I will do my best to describe the infrastructure.  
In this example, there is a _game server container_ with port 25569 for the game service 8443 for the web interface.  
These ports are [exposed by the Docker container](https://docs.docker.com/engine/reference/builder/#expose). This are **NOT** port mappings.  
If you wish to expose additional ports, you must add the [`--expose PORT` (docs.docker.com)](https://docs.docker.com/engine/reference/commandline/run/#publish-or-expose-port--p---expose) to the extra parameters (or the `docker run` command).  
Extra info; Unraid server uses the IP 192.168.0.100.
  
### Scenario Two (Instructions - Unraid)  
In these instructions, I do assume you have common sense, experience with Unraid and already know how to use the `Apps` section of Unraid, nevertheless I will still briefly explain this.

#### Installing the passthroughvpn container  
1. At the `Apps` section of Unraid search for `passthroughvpn`, you will see an app matching this name from my repository (Dyon's Repository).  
2. Configure the container to your liking, please refer to the [**Environment Variables**](https://github.com/DyonR/docker-passthroughvpn#environment-variables) section below. Do not forget to correct the **LAN_NETWORK** variable.  
3. The container will not yet successfully start, since there is no OpenVPN config added yet. This will be done in a later step. For now it will be stuck in a reboot loop.
  
#### Configuring the containers
1. Open the 'Edit' page of the **_game server container_**  
2. In the top right change the slider from `Basic View` to `Advanced View`.  
3. Look in the first section for the setting *Extra Parameters*, and add `--net=container:passthroughvpn`. It is possible that some containers already have something filled in here already, you can still add the `--net=container` after it, for example: `--restart unless-stopped --net=container:passthroughvpn` is valid and how it should be done.  
4. In the first section, set the `Network Type` to `None`.  
5. Apply the changes to the _game server container_.  
6. Open the 'Edit' page of the **_passthroughvpn container_**.  
7. In the top right change the slider from `Basic View` to `Advanced View`.  
8. Select the `Add another Path, Port, Variable, Label or Device` completely at the bottom and follow the example below:  
**Config Type**: `Port`  
**Name**: `Game Server Web interface`  
**Container Port**: `8443`  
**Host Port**: `8012`  
**Description**: Web interface for Game Server.  
9. **Note how I set the container port to 8443 (the exposed port) but the host port to 8012.** This means I would need to access the service on 192.168.0.100:8012 instead of 192.168.0.100:8443.  
10. Repeat step 8. for all desired ports (I would make a container port 25569 with host port 25570).  
11. Look for the `ADDITIONAL_PORTS` environment variable, add as example the following:  
`8012,8443,25569,25570`  
This are all container ports and host ports you have added in step 8.  
12. Apply the changes to the _passthroughvpn container_.  
13. The container will most likely not start or end in a boot loop, since there is no OpenVPN config, yet. How to obtain this will be explained at the next section.  
14. (If the container starts successfully since you already were a few steps ahead, you should now be able to access the web interface of your _game server_ via http://192.168.0.100:8012/ and the game service via 192.168.0.100:25570)  
  
#### Forwarding ports at a VPN service and obtaining the OpenVPN config  
Since I have no other reference material, in this example I will explain how I do it with a [Windscribe Static IP](https://windscribe.com/features/static-ips).  
  
1. Go to your account and then the port forwarding section.  
2. Add a new portforward (for Windscribe, the green circular + icon)  
3. Enter the correct info. Example:  
**Service Name**: Game Server Web interface  
**TCP+UDP**: TCP Only  
**Device**: New Manual Device -> **Device Name**: Game Server  
**External Port**: 5080  
**Internal Port**: 8012  
4. Download the OpenVPN config and securely store the username and password somewhere.
5. Repeat step 2-3 for all desired ports. (My game server will have External port 50815  
6. Open the 'Edit' page of the **_passthroughvpn container_**.  
7. Set the `VPN_TYPE` to OpenVPN.  
8. Enter the VPN username and password at the correct environment variable fields (`VPN_USERNAME` and `VPN_PASSWORD`)  
9. Go to your Unraid appdata folder, open the `passthroughvpn` directory and then the `openvpn` directory. Put your `.ovpn` config file in here.  
10. Apply the changes to the _passthroughvpn container_.  
11. The _game server_ web interface is now accessible via the VPN IP with port, http://37.120.192.19:5080/, and the game service at 37.120.192.19:5081.  
  
# Installing the auto-restart script
1. In Unraid, go to the Apps section and install "CA User Scripts" from Squid
2. For easy installation, open the terminal in Unraid and run the following 3 commands:
```
mkdir -p /boot/config/plugins/user.scripts/scripts/passthrough_restart
echo 'This script will check if the passthroughvpn container has restarted and restart the passed through containers' > /boot/config/plugins/user.scripts/scripts/passthrough_restart/description
wget -q https://raw.githubusercontent.com/DyonR/docker-passthroughvpn/master/restart-passed-through-containers.sh -O /boot/config/plugins/user.scripts/scripts/passthrough_restart/script
```
3. In Unraid, go to Settings -> (User Utilities at the bottom) -> User Scripts
4. Here you will see a script called 'passthrough_restart'. Set the schedule to At Startup of Array. And press Apply.
5. Select Run In Background to start the script immediately


# Variables, Volumes, and Ports
## Environment Variables
| Variable | Required | Function | Example | Default |
|----------|----------|----------|----------|----------|
|`VPN_ENABLED`| Yes | Enable VPN (yes/no)?|`VPN_ENABLED=yes`|`yes`|
|`VPN_TYPE`| Yes | WireGuard or OpenVPN (wireguard/openvpn)?|`VPN_TYPE=wireguard`|`openvpn`|
|`VPN_USERNAME`| No | If username and password provided, configures ovpn file automatically |`VPN_USERNAME=ad8f64c02a2de`||
|`VPN_PASSWORD`| No | If username and password provided, configures ovpn file automatically |`VPN_PASSWORD=ac98df79ed7fb`||
|`LAN_NETWORK`| Yes (atleast one) | Comma delimited local Network's with CIDR notation |`LAN_NETWORK=192.168.0.0/24,10.10.0.0/24`||
|`ADDITIONAL_PORTS`| No | Adding a comma delimited list of ports will allow these ports via the iptables script. |`ADDITIONAL_PORTS=1234,8112`||
|`RESTART_CONTAINER`| No | If set to `yes`, the container will `exit 1`, restarting itself. |`RESTART_CONTAINER=yes`||
|`NAME_SERVERS`| No | Comma delimited name servers |`NAME_SERVERS=1.1.1.1,1.0.0.1`|`1.1.1.1,1.0.0.1`|
|`PUID`| No | UID for the user that runs the container |`PUID=99`|`99`|
|`PGID`| No | GID for the user that runs the container |`PGID=100`|`100`|
|`UMASK`| No | |`UMASK=002`|`002`|
|`HEALTH_CHECK_HOST`| No |This is the host or IP that the healthcheck script will use to check an active connection|`HEALTH_CHECK_HOST=one.one.one.one`|`one.one.one.one`|
|`HEALTH_CHECK_INTERVAL`| No |This is the time in seconds that the container waits to see if the internet connection still works (check if VPN died)|`HEALTH_CHECK_INTERVAL=300`|`300`|
|`HEALTH_CHECK_SILENT`| No |Set to `1` to supress the 'Network is up' message. Defaults to `1` if unset.|`HEALTH_CHECK_SILENT=1`|`1`|

# Note about OpenVPN files  
It is possible that OpenVPN will fail to start if there is no `auth-user-pass` line in your `.ovpn` file.  
Open your .ovpn file with a text editor and check if the `auth-user-pass` line exists. If not, add this line to the first section of the config:  
`auth-user-pass credentials.conf`  
  

## PUID/PGID
User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as: `id <username>`  
Example output will be:  
`uid=1000(dyon) gid=100(users) groups=100(users)`  
In the container environment varables, this means I will set PUID to 1000 and PGID to 100.  
  
# Issues
If you are having issues with this container please submit an issue on GitHub.  
Please provide logs, Docker version and other information that can simplify reproducing the issue.  
If possible, always use the most up to date version of Docker, you operating system, kernel and the container itself. Support is always a best-effort basis.  
  
### Credits:
[MarkusMcNugen/docker-qBittorrentvpn](https://github.com/MarkusMcNugen/docker-qBittorrentvpn)  
[DyonR/jackettvpn](https://github.com/DyonR/jackettvpn)  
This projects originates from MarkusMcNugen/docker-qBittorrentvpn, but forking was not possible since DyonR/jackettvpn uses the fork already.
