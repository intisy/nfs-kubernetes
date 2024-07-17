#!/bin/bash

echo2() {
  echo -e "\033[0;33m$@\033[0m"
}

curl -fsSL https://raw.githubusercontent.com/WildePizza/nfs-kubernetes/HEAD/run.sh | bash -s deinstall

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
    path: "/mnt/data/mysql"
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
          value: "/mysql"
        # - name: SHARED_DIRECTORY_2
        #   value: "/registry"
        # - name: SHARED_DIRECTORY_3
        #   value: "/videos"
        volumeMounts:
        - name: nfs-root
          mountPath: /mysql
      volumes:
      - name: nfs-root
        persistentVolumeClaim:
          claimName: nfs-root-pv-claim
OEF
kubectl apply -f - <<OEF
apiVersion: v1
kind: Service
metadata:
  name: nfs-server
spec:
  selector:
    app: nfs-server
  ports:
  - protocol: TCP
    port: 2049
    targetPort: 2049
    name: nfs-server
OEF
