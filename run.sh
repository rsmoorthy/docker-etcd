#!/bin/sh

NAME=$(hostname)

# If list
if [ $1 == "list" ]; then
  etcdctl member list
  exit
fi

# If list
if [ $1 == "status" ] || [ $1 == "health" ]; then
  EPS=$(etcdctl --endpoints http://$PEER:2379 member list | awk -F ', ' '{print $3}')
  cluster=""
  for ep in $EPS; do
    if [ ! -z $cluster ]
    then
      cluster="${cluster},http://$ep:2380"
    else
      cluster="http://$ep:2380"
    fi
  done
  etcdctl --endpoints $cluster endpoint $1
  exit
fi

# If remove
if [ $1 == "remove" ]; then
  ID=$(etcdctl member list | grep $NAME | awk -F ', ' '{print $1}')
  etcdctl member remove $ID
  exit
fi


# Check for $CLIENT_URLS
if [ -z ${CLIENT_URLS+x} ]; then
        CLIENT_URLS="http://0.0.0.0:2379"
        echo "Using default CLIENT_URLS ($CLIENT_URLS)"
else
        echo "Detected new CLIENT_URLS value of $CLIENT_URLS"
fi

# Check for $PEER_URLS
if [ -z ${PEER_URLS+x} ]; then
        PEER_URLS="http://0.0.0.0:2380"
        echo "Using default PEER_URLS ($PEER_URLS)"
else
        echo "Detected new PEER_URLS value of $PEER_URLS"
fi

# Check for cluster token
CLUSTER=""
if [ ! -z ${NAME} ]; then
  NM="--name $NAME"
  if [ ! -z ${TOKEN} ]; then
    if [ -z ${PEER} ]; then
        CLUSTER="--initial-advertise-peer-urls http://$NAME:2380 --initial-cluster $NAME=http://$NAME:2380 --initial-cluster-token ${TOKEN} --initial-cluster-state new"
    else
        echo "Adding myself to the Peer"
        EPS=$(etcdctl --endpoints http://$PEER:2379 member list | awk -F ', ' '{print $3}')
        initial_cluster="$NAME=http://$NAME:2380"
        for ep in $EPS; do
          initial_cluster="${initial_cluster},$ep=http://$ep:2380"
        done
        etcdctl --endpoints http://$PEER:2379 member add $NAME --peer-urls http://$NAME:2380
        CLUSTER="--initial-advertise-peer-urls http://$NAME:2380 --initial-cluster $initial_cluster --initial-cluster-token ${TOKEN} --initial-cluster-state existing"
    fi
  fi
fi

ETCD_CMD="/bin/etcd -data-dir=/data -listen-peer-urls=${PEER_URLS} -listen-client-urls=${CLIENT_URLS} --advertise-client-urls=http://${NAME}:2379 ${NM} ${CLUSTER} $*"
echo -e "Running '$ETCD_CMD'\nBEGIN ETCD OUTPUT\n"

exec $ETCD_CMD
