#!/bin/bash

# Name of the passthroughvpn container
PASSTHROUGHVPNNAME=passthroughvpn

# Sleep time in seconds
SLEEP_TIME=10

while true; do
    # Get the Id of the passthroughvpn container
    passthroughvpnId=$(docker inspect --format='{{.Id}}' ${PASSTHROUGHVPNNAME})

    # Get the first time of the passthroughvpn container
    originalStartTime=$(docker inspect --format='{{.State.StartedAt}}' ${passthroughvpnId} | xargs date +%s -d)
    newStartTime=${originalStartTime}

    # As long as the original start time is unchanged, there is nothing to do but getting the new value.
    while [[ ${originalStartTime} -eq ${newStartTime} ]]; do
        newStartTime=$(docker inspect --format='{{.State.StartedAt}}' ${passthroughvpnId} | xargs date +%s -d)
        STATUS=$?
        if [[ "${STATUS}" -ne 0 ]]; then
            datetime=$(date +"%Y-%m-%d %H:%M:%S")
            echo "${datetime} | Failed to get status of passthroughvpn container id ${passthroughvpnId}."
            echo "${datetime} | Obtaining the new Docker id, the container most likely updated or did rebuild."
            passthroughvpnId=$(docker inspect --format='{{.Id}}' ${PASSTHROUGHVPNNAME})
            newStartTime=$(docker inspect --format='{{.State.StartedAt}}' ${passthroughvpnId} | xargs date +%s -d)
        fi
        sleep ${SLEEP_TIME}
    done

    # Get all the containers with the NetWorkMode
    dockeridnetwork=$(docker ps -q | xargs docker inspect --format='{{.Id}};{{.HostConfig.NetworkMode}}')

    # Keep only the containers with the container passthroughvpn as network
    passedthroughcontainers=$(printf '%s\n' ${dockeridnetwork} | grep "container:${passthroughvpnId}" | cut -d';' -f1)

    # Restart all the containers that are getting passed through
    for passedthroughcontainer in ${passedthroughcontainers}; do
        containername=$(docker inspect --format='{{.Name}}' ${passedthroughcontainer})
        datetime=$(date +"%Y-%m-%d %H:%M:%S")
        echo "${datetime} | Restarting ${containername:1} (Container ID ${passedthroughcontainer})"
        docker restart $passedthroughcontainer
    done
    sleep ${SLEEP_TIME}
done
