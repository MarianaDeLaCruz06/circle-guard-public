# Backend bootstrap — MinIO

Despliega un servidor MinIO en el cluster Kubernetes que actua como
**backend remoto S3-compatible** para el estado de Terraform de los
ambientes `dev`, `stage` y `prod`.

Este modulo usa `backend "local"` porque debe ejecutarse antes de que
el backend remoto exista.

## Uso

```bash
cd terraform/global/backend-bootstrap

terraform init
terraform apply
```

Una vez aplicado:

- **MinIO API**: `http://localhost:30900`
- **MinIO Console**: `http://localhost:30901` (usuario `minioadmin` / `minioadmin123` por defecto)
- **Bucket creado**: `terraform-state`

Los ambientes (`terraform/environments/<env>`) ya estan configurados
para usar este endpoint como backend S3. Ver `backend.tf` de cada
ambiente.

## Variables principales

| Variable | Default | Descripcion |
|---|---|---|
| `kubeconfig_context` | `docker-desktop` | Contexto kube a usar |
| `minio_root_user` | `minioadmin` | Credencial backend |
| `minio_root_password` | `minioadmin123` | Credencial backend |
| `bucket_name` | `terraform-state` | Bucket para tfstate files |
| `api_node_port` | `30900` | NodePort de la API S3 |
| `console_node_port` | `30901` | NodePort de la consola web |

## Como autenticar terraform init en los ambientes

Exporta las credenciales antes de ejecutar `terraform init` en cada ambiente:

```powershell
$env:AWS_ACCESS_KEY_ID = "minioadmin"
$env:AWS_SECRET_ACCESS_KEY = "minioadmin123"
```

```bash
export AWS_ACCESS_KEY_ID=minioadmin
export AWS_SECRET_ACCESS_KEY=minioadmin123
```
