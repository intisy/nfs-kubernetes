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
        image: itsthenetwork/nfs-server-alpine:12
        securityContext:
          privileged: true
          capabilities:
            add: ["SYS_ADMIN", "SETPCAP", "ALL"]
        ports:
        - containerPort: 2049
        env:
        - name: SHARED_DIRECTORY
          value: "/data"
        volumeMounts:
        - name: nfs-root
          mountPath: /data
      volumes:
      - name: nfs-root
        persistentVolumeClaim:
          claimName: nfs-root-pv-claim
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
    name: nfs-server
OEF
