# Kubernetización de Intranet Empresarial

Este proyecto aborda la implementación de una infraestructura en la nube mediante AWS y Kubernetes para desplegar una intranet basada en WordPress. Se utilizarán herramientas de infraestructura como código con Terraform y un sistema de integración y despliegue continuo con ArgoCD.

### Arquitectura del Sistema
```
  +------------------+                +----------------------+
  |                  |                |                      |
  |    GitHub Repo   | <---------->   |       ArgoCD        |
  |   (GitOps)       |                | (Continuous Delivery)|
  +------------------+                +----------------------+
          |                                      |
          |                                      v
  +------------------+                +----------------------+
  |                  |                |    AWS EKS/EC2       |
  |    Terraform     | ------------>  |    (Kubernetes)      |
  |     (IaC)       |                |                      |
  +------------------+                +----------------------+
                                              |
                                     +--------+---------+
                                     |                  |
                              +----------+        +-----------+
                              |          |        |           |
                              | WordPress|        |  GitHub   |
                              |  (CMS)  |        |  OAuth    |
                              +----------+        +-----------+
```

## Instrucciones de despliegue

### 1. Inicialización de Terraform

```bash
terraform init
```

Inicializa el backend y descarga los proveedores necesarios.

### 2. Aplicación del plan de Terraform

```bash
terraform apply
```

Despliega toda la infraestructura en AWS: instancias EC2, configuraciones de red, roles IAM, bucket S3 para estado remoto.

### 3. Configuración del contexto Kubernetes

```bash
ssh -o StrictHostKeyChecking=no -i ../k3s-key.pem ubuntu@<IP-del-nodo-master> \
  "sudo cat /etc/rancher/k3s/k3s.yaml" > kubeconfig

export KUBECONFIG=./kubeconfig

```

Verifica acceso:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

### 4. Instalación de ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Accede al portal de ArgoCD:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Credenciales iniciales:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

### 5. Despliegue de la Intranet WordPress

Configura un repositorio Git con los manifiestos Kubernetes de WordPress.
Regístralo en ArgoCD para desplegarlo automáticamente mediante GitOps.

### 6. Monitorización

Instalación de Prometheus y Grafana:

```bash
kubectl apply -f prometheus.yaml
kubectl apply -f grafana.yaml
```

Acceso a dashboards vía port-forward o mediante Ingress.

## Próximos pasos
- Implementar escalado automático (Horizontal Pod Autoscaler).
- Automatizar despliegues de infraestructura con GitHub Actions.
- Mejorar la seguridad: políticas RBAC, HTTPS, control de acceso IAM.