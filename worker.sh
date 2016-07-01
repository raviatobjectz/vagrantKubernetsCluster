sudo apt-get install bridge-utils -y
export MASTER_IP="192.168.50.4"
echo ${MASTER_IP}
export LOCAL_IP=`ifconfig eth1 | grep "inet " | awk -F'[: ]+' '{ print $4 }'`
echo ${LOCAL_IP}
export K8S_VERSION=1.2.4
export ETCD_VERSION=2.2.1
export FLANNEL_VERSION=0.5.5
export FLANNEL_IFACE=eth1
export FLANNEL_IPMASQ=true
echo "Sleeping 5 seconds after brige-utils install and echo"
sleep 5s

sudo sh -c 'docker daemon -H unix:///var/run/docker-bootstrap.sock -p /var/run/docker-bootstrap.pid --iptables=false --ip-masq=false --bridge=none --graph=/var/lib/docker-bootstrap 2> /var/log/docker-bootstrap.log 1> /dev/null &'
echo "Sleeping 5 seconds after bootstrap"
sleep 5s

sudo service docker stop
echo "Sleeping 5 seconds after docker stop"
sleep 5s

export dockerHash=`sudo docker -H unix:///var/run/docker-bootstrap.sock run -d \
    --net=host \
    --privileged \
    -v /dev/net:/dev/net \
    quay.io/coreos/flannel:${FLANNEL_VERSION} \
    /opt/bin/flanneld \
        --ip-masq=${FLANNEL_IPMASQ} \
        --etcd-endpoints=http://${MASTER_IP}:4001 \
        --iface=${FLANNEL_IFACE}`
echo ${dockerHash}
echo "Sleeping 5 seconds after flannel start"
sleep 5s

export flannelDetails=`sudo docker -H unix:///var/run/docker-bootstrap.sock exec ${dockerHash} cat /run/flannel/subnet.env`
echo ${flannelDetails} | sed -e "s/ /\n/g"
echo ${flannelDetails} | sed -e "s/ /\n/g" | sudo tee --append /etc/default/docker
echo "Sleeping 5 seconds after getting flannel details"
sleep 5s

echo 'DOCKER_OPTS="--bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU}"' | sudo tee --append /etc/default/docker
echo "Sleeping 5 seconds after setting docker file"
sleep 5s

sudo /sbin/ifconfig docker0 down
echo "Sleeping 5 seconds after docker0 down"
sleep 5s

sudo brctl delbr docker0
echo "Sleeping 5 seconds after delbr docker0"
sleep 5s

sudo service docker start
echo "Sleeping 5 seconds after docker start"
sleep 5s

sudo docker run \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:ro \
    --volume=/dev:/dev \
    --volume=/var/lib/docker/:/var/lib/docker:rw \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
    --volume=/var/run:/var/run:rw \
    --net=host \
    --privileged=true \
    --pid=host \
    -d \
    gcr.io/google_containers/hyperkube-amd64:v${K8S_VERSION} \
    /hyperkube kubelet \
        --allow-privileged=true \
        --api-servers=http://${MASTER_IP}:8080 \
        --v=2 \
        --address=0.0.0.0 \
        --enable-server \
        --hostname-override=${LOCAL_IP} \
        --containerized

echo "Sleeping 15 seconds after docker start"
sleep 15s

sudo docker run -d \
    --net=host \
    --privileged \
    gcr.io/google_containers/hyperkube-amd64:v${K8S_VERSION} \
    /hyperkube proxy \
        --master=http://${MASTER_IP}:8080 \
        --v=2

echo "Sleeping 15 seconds after docker service proxy start"
sleep 15s
