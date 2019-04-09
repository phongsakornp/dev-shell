SSH_CONTAINER_PORT=62222
SSH_HOST_PORT=62222
MOSH_HOST_PORT=60001
MOSH_CONTAINER_PORT=60001

docker run -it \
    -p $SSH_HOST_PORT:$SSH_CONTAINER_PORT \
    -p $MOSH_HOST_PORT:$MOSH_CONTAINER_PORT/udp \
    -v /var/run/docker.sock:/var/run/docker.sock \
     phongsakornp/shell
