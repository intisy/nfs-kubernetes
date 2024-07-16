#!/bin/bash

username=$1
password=$2
gererate_password=false

echo2() {
  echo -e "\033[0;33m$@\033[0m"
}
# generate_secure_password() {
#   if ! command -v openssl &> /dev/null; then
#     echo2 "Error: OpenSSL not found. Secure password generation unavailable."
#     return 1
#   fi
#   length=20
#   echo $(openssl rand -base64 $length | tr -dc 'A-Za-z0-9')
# }
# if [ ! -n "$password" ]; then
#   if [ "$gererate_password" = true ]; then
#     password=$(generate_secure_password)
#   else
#     password=$username
#   fi
#   echo2 "Using password: $password"
# fi

curl -fsSL https://raw.githubusercontent.com/WildePizza/nfs-kubernetes/HEAD/run.sh | bash -s deinstall

echo2 Setting up NFS server!
kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-root-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: /mnt/data
OEF
kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-root-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
OEF
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
        image: mekayelanik/nfs-server-alpine:latest
        securityContext:
          privileged: true
          capabilities:
            add: ["SYS_ADMIN", "SETPCAP", "ALL"]
        ports:
        - containerPort: 2049
        - containerPort: 111
        - containerPort: 32765
        - containerPort: 32766
        - containerPort: 32767
        env:
        - name: TZ
          value: "Asia/Dhaka"
        - name: ALLOWED_CLIENT
          value: "192.168.1.1/24"
        - name: NFS_MOUNT_PORT
          value: "2049"
        - name: NUMBER_OF_SHARES
          value: "2"
        - name: NFS_EXPORT_1
          value: "Movies"
        - name: NFS_EXPORT_2
          value: "Music"
        volumeMounts:
        - name: modules
          mountPath: /lib/modules
          readOnly: true
        - name: nfs-root
          mountPath: /data
      volumes:
      - name: modules
        hostPath:
          path: /lib/modules
      - name: nfs-root
        persistentVolumeClaim:
          claimName: nfs-root-pvc
OEF
kubectl apply -f - <<OEF
apiVersion: v1
kind: Service
metadata:
  name: nfs-server-service
spec:
  selector:
    app: nfs-server
  ports:
  - protocol: TCP
    port: 2049
    targetPort: 2049
  - protocol: TCP
    port: 111
    targetPort: 111
  - protocol: TCP
    port: 32765
    targetPort: 32765
  - protocol: TCP
    port: 32766
    targetPort: 32766
  - protocol: TCP
    port: 32767
    targetPort: 32767
OEF