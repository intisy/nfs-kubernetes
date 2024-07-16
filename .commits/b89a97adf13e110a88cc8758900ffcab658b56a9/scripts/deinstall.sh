#!/bin/bash

kubectl delete service nfs-server-service
kubectl delete deployment nfs-server
kubectl delete pvc nfs-root-pv-claim
kubectl delete pv nfs-root-pv