# Diagramas

## architecture.mermaid

Diagrama del modelo de infraestructura desplegado por Terraform.

Para visualizarlo:

- **VS Code**: instala la extension "Markdown Preview Mermaid Support"
- **CLI**: `npx -p @mermaid-js/mermaid-cli mmdc -i architecture.mermaid -o architecture.png`
- **Online**: pegalo en https://mermaid.live

## Componentes representados

1. **Backend remoto (terraform-backend ns)**: MinIO S3-compatible que aloja el bucket `terraform-state`.
2. **Stack CircleGuard (3 ambientes)**: ConfigMap + Secret compartidos, 4 componentes stateful (Postgres, Neo4j, Kafka+ZK, Redis), 6 microservicios.
3. **Flujos**: dependencias entre microservicios y stores, mas wiring de configuracion.
