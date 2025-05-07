# Infraestructura Cloud y GitOps para Servicios Empresariales

Este proyecto aborda un escenario real: la migración de las aplicaciones de una compañía a la nube (AWS) y su orquestación mediante Kubernetes. Se emplean herramientas como Terraform para la infraestructura como código (IaC) y ArgoCD para la integración y entrega continua (GitOps), simulando un entorno de producción moderno.

En contraste, mantener servicios en servidores físicos sin herramientas de orquestación presenta desafíos significativos. La gestión manual de la infraestructura es propensa a errores, dificulta la escalabilidad y la alta disponibilidad, y ralentiza los ciclos de despliegue. La falta de automatización incrementa los costes operativos y reduce la capacidad de respuesta ante cambios o fallos. Este proyecto demuestra cómo la adopción de la nube y prácticas modernas como IaC y GitOps superan estas limitaciones.

## Estructura del Proyecto

El proyecto está organizado en los siguientes componentes principales:

- **Terraform**: Define la infraestructura en AWS (EC2, IAM, Redes, S3).
  - Módulos:
    - `k3s-cluster`: Configura un clúster k3s en una instancia EC2.
    - `proxy`: Implementa un proxy NGINX en una instancia EC2 separada.
    - `helm-releases`: Despliega charts de Helm esenciales (cert-manager, ArgoCD, ingress-nginx, letsencrypt-issuer) vía Terraform.
- **Helm Charts**: Contiene los manifiestos para desplegar aplicaciones:
  - `charts/wordpress`: Configuración personalizada para WordPress (depende de MariaDB).
  - `charts/wikijs`: Configuración para Wiki.js.
  - `charts/prometheus`: Configuración para Prometheus.
  - `charts/grafana`: Configuración para Grafana.
- **ArgoCD Applications**: Define las aplicaciones a desplegar vía GitOps (`apps/*.yaml`).
- **Kubernetes**: Orquesta los contenedores y servicios dentro del clúster k3s.

## Arquitectura del Sistema

El sistema sigue este flujo general:

1.  **Terraform**: Provisiona la infraestructura base en AWS (EC2 para k3s y proxy, roles IAM, S3 para estado remoto).
2.  **k3s**: Se instala en la instancia EC2 master mediante `remote-exec`.
<!-- 3.  **Helm (vía Terraform)**: Despliega cert-manager, ingress-nginx, ArgoCD y el ClusterIssuer de Let's Encrypt. -->
<!-- 4.  **ArgoCD**: Se configura para monitorizar el repositorio Git. -->
<!-- 5.  **ArgoCD Applications (`apps/*.yaml`)**: Definen las aplicaciones (WordPress, Prometheus, Grafana, Wiki.js) que ArgoCD debe desplegar usando los Helm Charts del repositorio. -->
6.  **Proxy NGINX**: Se configura en una EC2 separada para enrutar el tráfico externo hacia el Ingress Controller de k3s (NodePort).
<!-- 7.  **GitHub Actions (Futuro)**: Desplegará las aplicaciones y configuraciones de Kubernetes (Helm charts, manifests) en el clúster k3s. -->

```mermaid
graph LR
    subgraph AWS Cloud
        direction LR
        EC2_Master[EC2 Master (k3s)]
        EC2_Proxy[EC2 Proxy (NGINX)]
        S3_Backend[S3 (Terraform State)]
        IAM_Roles[IAM Roles]
    end

    subgraph Local/CI
        direction TB
        Terraform[Terraform CLI]
        GitHub_Actions[GitHub Actions (CI/CD)]
        Git_Repo[GitHub Repo (Code)]
    end

    subgraph Kubernetes Cluster (on EC2 Master)
        direction TB
        Ingress[Ingress Controller (nginx)]
        CertManager[Cert-Manager]
        ArgoCD[ArgoCD (Optional - Deployed by Pipeline)]
        Apps[Applications (WP, Grafana, etc.)]
    end

    Terraform -- Provisions --> EC2_Master
    Terraform -- Provisions --> EC2_Proxy
    Terraform -- Uses --> S3_Backend
    Terraform -- Configures --> IAM_Roles

    Git_Repo -- Triggers --> GitHub_Actions
    GitHub_Actions -- Runs --> Terraform
    GitHub_Actions -- Deploys --> Ingress
    GitHub_Actions -- Deploys --> CertManager
    GitHub_Actions -- Deploys --> ArgoCD
    GitHub_Actions -- Deploys --> Apps

    User --> EC2_Proxy -- Forwards --> Ingress -- Routes --> Apps

    %% ArgoCD (if used) pulls from Git Repo and deploys Apps
    %% Git_Repo --> ArgoCD --> Apps
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
# Opcional: Crear secrets.tfvars para variables sensibles si no se usan variables de entorno
terraform apply # (o terraform apply -var-file="secrets.tfvars")
```

Despliega la infraestructura AWS e instala k3s en el nodo master.
<!-- Despliega la infraestructura AWS, instala k3s, y despliega los Helm charts base (cert-manager, ingress-nginx, ArgoCD). -->

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
<!--
ArgoCD se expone a través del Ingress en `argocd.adrianmagarola.click` (o el dominio configurado). Terraform configura el Ingress para usar Let's Encrypt.

Obtén la contraseña inicial:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo
```

Accede a la UI de ArgoCD y loguéate con `admin` y la contraseña obtenida.
-->
**(Nota: ArgoCD y otras aplicaciones ahora se desplegarán mediante pipelines de GitHub Actions, no directamente por Terraform.)**

### 5. Despliegue de Aplicaciones (GitOps)
<!--
Las aplicaciones definidas en `apps/*.yaml` (WordPress, Prometheus, Grafana, Wiki.js) deberían empezar a sincronizarse automáticamente en ArgoCD. Verifica su estado en la UI.

*   **WordPress**: Accesible en el dominio principal (`adrianmagarola.click`).
*   **Grafana/Prometheus**: Desplegados en el namespace `monitoring`. Se necesita configurar Ingress o Port-forward para acceder.
*   **Wiki.js**: Desplegado en el namespace `default`. Se necesita configurar Ingress o Port-forward.
-->
**(Nota: Las aplicaciones ahora se desplegarán mediante pipelines de GitHub Actions.)**

### 6. Configuración del Proxy (Opcional - Si no se usa Route53/ALB)

El módulo `proxy` configura NGINX para redirigir el tráfico al NodePort del Ingress Controller. La configuración de certificados en el proxy necesita revisión (actualmente usa autofirmados iniciales y la lógica de copia de certificados Let's Encrypt desde el máster está comentada en `terraform/main.tf`).

## Análisis Detallado del Código

### Terraform
*   **Infraestructura**: Módulos bien definidos (`k3s-cluster`, `proxy`, `helm-releases`). El estado se gestiona remotamente en S3 (requiere configuración inicial del bucket o ajuste del backend).
*   **Automatización**: Se usa `remote-exec` para la instalación y configuración inicial de k3s en el nodo master. Aunque funcional, para configuraciones más complejas se recomienda usar herramientas como Ansible, cloud-init avanzado o imágenes personalizadas (AMI).
*   **Gestión de Secretos**: 
    *   El `data "external" "kubeconfig"` extrae credenciales del clúster para configurar los providers `kubernetes` y `helm`. Esto es práctico pero expone datos sensibles en el estado de Terraform.
    *   Se usan claves SSH (`k3s-key.pem`, `ec2-proxy-key.pem`) directamente en scripts y configuraciones (`null_resource "extract_tls_cert"`). Asegúrate de que `.gitignore` previene su commit.
    *   Se recomienda usar un sistema de gestión de secretos como AWS Secrets Manager o HashiCorp Vault, especialmente para `kubeconfig` y claves.
<!-- *   **Helm Releases**: Desplegar Helm charts con Terraform es útil para componentes base de la infraestructura (cert-manager, ingress, ArgoCD). Asegura la disponibilidad temprana de estos servicios. -->
**(Nota: El despliegue de Helm releases mediante Terraform ha sido comentado para moverlo a pipelines.)**

### Helm Charts
*   **WordPress (`charts/wordpress`)**: Usa el chart oficial de Bitnami MariaDB como dependencia. Las credenciales de WordPress y MariaDB se configuran mediante `values.yaml`. Considera usar secretos de Kubernetes en lugar de pasar todo por `values.yaml` directamente.
*   **Prometheus/Grafana (`charts/prometheus`, `charts/grafana`)**: Charts básicos. No incluyen configuración de Ingress por defecto. Requieren configuración manual o adicional para exponerlos.
*   **Wiki.js (`charts/wikijs`)**: Chart básico, Ingress deshabilitado por defecto.
*   **General**: Los charts son simples. Para producción, requerirían configuración de persistencia robusta, recursos (requests/limits), probes (liveness/readiness) y seguridad más detallada.

<!-- ### ArgoCD -->
<!-- *   **Aplicaciones (`apps/*.yaml`)**: Definen el despliegue GitOps. La política `syncPolicy: { automated: { prune: true, selfHeal: true } }` es adecuada para mantener la sincronización con Git. `syncOptions: [CreateNamespace=true]` es conveniente pero asegúrate de que los namespaces son los deseados. -->
<!-- *   **Configuración Ingress (Terraform)**: El Helm release de ArgoCD en `modules/helm-releases/main.tf` está configurado para usar Ingress con Let's Encrypt. Sin embargo, incluye `server.extraArgs = "{--insecure}"`. **Esto debe eliminarse en un entorno de producción** ya que desactiva validaciones TLS. -->
**(Nota: La configuración y despliegue de ArgoCD mediante Terraform ha sido comentada.)**

### Seguridad
*   **Claves y Certificados**: La gestión de claves SSH y certificados (autofirmados iniciales en proxy, extracción de kubeconfig) es un punto crítico. Evita exponer claves privadas. El uso de `cert-manager` para certificados TLS de Ingress es una buena práctica.
*   **RBAC**: Las políticas RBAC por defecto de k3s, Helm charts y ArgoCD deben revisarse para asegurar el principio de mínimo privilegio.
*   **Red**: Revisa las reglas de los Security Groups de AWS para limitar el acceso a los puertos necesarios (SSH, HTTP/S, API de K8s si es necesario externamente).
<!-- *   **ArgoCD Insecure Flag**: Eliminar `--insecure` de la configuración del Helm release de ArgoCD. -->
**(Nota: La configuración de ArgoCD se gestionará en la pipeline.)**

## Próximos Pasos y Mejoras

- **Gestión de Secretos**: Implementar Vault o AWS Secrets Manager para `kubeconfig`, claves SSH y credenciales de aplicación.
- **Eliminar `remote-exec`**: Usar Ansible, cloud-init o AMI personalizada para la configuración de nodos.
- **Proxy NGINX**: Reemplazar con AWS ALB/NLB o mejorar la gestión de certificados (integrar con cert-manager o copiar certificados de forma segura).
- **Seguridad ArgoCD**: Eliminar el flag `--insecure`.
- **Helm Charts**: Mejorar charts con probes, recursos, HPA, configuración de persistencia avanzada y gestión de secretos vía Kubernetes Secrets.
- **Monitorización**: Configurar Ingress para Prometheus/Grafana y crear dashboards personalizados.
- **CI/CD**: Automatizar `terraform apply` y validaciones con GitHub Actions.
- **Escalado**: Implementar Horizontal Pod Autoscaler (HPA) para aplicaciones como WordPress.
- **Base de Datos**: Considerar RDS en lugar de MariaDB en el clúster para mayor gestionabilidad y rendimiento.

---

Para más información, consulta la documentación oficial de [Terraform](https://www.terraform.io/), [Kubernetes](https://kubernetes.io/), [k3s](https://k3s.io/), [ArgoCD](https://argo-cd.readthedocs.io/), [Helm](https://helm.sh/) y [cert-manager](https://cert-manager.io/).