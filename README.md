# VPN Passthrough Container with support for WireGuard and OpenVPN
[![Docker Pulls](https://img.shields.io/docker/pulls/dyonr/passthroughvpn)](https://hub.docker.com/r/dyonr/passthroughvpn)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/dyonr/passthroughvpn/latest)](https://hub.docker.com/r/dyonr/passthroughvpn)

Docker container which runs Debian 10 with a WireGuard or OpenVPN with iptables killswitch to prevent IP leakage when the tunnel goes down.
This Docker runs nothing but Debian 10, but it's intended use is to route other containers with no VPN or proxy capability through this one to protect you IP.

## Example usages
* Hosting a game server, but you do not want to expose your IP
  * This would likely only be possible if you provider supports portforwarding
* Containers that download online content, but have no 'vpn' version
* Hosting a website

## USAGE WARNING
* If the container loses connection, and RESTART_CONTAINER is set to `yes` this container will restart when the connection is lost. Because of this, the Dockers you route through this one will also restart, since they have to rebuild themself to connect to this Docker.

## Docker Features
* Base: Debian 10-slim
* IP tables killswitch to prevent IP leaking when VPN connection fails, which reboots the container
* Configurable UID and GID for config files and /downloads for qBittorrent
* Created with [Unraid](https://unraid.net/) in mind

# Usage Intructions
In this example, you have a container which hosts a game server on port 26920 and it's web interface on 8443.

## Unraid
This container will later get added to the apps section of Unraid, that is what the instructions below are aimed for.
If you use Unraid, you must edit this container, in the bottom of the edit screen, you will see "Add another Path, Port, Variable, Label or Device".
Set the `Config Type` to `Port`. Set it's `Name` to, for example, `Game Server`.
Set the `Container Port` to `26920`.
Set the `Host Port` to any available port that you wish. This will be the port you use to connect to from externally. However, using the same port as `Container Port`, `26920`, is recommended.
Set the `Default Value` to `26920`.
Set the `Connection Type` to whatever the game server requires.
You can set the `Description` to something like `Port 26920, used by Game Server`
Repeat the steps above for the other port, `8443`.

## docker run
This container can also get started with the `docker run` command.
```
$ docker run --privileged  -d \
              -v /your/config/path/:/config \
              -v /your/downloads/path/:/downloads \
              -e "VPN_ENABLED=yes" \
              -e "VPN_TYPE=wireguard" \
              -e "LAN_NETWORK=192.168.0.0/24" \
              -e "ADDITIONAL_PORTS=26920,8443" \
              -p 26920:26920 \
              -p 8443:8443 \
              --restart unless-stopped \
              dyonr/passthroughvpn
```

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