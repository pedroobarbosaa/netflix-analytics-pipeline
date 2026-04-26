# Arquitetura do Pipeline

## Visão Geral

```
CSV Files (dados brutos)
       ↓
Google Cloud Storage (GCS)
Bucket: gs://pedro-barbosa-netflix-data/bronze/
       ↓
BigQuery: dataset netflix_raw
(tabelas externas — espelho dos CSVs)
       ↓
BigQuery: dataset netflix_analytical
(tabelas físicas e views tratadas)
       ↓
Metabase (Docker)
Dashboard interativo
```

## Camadas

### Bronze — GCS + netflix_raw
Dados brutos sem transformação. Tabelas externas no BigQuery apontam diretamente para os CSVs no GCS. Todas as colunas em STRING para evitar erros de ingestão.

### Analytical — netflix_analytical
Dados tratados, tipados e modelados seguindo Star Schema. Separa responsabilidades entre tabelas físicas (dim/fact) e views analíticas.

## Decisões de Design

- **Tabelas externas na camada raw:** evita duplicar dados, leitura direta do GCS
- **SAFE_CAST em vez de CAST:** tolerância a falhas na conversão de tipos
- **UNION ALL para fact_ratings:** consolida duas fontes de avaliações mantendo rastreabilidade via coluna `src`
- **Views sobre views:** cada camada tem responsabilidade única, facilita manutenção
- **Docker para Metabase:** portabilidade e isolamento do ambiente de visualização
