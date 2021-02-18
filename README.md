# VPN Passthrough Container with support for WireGuard and OpenVPN
[![Docker Pulls](https://img.shields.io/docker/pulls/dyonr/passthroughvpn)](https://hub.docker.com/r/dyonr/passthroughvpn)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/dyonr/passthroughvpn/latest)](https://hub.docker.com/r/dyonr/passthroughvpn)

Docker container which runs Debian 10 with a WireGuard or OpenVPN with iptables killswitch to prevent IP leakage when the tunnel goes down.
This Docker runs nothing but Debian 10 with a VPN connection, but it's intended use is to route other containers with no VPN or proxy capability through this one to protect you IP.

## Example usages
* Hosting a (game) server service, but you do not want to expose your IP
  * This would likely only be possible if you provider supports portforwarding
* Containers that download online content, but have no 'vpn' version

## USAGE WARNING
* If the container loses connection, and RESTART_CONTAINER is set to `yes` this container will restart when the connection is lost. Because of this, the Dockers you route through this one will rebuild and reconnect to the passthrough container.

## Container info
* Base: Debian 10-slim
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
2. Configure the container to your liking, please refer to the **Environment Variables** section below. Do not forget to correct the **LAN_NETWORK** variable.  
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
2. Configure the container to your liking, please refer to the **Environment Variables** section below. Do not forget to correct the **LAN_NETWORK** variable.  
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

# How to use WireGuard 
The container will fail to boot if `VPN_ENABLED` is set and there is no valid .conf file present in the /config/wireguard directory. Drop a .conf file from your VPN provider into /config/wireguard and start the container again. The file must have the name `wg0.conf`, or it will fail to start.

# How to use OpenVPN
The container will fail to boot if `VPN_ENABLED` is set and there is no valid .ovpn file present in the /config/openvpn directory. Drop a .ovpn file from your VPN provider into /config/openvpn (if necessary with additional files like certificates) and start the container again. You may need to edit the ovpn configuration file to load your VPN credentials from a file by setting `auth-user-pass`.

**Note:** The script will use the first ovpn file it finds in the /config/openvpn directory. Adding multiple ovpn files will not start multiple VPN connections.

## Example auth-user-pass option for .ovpn files
`auth-user-pass credentials.conf`

## Example credentials.conf
```
username
password
```

## PUID/PGID
User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:

```
id <username>
```

# Issues
If you are having issues with this container please submit an issue on GitHub.  
Please provide logs, Docker version and other information that can simplify reproducing the issue.  
If possible, always use the most up to date version of Docker, you operating system, kernel and the container itself. Support is always a best-effort basis.

### Credits:
[MarkusMcNugen/docker-qBittorrentvpn](https://github.com/MarkusMcNugen/docker-qBittorrentvpn)  
[DyonR/jackettvpn](https://github.com/DyonR/jackettvpn)  
This projects originates from MarkusMcNugen/docker-qBittorrentvpn, but forking was not possible since DyonR/jackettvpn uses the fork already.
