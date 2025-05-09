# Infraestructura Cloud y GitOps para Servicios Empresariales

Este proyecto aborda un escenario real: la migración de las aplicaciones de una compañía a la nube (AWS) y su orquestación mediante Kubernetes. Se emplean herramientas como Terraform para la infraestructura como código (IaC) y se utilizan pipelines de GitHub Actions para desplegar ArgoCD y aplicaciones, facilitando la integración y entrega continua (GitOps) en un entorno de producción moderno.

En contraste, mantener servicios en servidores físicos sin herramientas de orquestación presenta desafíos significativos. La gestión manual de la infraestructura es propensa a errores, dificulta la escalabilidad y la alta disponibilidad, y ralentiza los ciclos de despliegue. La falta de automatización incrementa los costes operativos y reduce la capacidad de respuesta ante cambios o fallos. Este proyecto demuestra cómo la adopción de la nube y prácticas modernas como IaC y GitOps superan estas limitaciones.

## Estructura del Proyecto

El proyecto está organizado en los siguientes componentes principales:

- **Terraform**: Define la infraestructura en AWS (EC2, IAM, Redes, S3).
  - Módulos:
    - `k3s-cluster`: Configura un clúster k3s en una instancia EC2.
    - `proxy`: Implementa un proxy NGINX en una instancia EC2 separada.
    - `helm-releases`: Anteriormente usado para desplegar charts de Helm vía Terraform, ahora estos despliegues son gestionados por pipelines de GitHub Actions.
- **Helm Charts**: Contiene los manifiestos para desplegar aplicaciones (`charts/*`).
- **GitHub Actions Workflows** (`/.github/workflows`): Automatizan el despliegue de la infraestructura de Kubernetes (cert-manager, ingress-nginx, ArgoCD) y las aplicaciones.
- **ArgoCD Applications**: Define las aplicaciones a desplegar vía GitOps (`apps/*.yaml`), aplicadas mediante pipelines.
- **Kubernetes**: Orquesta los contenedores y servicios dentro del clúster k3s.

## Arquitectura del Sistema

El sistema sigue este flujo general:

1.  **Terraform**: Provisiona la infraestructura base en AWS (EC2 para k3s y proxy, roles IAM, S3 para estado remoto).
2.  **k3s**: Se instala en la instancia EC2 master mediante `remote-exec` durante la ejecución de Terraform.
3.  **GitHub Actions**: Tras la creación de la infraestructura, las pipelines de GitHub Actions se encargan de:
    *   Desplegar componentes esenciales en el clúster k3s como cert-manager e ingress-nginx.
    *   Desplegar ArgoCD.
    *   Aplicar los manifiestos de `Application` de ArgoCD (`apps/*.yaml`).
4.  **ArgoCD**: Una vez desplegado y configurado por la pipeline, ArgoCD monitoriza el repositorio Git (según se define en los manifiestos de `Application`) y despliega/sincroniza las aplicaciones (WordPress, Prometheus, Grafana, Wiki.js, etc.) usando los Helm Charts del repositorio.
5.  **Autenticación (OAuth2 Proxy)**: El acceso a las aplicaciones expuestas (ej. Grafana, ArgoCD) se protege mediante OAuth2 Proxy, que se integra con GitHub para la autenticación de usuarios.
6.  **Proxy NGINX**: Se configura en una EC2 separada para enrutar el tráfico externo hacia el Ingress Controller de k3s (NodePort).

```mermaid
graph LR
    subgraph AWS Cloud
        direction LR
        EC2_Master[EC2 Master (k3s)]
        EC2_Proxy["EC2 Proxy (NGINX)"]
        S3_Backend[S3 (Terraform State)]
        IAM_Roles[IAM Roles]
    end

    subgraph Local/CI
        direction TB
        Terraform[Terraform CLI]
        Git_Repo[GitHub Repo (Code)]
        GitHub_Actions[GitHub Actions (CI/CD Pipelines)]
    end

    subgraph Kubernetes Cluster (on EC2 Master)
        direction TB
        Ingress[Ingress Controller (nginx)]
        CertManager[Cert-Manager]
        ArgoCD[ArgoCD]
        OAuth2_Proxy[OAuth2 Proxy]
        Apps[Applications (WP, Grafana, etc.)]
    end

    Terraform -- Provisions --> EC2_Master
    Terraform -- Provisions --> EC2_Proxy
    Terraform -- Uses --> S3_Backend
    Terraform -- Configures --> IAM_Roles

    Git_Repo -- Triggers --> GitHub_Actions

    GitHub_Actions -- Runs --> Terraform %% Potentially, for IaC updates
    GitHub_Actions -- Deploys K8s Infra --> Ingress
    GitHub_Actions -- Deploys K8s Infra --> CertManager
    GitHub_Actions -- Deploys --> ArgoCD
    GitHub_Actions -- Applies ArgoCD Apps --> ArgoCD

    ArgoCD -- Pulls & Syncs --> Apps
    User -- Authenticates via --> OAuth2_Proxy
    OAuth2_Proxy -- Authorizes Access --> Apps
    User --> EC2_Proxy -- Forwards --> Ingress -- Routes --> OAuth2_Proxy
```

## Instrucciones de Despliegue

*   **(Prerrequisito)**: Configurar credenciales de AWS.
*   **(Prerrequisito)**: Generar un par de claves SSH (p.ej., `ssh-keygen -t rsa -b 4096 -f k3s-key`) y colocar la clave privada (`k3s-key.pem`) en el directorio raíz (o ajustar rutas).

### 1. Inicialización de Terraform

```bash
cd terraform
terraform init
```

### 2. Aplicación del Plan de Terraform

```bash
terraform apply -var-file="secrets.tfvars"
```

Despliega la infraestructura AWS e instala k3s en el nodo master. Los componentes de Kubernetes como ArgoCD, cert-manager y las aplicaciones finales se despliegan posteriormente mediante pipelines de GitHub Actions.

### 3. Configuración del Contexto Kubernetes

```bash
# Obtener IP pública del master desde la salida de Terraform
MASTER_IP=$(terraform output -raw k3s_master_public_ip)

# Obtener kubeconfig
ssh -o StrictHostKeyChecking=no -i ../k3s-key.pem ubuntu@$MASTER_IP \
  "sudo cat /etc/rancher/k3s/k3s.yaml" > ../kubeconfig

export KUBECONFIG=../kubeconfig
```

Verifica el acceso:

```bash
kubectl get nodes
kubectl get pods -A # Ver pods en todos los namespaces
```

### 4. Acceso a ArgoCD

ArgoCD se despliega mediante una pipeline de GitHub Actions (`.github/workflows/deploy-argocd.yaml`). Una vez desplegado, se expone a través del Ingress en `argocd.adrianmagarola.click` (o el dominio configurado).

Obtén la contraseña inicial (si la pipeline no la cambia o la expone de otra manera):

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo
```

Accede a la UI de ArgoCD y loguéate con `admin` y la contraseña obtenida.

### 5. Despliegue de Aplicaciones (GitOps)

Las aplicaciones definidas en `apps/*.yaml` (WordPress, Prometheus, Grafana, Wiki.js, etc.) son aplicadas como `Application` manifests de ArgoCD mediante la pipeline `.github/workflows/deploy-aplications.yaml`. ArgoCD se encarga de sincronizarlas. Verifica su estado en la UI de ArgoCD.

### 6. Configuración del Proxy (Opcional - Si no se usa Route53/ALB)

El módulo `proxy` configura NGINX para redirigir el tráfico al NodePort del Ingress Controller. La configuración de certificados en el proxy necesita revisión (actualmente usa autofirmados iniciales y la lógica de copia de certificados Let's Encrypt desde el máster está comentada en `terraform/main.tf`).

## Análisis Detallado del Código

### Terraform
*   **Infraestructura**: Módulos bien definidos (`k3s-cluster`, `proxy`, `helm-releases`). El estado se gestiona remotamente en S3 (requiere configuración inicial del bucket o ajuste del backend).
*   **Automatización**: Se usa `remote-exec` para la instalación y configuración inicial de k3s en el nodo master. Aunque funcional, para configuraciones más complejas se recomienda usar herramientas como Ansible, cloud-init avanzado o imágenes personalizadas (AMI).
*   **Gestión de Secretos**: 
    *   El `data "external" "kubeconfig"` (actualmente comentado) extraía credenciales del clúster. Esta práctica expone datos sensibles en el estado de Terraform.
    *   Se usan claves SSH (`k3s-key.pem`, `ec2-proxy-key.pem`) generadas por Terraform y almacenadas localmente o como secrets en GitHub Actions para la configuración de instancias y despliegues. Asegúrate de que `.gitignore` previene el commit de claves locales.
    *   Las credenciales de AWS, tokens de GitHub y otros secretos sensibles se gestionan como GitHub Actions Secrets y se inyectan en las pipelines o en la configuración de Terraform (a través de `secrets.tfvars` para ejecuciones locales, o variables de entorno en CI/CD).
    *   Se recomienda centralizar la gestión de secretos con herramientas como AWS Secrets Manager o HashiCorp Vault para un entorno de producción robusto.

### Helm Charts
*   **WordPress (`charts/wordpress`)**: Usa el chart oficial de Bitnami MariaDB como dependencia. Las credenciales de WordPress y MariaDB se configuran mediante `values.yaml`. Considera usar secretos de Kubernetes en lugar de pasar todo por `values.yaml` directamente.
*   **Prometheus/Grafana (`charts/prometheus`, `charts/grafana`)**: Charts básicos. No incluyen configuración de Ingress por defecto en sus `values.yaml` base, pero los Ingresses se gestionan a través de `oauth2-proxy` o configuraciones específicas en las pipelines.
*   **Wiki.js (`charts/wikijs`)**: Chart básico, Ingress deshabilitado por defecto en `values.yaml`, pero habilitado y configurado en la pipeline de despliegue de aplicaciones.

### Seguridad
*   **Claves y Certificados**: La gestión de claves SSH y certificados (autofirmados iniciales en proxy, extracción de kubeconfig) es un punto crítico. Evita exponer claves privadas. El uso de `cert-manager` para certificados TLS de Ingress es una buena práctica, y su despliegue está automatizado.
*   **RBAC**: Las políticas RBAC por defecto de k3s, Helm charts y ArgoCD deben revisarse para asegurar el principio de mínimo privilegio.
*   **Red**: Revisa las reglas de los Security Groups de AWS para limitar el acceso a los puertos necesarios (SSH, HTTP/S, API de K8s si es necesario externamente).
*   **ArgoCD Insecure Flag**: Como se mencionó, el flag `--insecure` en la configuración de ArgoCD (desplegado vía pipeline) **debe eliminarse en un entorno de producción** ya que desactiva validaciones TLS importantes.

## Próximos Pasos y Mejoras

- **Gestión de Secretos**: Implementar Vault o AWS Secrets Manager para `kubeconfig` (si se extrae), claves SSH y credenciales de aplicación.
- **Eliminar `remote-exec`**: Usar Ansible, cloud-init o AMI personalizada para la configuración de nodos k3s.
- **Proxy NGINX**: Reemplazar con AWS ALB/NLB o mejorar la gestión de certificados (integrar con cert-manager o copiar certificados de forma segura desde el clúster k3s).
- **Seguridad ArgoCD**: **Prioridad Alta**: Eliminar el flag `--insecure` de la configuración de ArgoCD en `argocd-values.yaml` y asegurar que la pipeline lo despliegue de forma segura.
- **Helm Charts**: Mejorar charts con probes, recursos, HPA, configuración de persistencia avanzada y gestión de secretos vía Kubernetes Secrets.
- **Monitorización**: Configurar Ingress para Prometheus/Grafana (actualmente se accede vía `oauth2-proxy`) y crear dashboards personalizados.
- **CI/CD**: Expandir las GitHub Actions para incluir validaciones, tests y potencialmente automatizar `terraform apply` con aprobaciones. Actualmente, los despliegues de aplicaciones y componentes de Kubernetes están bien automatizados.
- **Escalado**: Implementar Horizontal Pod Autoscaler (HPA) para aplicaciones como WordPress.
- **Base de Datos**: Considerar RDS en lugar de MariaDB en el clúster para mayor gestionabilidad y rendimiento.

---

Para más información, consulta la documentación oficial de [Terraform](https://www.terraform.io/), [Kubernetes](https://kubernetes.io/), [k3s](https://k3s.io/), [ArgoCD](https://argo-cd.readthedocs.io/), [Helm](https://helm.sh/), [cert-manager](https://cert-manager.io/) y [GitHub Actions](https://docs.github.com/en/actions).