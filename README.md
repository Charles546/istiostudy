Istio Sidecar Exiting Behavior Study
====================================

Prolem
------

When doing rolling restart of deployments in kubernetes, the containers of the older revision start quiting
immediately upon receiving *SIGTERM*. If the deployment exposes a service, we may see some socket errors
or HTTP 502 errors on the service because the container dies too quickly that `kube-proxy` has not removed
the pod from the service. This is commonly mitigated by adding a waiting period in the container
either before or after receiving the *SIGTERM*.
 
With injection of sidecar container by **Istio**, the traffic in the pod gets redirected to the sidecar
container before being routed back to the application running inside the app container. It becomes harder to
deal with the timing issue between the exiting pod and updating of kube-proxy. The mitigation mentioned
earlier does not help any more.

This repo contains some files to reproduce the issue and hopefully, help finding solutions for this
issue.

Prerequisites
-------------

 * minikube
 * yq
 * kubectl
 * istioctl
 * siege

Setup
-----

```bash
./up.sh
```

This will create a minikube cluster and install Istio into the cluster.

Test without waiting period
---------------------------

```bash
./run-test.sh demo-site-nohook.yaml >/dev/null
```

You should observe some socket errors and the `siege` command output will show less than 100%
availability.

Example output
```
** SIEGE 4.0.5
** Preparing 25 concurrent users for battle.
The server is now under siege...
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer
[error] socket: read error Connection reset by peer sock.c:635: Connection reset by peer

Lifting the server siege...
Transactions:		      127679 hits
Availability:		       99.98 %
Elapsed time:		       51.17 secs
Data transferred:	       74.52 MB
Response time:		        0.01 secs
Transaction rate:	     2495.19 trans/sec
Throughput:		        1.46 MB/sec
Concurrency:		       24.25
Successful transactions:      127679
Failed transactions:	          26
Longest transaction:	        0.14
Shortest transaction:	        0.00
```

Test with waiting period
------------------------

```bash
./run-test.sh demo-site.yaml >/dev/null
```

This test should not encounter any error and the `siege` command output will show 100% availability.

Example output
```
** SIEGE 4.0.5
** Preparing 25 concurrent users for battle.
The server is now under siege...

Lifting the server siege...
Transactions:		       89051 hits
Availability:		      100.00 %
Elapsed time:		       37.19 secs
Data transferred:	       51.97 MB
Response time:		        0.01 secs
Transaction rate:	     2394.49 trans/sec
Throughput:		        1.40 MB/sec
Concurrency:		       24.46
Successful transactions:       89051
Failed transactions:	           0
Longest transaction:	        0.12
Shortest transaction:	        0.00
```

Enable sidecar injection
------------------------

```
kubectl config use-context minikube
kubectl label namespace default istio-injection=enabled
```

After enabling the sidecar injection, both test will present errors and `siege` command output will show
less than 100% availability.

Disable sidecar injection
------------------------

```
kubectl config use-context minikube
kubectl label namespace default istio-injection-
```

Tear down
---------

```
./down.sh
```

This will delete the minikube cluster.
