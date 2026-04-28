# src/functions/get_cost_api/main.py
#
# Cloud Function (2nd Gen) — HTTP-triggered
# Queries BigQuery billing export and returns a JSON cost breakdown.

import functions_framework
import os
import json
from datetime import datetime, timedelta
from google.cloud import bigquery

# ──────────────────────────────────────────────
#  Configuration from environment variables
# ──────────────────────────────────────────────
BILLING_PROJECT_ID = os.environ.get("BILLING_PROJECT_ID")
BILLING_DATASET_ID = os.environ.get("BILLING_DATASET_ID")
BILLING_TABLE_ID = os.environ.get("BILLING_TABLE_ID")

# Initialize BigQuery client
bq_client = bigquery.Client()

# ──────────────────────────────────────────────
#  GCP Service Name Mappings
#  Maps technical billing descriptions to
#  user-friendly names for the dashboard.
# ──────────────────────────────────────────────
SERVICE_MAPPINGS = {
    # --- Compute ---
    "Compute Engine": "Compute Engine (VMs)",
    "Cloud Functions": "Cloud Functions (Serverless)",
    "Cloud Run": "Cloud Run (Serverless Containers)",
    "Google Kubernetes Engine": "GKE (Managed Kubernetes)",
    "App Engine": "App Engine (PaaS)",
    "Cloud GPUs": "Cloud GPUs (Accelerators)",
    "VMware Engine": "VMware Engine (Hybrid Cloud)",
    "Sole-Tenant Nodes": "Sole-Tenant Nodes (Dedicated VMs)",
    "Batch": "Batch (Managed Batch Processing)",

    # --- Storage ---
    "Cloud Storage": "Cloud Storage (Object Storage)",
    "Persistent Disk": "Persistent Disk (Block Storage)",
    "Filestore": "Filestore (Managed NFS)",
    "Cloud Storage for Firebase": "Firebase Storage",
    "NetApp Volumes": "NetApp Volumes (Enterprise NAS)",
    "Backup and DR": "Backup and DR (Data Protection)",
    "Archive Storage": "Archive Storage (Cold Storage)",

    # --- Database ---
    "Cloud SQL": "Cloud SQL (Managed RDBMS)",
    "Cloud Spanner": "Cloud Spanner (Global SQL)",
    "Cloud Bigtable": "Cloud Bigtable (Wide-Column NoSQL)",
    "Firestore": "Firestore (Document NoSQL)",
    "Memorystore": "Memorystore (In-Memory Cache)",
    "AlloyDB": "AlloyDB (PostgreSQL Compatible)",
    "Database Migration Service": "DMS (Database Migration)",
    "Datastream": "Datastream (CDC Replication)",
    "Firebase Realtime Database": "Firebase Realtime DB",

    # --- Networking ---
    "Cloud DNS": "Cloud DNS (DNS Service)",
    "Cloud CDN": "Cloud CDN (Content Delivery)",
    "Cloud Load Balancing": "Cloud Load Balancing",
    "Cloud NAT": "Cloud NAT (Network Translation)",
    "Cloud Interconnect": "Cloud Interconnect (Dedicated Network)",
    "Cloud VPN": "Cloud VPN (Secure Tunnel)",
    "Cloud Armor": "Cloud Armor (WAF + DDoS)",
    "Traffic Director": "Traffic Director (Service Mesh)",
    "Network Intelligence Center": "Network Intelligence Center",
    "VPC": "VPC (Virtual Private Cloud)",
    "Cloud Router": "Cloud Router (Dynamic Routing)",
    "Network Connectivity Center": "Network Connectivity Center",
    "Private Service Connect": "Private Service Connect",

    # --- Big Data & Analytics ---
    "BigQuery": "BigQuery (Data Warehouse)",
    "BigQuery BI Engine": "BigQuery BI Engine",
    "BigQuery Reservation API": "BigQuery Reservations",
    "Dataflow": "Dataflow (Stream/Batch Processing)",
    "Dataproc": "Dataproc (Hadoop/Spark)",
    "Pub/Sub": "Pub/Sub (Messaging)",
    "Cloud Composer": "Cloud Composer (Airflow)",
    "Data Fusion": "Data Fusion (ETL)",
    "Dataprep by Trifacta": "Dataprep (Data Wrangling)",
    "Looker": "Looker (BI Platform)",
    "Data Catalog": "Data Catalog (Metadata)",
    "Analytics Hub": "Analytics Hub (Data Exchange)",
    "Dataplex": "Dataplex (Data Governance)",

    # --- AI & Machine Learning ---
    "Vertex AI": "Vertex AI (ML Platform)",
    "Cloud Natural Language API": "Natural Language API (NLP)",
    "Cloud Vision API": "Vision API (Image Analysis)",
    "Cloud Video Intelligence API": "Video AI (Video Analysis)",
    "Cloud Translation API": "Translation API",
    "Cloud Text-to-Speech API": "Text-to-Speech API",
    "Cloud Speech-to-Text API": "Speech-to-Text API",
    "Dialogflow": "Dialogflow (Conversational AI)",
    "Document AI": "Document AI (OCR)",
    "Recommendations AI": "Recommendations AI",
    "Cloud AutoML": "AutoML (Custom Models)",
    "Generative AI": "Generative AI (Foundation Models)",

    # --- Management & Governance ---
    "Cloud Logging": "Cloud Logging",
    "Cloud Monitoring": "Cloud Monitoring",
    "Cloud Trace": "Cloud Trace (Distributed Tracing)",
    "Cloud Debugger": "Cloud Debugger",
    "Cloud Profiler": "Cloud Profiler",
    "Error Reporting": "Error Reporting",
    "Cloud Deployment Manager": "Deployment Manager (IaC)",
    "Config Management": "Config Management",

    # --- Security & Identity ---
    "Secret Manager": "Secret Manager (Secrets)",
    "Cloud Key Management Service": "Cloud KMS (Encryption Keys)",
    "Cloud IAM": "Cloud IAM (Access Control)",
    "Identity-Aware Proxy": "IAP (Identity-Aware Proxy)",
    "Security Command Center": "SCC (Security Posture)",
    "Certificate Authority Service": "CAS (Private CA)",
    "Binary Authorization": "Binary Authorization",
    "VPC Service Controls": "VPC Service Controls",
    "Cloud Data Loss Prevention": "Cloud DLP (Data Protection)",
    "Chronicle": "Chronicle (Security Analytics)",
    "reCAPTCHA Enterprise": "reCAPTCHA Enterprise",
    "Web Security Scanner": "Web Security Scanner",

    # --- Developer Tools ---
    "Cloud Build": "Cloud Build (CI/CD)",
    "Artifact Registry": "Artifact Registry (Containers)",
    "Cloud Source Repositories": "Cloud Source Repos (Git)",
    "Cloud Scheduler": "Cloud Scheduler (Cron Jobs)",
    "Cloud Tasks": "Cloud Tasks (Task Queue)",
    "Workflows": "Workflows (Orchestration)",
    "Eventarc": "Eventarc (Event Routing)",
    "Cloud Shell": "Cloud Shell (Browser CLI)",

    # --- Serverless ---
    "Cloud Endpoints": "Cloud Endpoints (API Gateway)",
    "API Gateway": "API Gateway (Managed APIs)",
    "Apigee API Management": "Apigee (Enterprise API Platform)",

    # --- IoT ---
    "Cloud IoT Core": "IoT Core (Device Management)",

    # --- Migration ---
    "Migrate to Virtual Machines": "Migrate to VMs",
    "Transfer Appliance": "Transfer Appliance (Data Migration)",
    "Storage Transfer Service": "Storage Transfer Service",

    # --- Other ---
    "Support": "Google Cloud Support",
    "Invoice": "Invoice Charges",
    "Marketplace": "Marketplace Applications",
    "Firebase": "Firebase Platform",
}


@functions_framework.http
def get_cost_data(request):
    """
    HTTP Cloud Function entry point.
    Queries BigQuery billing export for the last 7 days of cost data,
    grouped by GCP service, and returns a JSON response.
    """
    # Handle CORS preflight
    if request.method == "OPTIONS":
        headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Max-Age": "3600",
        }
        return ("", 204, headers)

    cors_headers = {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json",
    }

    # Validate configuration
    if not all([BILLING_PROJECT_ID, BILLING_DATASET_ID, BILLING_TABLE_ID]):
        return (
            json.dumps({"error": "Billing export environment variables not configured."}),
            500,
            cors_headers,
        )

    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=7)
    start_str = start_date.strftime("%Y-%m-%d")
    end_str = end_date.strftime("%Y-%m-%d")

    try:
        payload = _query_billing_data(start_str, end_str)
        return (json.dumps(payload), 200, cors_headers)

    except Exception as e:
        print(f"Error querying billing data: {e}")
        return (
            json.dumps({"error": f"Failed to retrieve cost data: {str(e)}"}),
            500,
            cors_headers,
        )


def _query_billing_data(start_date: str, end_date: str) -> dict:
    """
    Queries the BigQuery billing export table for cost data
    grouped by service within the given date range.
    """
    table_ref = f"`{BILLING_PROJECT_ID}.{BILLING_DATASET_ID}.{BILLING_TABLE_ID}`"

    query = f"""
        SELECT
            service.description AS service_name,
            SUM(cost) AS total_cost,
            SUM(IFNULL(
                (SELECT SUM(c.amount) FROM UNNEST(credits) c), 0
            )) AS total_credits
        FROM {table_ref}
        WHERE DATE(usage_start_time) >= @start_date
          AND DATE(usage_start_time) < @end_date
        GROUP BY service_name
        ORDER BY total_cost DESC
    """

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("start_date", "DATE", start_date),
            bigquery.ScalarQueryParameter("end_date", "DATE", end_date),
        ]
    )

    query_job = bq_client.query(query, job_config=job_config)
    results = query_job.result()

    services_with_cost = []
    total_cost = 0.0
    total_credits = 0.0

    for row in results:
        cost = float(row.total_cost or 0)
        credits = float(row.total_credits or 0)
        net_cost = cost + credits  # credits are negative

        if net_cost > 0.005:  # Filter out sub-penny costs
            friendly_name = SERVICE_MAPPINGS.get(row.service_name, row.service_name)
            services_with_cost.append({
                "service": friendly_name,
                "cost": round(net_cost, 2),
                "grossCost": round(cost, 2),
                "credits": round(credits, 2),
            })
            total_cost += cost
            total_credits += credits

    return {
        "provider": "Google Cloud Platform",
        "reportingPeriod": {"start": start_date, "end": end_date},
        "totalCost": round(total_cost + total_credits, 2),
        "totalGrossCost": round(total_cost, 2),
        "totalCredits": round(total_credits, 2),
        "costsByService": services_with_cost,
        "serviceCount": len(services_with_cost),
        "generatedAt": datetime.utcnow().isoformat() + "Z",
    }
