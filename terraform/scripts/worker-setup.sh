#!/bin/bash

# Actualizar los paquetes
sudo apt-get update -y

# Copiar el archivo k3s.pem desde un lugar específico
scp -i k3s-key.pem ./k3s-key.pem ubuntu@${self.public_ip}:/home/ubuntu/.ssh/k3s-key.pem

# Obtener la dirección IP del master (sustituye por la IP real)
MASTER_IP=<master_ip>

# Obtener el token del master
TOKEN=$(ssh -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/k3s-key.pem ubuntu@$MASTER_IP sudo cat /var/lib/rancher/k3s/server/node-token)

# Unirse al clúster k3s
curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$TOKEN sh -

# Descargar e instalar kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl

# Crear el directorio .kube si no existe
mkdir -p /home/ubuntu/.kube

# Obtener el archivo kubeconfig de k3s y guardarlo en el directorio .kube
sudo k3s kubectl config view --raw > /home/ubuntu/.kube/config

# Conceder permisos para el archivo kubeconfig
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Esperar 30 segundos para asegurarse de que el worker se registre en el master
sleep 30

# Etiquetar el nodo worker
kubectl label node $(hostname) node-role.kubernetes.io/worker=true
