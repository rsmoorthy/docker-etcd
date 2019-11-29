# docker-etcd
Simple etcd docker image - easy to start / manage for multi-member cluster


## How to start a multi-member cluster incrementally

* Note: All docker containers should have a hostname (`-h <hostname>`) and network (`--net=mynet`)

* Initial start

```
# This starts the first member of the multi-member cluster
# TOKEN environment variable is needed to start the cluster
$ docker run --name etcd01 -h etcd01 -itd --net=mynet -e TOKEN=cluster01 rsmoorthy/etcd:3.4
$ docker exec -it etcd01 run.sh list
2be387acf3308cc9, started, etcd01, http://etcd01:2380, http://etcd01:2379, false
$
```

* Second / third / nth member start
```
# Starts the second/third/nth member. Just specify PEER env variable to specify any of the existing Peers
$ docker run --name etcd02 -h etcd02 -itd --net=mynet -e TOKEN=cluster01 -e PEER=etcd01 rsmoorthy/etcd:3.4
$ docker exec -it etcd01 run.sh list
2be387acf3308cc9, started, etcd01, http://etcd01:2380, http://etcd01:2379, false
ec3ea41994f02a68, started, etcd02, http://etcd02:2380, http://etcd02:2379, false
$
$ docker run --name etcd03 -h etcd03 -itd --net=mynet -e TOKEN=cluster01 -e PEER=etcd01 rsmoorthy/etcd:3.4
$ docker exec -it etcd03 run.sh list
2be387acf3308cc9, started, etcd01, http://etcd01:2380, http://etcd01:2379, false
4c65c889044d4815, started, etcd03, http://etcd03:2380, http://etcd03:2379, false
ec3ea41994f02a68, started, etcd02, http://etcd02:2380, http://etcd02:2379, false
$
```

* Check health, Stop / Start containers
```
# Stop and start any container without having to do any reconfiguration
$ docker stop etcd02
$ docker exec -it etcd01 run.sh health
http://etcd01:2380 is healthy: successfully committed proposal: took = 2.143237ms
http://etcd03:2380 is healthy: successfully committed proposal: took = 2.250647ms
http://etcd02:2380 is unhealthy: failed to commit proposal: context deadline exceeded
Error: unhealthy cluster
$ docker start etcd02
$ docker exec -it etcd01 run.sh health
http://etcd01:2380 is healthy: successfully committed proposal: took = 3.807737ms
http://etcd02:2380 is healthy: successfully committed proposal: took = 4.868355ms
http://etcd03:2380 is healthy: successfully committed proposal: took = 4.584993ms
```

* Remove members easily
```
# Remove any of the members easily. Run remove on the container which you want it to remove
$ docker exec -it etcd01 run.sh remove
Member 2be387acf3308cc9 removed from cluster d7b057869cd0b403
$ docker ps -a | grep etcd
28b9d32d83a6        rsmoorthy/etcd:3.4   "/bin/run.sh"            3 hours ago         Up 3 hours                  2379-2380/tcp, 4001/tcp, 7001/tcp   etcd03
f55f01c19832        rsmoorthy/etcd:3.4   "/bin/run.sh"            3 hours ago         Up 30 seconds               2379-2380/tcp, 4001/tcp, 7001/tcp   etcd02
704b9ba78cf9        rsmoorthy/etcd:3.4   "/bin/run.sh"            3 hours ago         Exited (0) 20 seconds ago                                       etcd01
$ docker exec -it etcd02 run.sh list
4c65c889044d4815, started, etcd03, http://etcd03:2380, http://etcd03:2379, false
ec3ea41994f02a68, started, etcd02, http://etcd02:2380, http://etcd02:2379, false
$ 
```




