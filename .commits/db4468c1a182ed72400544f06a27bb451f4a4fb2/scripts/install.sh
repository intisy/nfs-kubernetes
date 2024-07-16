#!/bin/bash

username=$1
password=$2
gererate_password=false

echo2() {
  echo -e "\033[0;33m$@\033[0m"
}
generate_secure_password() {
  if ! command -v openssl &> /dev/null; then
    echo2 "Error: OpenSSL not found. Secure password generation unavailable."
    return 1
  fi
  length=20
  echo $(openssl rand -base64 $length | tr -dc 'A-Za-z0-9')
}
if [ ! -n "$password" ]; then
  if [ "$gererate_password" = true ]; then
    password=$(generate_secure_password)
  else
    password=$username
  fi
  echo2 "Using password: $password"
fi
echo2 Setting up NFS server!
kubectl apply -f - <<OEF
apiVersion: v1
kind: Service
metadata:
  name: nfs-server
  namespace: default
spec:
  ports:
  - port: 2049
  selector:
    app: nfs-server
OEF
kubectl apply -f - <<OEF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-server
  namespace: default
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
        image: itsthenetwork/nfs-server-alpine:latest
        securityContext:
          capabilities:
            add: ["SYS_ADMIN", "SETPCAP"]
        ports:
        - containerPort: 2049
        env:
        - name: SHARED_DIRECTORY
          value: /nfsshare
OEF