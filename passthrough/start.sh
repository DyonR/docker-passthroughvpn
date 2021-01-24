#!/bin/bash

# Check if the PGID exists, if not create the group with the name 'vpn_group'
grep $"${PGID}:" /etc/group > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "[INFO] A group with PGID $PGID already exists in /etc/group, nothing to do." | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[INFO] A group with PGID $PGID does not exist, adding a group called 'vpn_group' with PGID $PGID" | ts '%Y-%m-%d %H:%M:%.S'
	groupadd -g $PGID vpn_group
fi

# Check if the PUID exists, if not create the user with the name 'vpn_user', with the correct group
grep $"${PUID}:" /etc/passwd > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "[INFO] An user with PUID $PUID already exists in /etc/passwd, nothing to do." | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[INFO] An user with PUID $PUID does not exist, adding an user called 'vpn_user' with PUID $PUID" | ts '%Y-%m-%d %H:%M:%.S'
	useradd -c "vpn_user" -g $PGID -u $PUID vpn_user
fi

# Set the umask
if [[ ! -z "${UMASK}" ]]; then
	echo "[INFO] UMASK defined as '${UMASK}'" | ts '%Y-%m-%d %H:%M:%.S'
	export UMASK=$(echo "${UMASK}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
else
	echo "[WARNING] UMASK not defined (via -e UMASK), defaulting to '002'" | ts '%Y-%m-%d %H:%M:%.S'
	export UMASK="002"
fi



# Set some variables that are used
HOST=${HEALTH_CHECK_HOST}
DEFAULT_HOST="one.one.one.one"
INTERVAL=${HEALTH_CHECK_INTERVAL}
DEFAULT_INTERVAL=300

# If host is zero (not set) default it to the DEFAULT_HOST variable
if [[ -z "${HOST}" ]]; then
	echo "[INFO] HEALTH_CHECK_HOST is not set. For now using default host ${DEFAULT_HOST}" | ts '%Y-%m-%d %H:%M:%.S'
	HOST=${DEFAULT_HOST}
fi

# If HEALTH_CHECK_INTERVAL is zero (not set) default it to DEFAULT_INTERVAL
if [[ -z "${HEALTH_CHECK_INTERVAL}" ]]; then
	echo "[INFO] HEALTH_CHECK_INTERVAL is not set. For now using default interval of ${DEFAULT_INTERVAL}" | ts '%Y-%m-%d %H:%M:%.S'
	INTERVAL=${DEFAULT_INTERVAL}
fi

# If HEALTH_CHECK_SILENT is zero (not set) default it to supression
if [[ -z "${HEALTH_CHECK_SILENT}" ]]; then
	echo "[INFO] HEALTH_CHECK_SILENT is not set. Because this variable is not set, it will be supressed by default" | ts '%Y-%m-%d %H:%M:%.S'
	HEALTH_CHECK_SILENT=1
fi

while true; do
	# Ping uses both exit codes 1 and 2. Exit code 2 cannot be used for Docker health checks, therefore we use this script to catch error code 2
	ping -c 1 $HOST > /dev/null 2>&1
	STATUS=$?
	if [[ "${STATUS}" -ne 0 ]]; then
		echo "[ERROR] Network is possibly down." | ts '%Y-%m-%d %H:%M:%.S'
		sleep 1
		if [[ "${RESTART_CONTAINER,,}" == "yes" ]]; then
			echo "[INFO] Restarting container." | ts '%Y-%m-%d %H:%M:%.S'
			exit 1
		fi
	fi
	if [ ! "${HEALTH_CHECK_SILENT}" -eq 1 ]; then
		echo "[INFO] Network is up" | ts '%Y-%m-%d %H:%M:%.S'
	fi
	sleep ${INTERVAL}
done
