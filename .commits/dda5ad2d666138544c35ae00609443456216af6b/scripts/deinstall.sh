#!/bin/bash

kubectl delete service phpmyadmin
kubectl delete deployment phpmyadmin
kubectl delete pods -l app=phpmyadmin
kubectl delete replicaset.apps -l app=phpmyadmin
kubectl delete deployment mysql
kubectl delete pods -l app=mysql
kubectl delete replicaset.apps -l app=mysql
kubectl delete service mysql
kubectl delete pvc mysql-pv-claim
kubectl delete pv mysql-pv
kubectl delete secret mysql-root-pass
kubectl delete secret mysql-user-pass
