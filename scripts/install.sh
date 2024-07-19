#!/bin/bash

args=$@
pat=$1
sha=$2

echo2() {
  echo -e "\033[0;33m$@\033[0m"
}

sudo bash kubernetes-center/run.sh repo=nfs-kubernetes raw_args="$args" action=deinstall pat=$pat sha=$sha

echo2 Setting up NFS server!
kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-root-pv
spec:
  capacity:
    storage: 1500Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  claimRef:
    namespace: default
    name: nfs-root-pv-claim
  storageClassName: local-storage
  local:
    path: "/mnt/data"
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.kubernetes.io/control-plane
          operator: In
          values:
          - "true"
OEF
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-root-pv-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1500Gi
EOF
kubectl apply -f - <<OEF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-server
  template:
    metadata:
      labels:
        app: nfs-server
    spec:
      containers:
      - name: nfs-server
        image: itsthenetwork/nfs-server-alpine:latest-arm
        securityContext:
          privileged: true
          capabilities:
            add: ["SYS_ADMIN", "SETPCAP", "ALL"]
        ports:
        - containerPort: 2049
        env:
        - name: SHARED_DIRECTORY
          value: "/data"
        - name: SHARED_DIRECTORY_2
          value: "/data/mysql"
        - name: SHARED_DIRECTORY_3
          value: "/data/registry"
        - name: SHARED_DIRECTORY_4
          value: "/data/videos"
        volumeMounts:
        - name: nfs-root
          mountPath: /data
      volumes:
      - name: nfs-root
        persistentVolumeClaim:
          claimName: nfs-root-pv-claim
OEF
kubectl apply -f - <<OEF
kind: Service
apiVersion: v1
metadata:
  name: nfs-server
spec:
  selector:
    app: nfs-server
  ports:
    - name: tcp-2049
      port: 2049
      protocol: TCP
    - name: udp-111
      port: 111
      protocol: UDP
OEF
echo2 "Waiting for NFS Server to be ready..." >&2
while [ $(kubectl get deployment nfs-server | grep -c "1/1") != "1" ]; do
    sleep 1
done
