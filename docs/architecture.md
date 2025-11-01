# Architecture & Storytelling Guide

This platform is designed to feel familiar to teams who work with AWS analytics tooling—only repackaged with open-source building blocks that you can proudly demo from your homelab. Use this document as a narrative aid when positioning yourself as a Data or Analytics Engineer.

## High-Level Blueprint

```
                  +-------------------+
    Source Feeds  |  Airflow Schedules |---+
   (APIs, Files)  +----------+--------+   |
                              |            |
                              v            v
                       +------------------------+
                       | Spark + Jupyter (ELT)  |
                       |  - Batch & notebooks   |
                       |  - Feature engineering |
                       +-----------+------------+
                                   |
                      +------------+------------+
                      | Iceberg REST Catalog    |
                      | (metadata in Postgres)  |
                      +------------+------------+
                                   |
                      +------------v------------+
                      |      MinIO (S3)         |
                      |  Raw → Bronze → Gold    |
                      +--+--------------+-------+
                         |              |
     +-------------------+              +---------------------+
     |                                                   |
 +---v------------+                      +-----------------v---+
 | Hive Metastore |                      |     MLflow          |
 | (legacy tables)|                      | (tracking & models) |
 +---+------------+                      +---------+-----------+
     |                                              |
 +---v------------+                                 |
 |   Trino        |<--------------------------------+
 | (SQL lakehouse)|-----+-------------------------------+
 +---+------------+     |                               |
     |                  |                               |
 +---v------------+ +---v------------+          +-------v------+
 | Superset (BI)  | | CLI/Notebooks |          | Stakeholders |
 +----------------+ +----------------+          +--------------+
```

Key ideas:
- **Shared object store:** MinIO contains every lifecycle zone, enabling reproducible ELT, SQL, ML, and BI on the same foundation.
- **Separation of concerns:** Metadata lives in PostgreSQL; compute services can be scaled or rebuilt independently.
- **AWS parity:** Each component maps to a familiar AWS service (S3, Glue Catalog, Glue Jobs, MWAA, Athena, SageMaker, QuickSight), making the story resonate with cloud-focused stakeholders.

## Deployment Topology
- **Storage plane (NAS or storage appliance):** MinIO, PostgreSQL, Hive Metastore, Iceberg REST, MLflow, Superset. These services crave fast disks and plenty of RAM.
- **Compute plane (Proxmox/x86 nodes):** Spark + Jupyter, Airflow, Trino. Scale CPU and memory here to match workload demos.
- **Network:** Host networking simplifies cross-host communication. Replace placeholder addresses (`<nas-host>`, `<compute-host>`, `<dns-host>`) with IPs or hostnames from your environment. Use split DNS or `/etc/hosts` to expose friendly names during demos.

## Persona-Led Use Cases

### Data Engineer – Streaming Batch Reconciliation
1. Airflow DAG lands raw CDC batches from operational databases into `s3://landing/`.
2. Spark notebook cleans and merges data, publishing canonical Iceberg tables into `s3://warehouse/bronze` and `s3://warehouse/gold`.
3. Iceberg REST updates the catalog; Trino picks up new snapshots instantly.
4. Airflow triggers data quality SQL checks in Trino before handing datasets off to analysts.

Talking points:
- Emphasise reproducibility (Iceberg snapshots) and quick iteration (Jupyter co-located with Spark).
- Showcase infrastructure-as-code: Docker Compose files mirror Terraform modules you would deploy in the cloud.

### Business Intelligence Engineer – Self-Service Insights
1. Superset connects to Trino using the Iceberg catalog.
2. Analysts build virtual datasets with familiar SQL, joining curated tables and ML predictions.
3. Superset dashboards update on a schedule driven by Airflow, ensuring stakeholders always see fresh data.

Talking points:
- Highlight low-latency queries on columnar Iceberg tables.
- Demonstrate role-based access using PostgreSQL-backed metadata.

### Machine Learning Engineer – Experiment Lifecycle
1. Spark notebooks train models, logging parameters, metrics, and artifacts to MLflow.
2. Artifacts reside in MinIO; registry events trigger Airflow to run evaluation or deployment pipelines.
3. BI teams consume prediction tables in Superset, closing the loop between experimentation and business value.

Talking points:
- Show how MLflow integrates with the rest of the lakehouse—no siloed storage.
- Discuss how the same pattern maps to Amazon SageMaker or Databricks managed services.

## Demo Checklist
- Prepare sample datasets (e.g., NYC Taxi or TPC-DS) and pre-load them into MinIO.
- Script a short Airflow run that performs ingestion, transformation, and validation in one pass.
- Build a Superset dashboard that references the transformed tables and includes a chart driven by MLflow outputs.
- Keep slides/screenshots ready to explain how the homelab layout maps to enterprise cloud patterns.

Use this repository as both a hands-on playground and a portfolio asset—walk recruiters through the architecture diagram, highlight the AWS parallels, and then fire up the demo environment to prove every component works together.***
