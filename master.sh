sudo apt-get install bridge-utils -y
export MASTER_IP="192.168.50.4"
echo ${MASTER_IP}
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

sudo docker -H unix:///var/run/docker-bootstrap.sock run -d \
    --net=host \
    gcr.io/google_containers/etcd-amd64:${ETCD_VERSION} \
    /usr/local/bin/etcd \
        --listen-client-urls=http://127.0.0.1:4001,http://${MASTER_IP}:4001 \
        --advertise-client-urls=http://${MASTER_IP}:4001 \
        --data-dir=/var/etcd/data
echo "Sleeping 5 seconds after etcd start"
sleep 5s


sudo docker -H unix:///var/run/docker-bootstrap.sock run \
    --net=host \
    gcr.io/google_containers/etcd-amd64:${ETCD_VERSION} \
    etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
echo "Sleeping 5 seconds after etcd network set"
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
        --api-servers=http://localhost:8080 \
        --v=2 \
        --address=0.0.0.0 \
        --enable-server \
        --hostname-override=127.0.0.1 \
        --config=/etc/kubernetes/manifests-multi \
        --containerized

echo "Sleeping 25 seconds after docker start"
sleep 25s

kubectl get pods
kubectl get nodes
