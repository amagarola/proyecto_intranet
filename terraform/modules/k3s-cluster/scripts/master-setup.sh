#!/bin/bash

# Actualizar los paquetes
sudo apt-get update -y

# Instalar dependencias necesarias para Kubernetes
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Descargar e instalar kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Instalar k3s
curl -sfL https://get.k3s.io | sh -

# Crear el directorio .kube si no existe
mkdir -p /home/ubuntu/.kube

# Obtener el archivo kubeconfig de k3s y guardarlo en el directorio .kube
sudo k3s kubectl config view --raw > /home/ubuntu/.kube/config

# Esperar 30 segundos para asegurarse de que el worker se registre en el master
sleep 30

# Marcar el nodo como master
kubectl taint nodes $(hostname) node-role.kubernetes.io/master=true:NoSchedule
