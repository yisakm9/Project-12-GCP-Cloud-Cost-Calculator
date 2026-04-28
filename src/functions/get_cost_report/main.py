# src/functions/get_cost_report/main.py
#
# Cloud Function (2nd Gen) — Pub/Sub-triggered via Cloud Scheduler
# Queries BigQuery billing export for weekly costs and sends an
# HTML email report using the SendGrid API.

import functions_framework
import os
import json
import base64
from datetime import datetime, timedelta
from google.cloud import bigquery
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Content

# ──────────────────────────────────────────────
#  Configuration from environment variables
# ──────────────────────────────────────────────
BILLING_PROJECT_ID = os.environ.get("BILLING_PROJECT_ID")
BILLING_DATASET_ID = os.environ.get("BILLING_DATASET_ID")
BILLING_TABLE_ID = os.environ.get("BILLING_TABLE_ID")
SENDGRID_API_KEY = os.environ.get("SENDGRID_API_KEY")
SENDER_EMAIL = os.environ.get("SENDER_EMAIL")
RECIPIENT_EMAIL = os.environ.get("RECIPIENT_EMAIL")

# Initialize BigQuery client
bq_client = bigquery.Client()

# ──────────────────────────────────────────────
#  GCP Service Name Mappings
# ──────────────────────────────────────────────
SERVICE_MAPPINGS = {
    "Compute Engine": "Compute Engine (VMs)",
    "Cloud Functions": "Cloud Functions (Serverless)",
    "Cloud Run": "Cloud Run (Serverless Containers)",
    "Google Kubernetes Engine": "GKE (Managed Kubernetes)",
    "App Engine": "App Engine (PaaS)",
    "Cloud Storage": "Cloud Storage (Object Storage)",
    "Persistent Disk": "Persistent Disk (Block Storage)",
    "Filestore": "Filestore (Managed NFS)",
    "Cloud SQL": "Cloud SQL (Managed RDBMS)",
    "Cloud Spanner": "Cloud Spanner (Global SQL)",
    "Cloud Bigtable": "Cloud Bigtable (NoSQL)",
    "Firestore": "Firestore (Document NoSQL)",
    "Memorystore": "Memorystore (In-Memory Cache)",
    "AlloyDB": "AlloyDB (PostgreSQL Compatible)",
    "BigQuery": "BigQuery (Data Warehouse)",
    "Dataflow": "Dataflow (Stream/Batch Processing)",
    "Dataproc": "Dataproc (Hadoop/Spark)",
    "Pub/Sub": "Pub/Sub (Messaging)",
    "Cloud DNS": "Cloud DNS (DNS Service)",
    "Cloud CDN": "Cloud CDN (Content Delivery)",
    "Cloud Load Balancing": "Cloud Load Balancing",
    "Cloud NAT": "Cloud NAT (Network Translation)",
    "Cloud Armor": "Cloud Armor (WAF + DDoS)",
    "Cloud Logging": "Cloud Logging",
    "Cloud Monitoring": "Cloud Monitoring",
    "Secret Manager": "Secret Manager (Secrets)",
    "Cloud Key Management Service": "Cloud KMS (Encryption Keys)",
    "Vertex AI": "Vertex AI (ML Platform)",
    "Cloud Build": "Cloud Build (CI/CD)",
    "Artifact Registry": "Artifact Registry (Containers)",
    "Cloud Scheduler": "Cloud Scheduler (Cron Jobs)",
    "Networking": "Networking (VPC & Egress)",
    "Support": "Google Cloud Support",
}


@functions_framework.cloud_event
def generate_cost_report(cloud_event):
    """
    Pub/Sub Cloud Function entry point.
    Triggered weekly by Cloud Scheduler via Pub/Sub.
    Queries BigQuery for the last 7 days of cost data and
    sends a formatted HTML email report via SendGrid.
    """
    # Validate configuration
    required_vars = [BILLING_PROJECT_ID, BILLING_DATASET_ID, BILLING_TABLE_ID,
                     SENDGRID_API_KEY, SENDER_EMAIL, RECIPIENT_EMAIL]
    if not all(required_vars):
        print("ERROR: Missing required environment variables.")
        return

    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=7)
    start_str = start_date.strftime("%Y-%m-%d")
    end_str = end_date.strftime("%Y-%m-%d")

    try:
        cost_data = _query_billing_data(start_str, end_str)
        email_html = _create_email_body(cost_data, start_str, end_str)
        _send_email(email_html, start_str, end_str)
        print(f"Cost report sent successfully for period {start_str} to {end_str}")
    except Exception as e:
        print(f"Error generating cost report: {e}")
        raise


def _query_billing_data(start_date: str, end_date: str) -> list:
    """Queries BigQuery billing export for cost data grouped by service."""
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

    cost_data = []
    for row in results:
        cost = float(row.total_cost or 0)
        credits = float(row.total_credits or 0)
        net_cost = cost + credits
        if net_cost > 0.005:
            friendly_name = SERVICE_MAPPINGS.get(row.service_name, row.service_name)
            cost_data.append({
                "service": friendly_name,
                "cost": round(net_cost, 2),
                "gross_cost": round(cost, 2),
                "credits": round(credits, 2),
            })
    return cost_data


def _create_email_body(cost_data: list, start_date: str, end_date: str) -> str:
    """Generates a styled HTML email body from the cost data."""
    total_cost = sum(item["cost"] for item in cost_data)
    total_gross = sum(item["gross_cost"] for item in cost_data)
    total_credits = sum(item["credits"] for item in cost_data)

    rows_html = ""
    for item in cost_data:
        rows_html += f"""
        <tr>
            <td style="padding: 12px 16px; border-bottom: 1px solid #e0e0e0;
                        font-family: 'Google Sans', Arial, sans-serif; font-size: 14px;">
                {item['service']}
            </td>
            <td style="padding: 12px 16px; border-bottom: 1px solid #e0e0e0;
                        text-align: right; font-family: 'Google Sans', Arial, sans-serif;
                        font-size: 14px; font-weight: 500;">
                ${item['cost']:.2f}
            </td>
        </tr>
        """

    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="margin: 0; padding: 0; background-color: #f8f9fa;
                 font-family: 'Google Sans', Arial, sans-serif;">
        <div style="max-width: 640px; margin: 0 auto; padding: 32px 16px;">
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #1a73e8 0%, #4285f4 50%, #34a853 100%);
                        border-radius: 16px 16px 0 0; padding: 32px; text-align: center;">
                <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 500;">
                    ☁️ GCP Weekly Cost Report
                </h1>
                <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0; font-size: 14px;">
                    {start_date} — {end_date}
                </p>
            </div>

            <!-- Summary Cards -->
            <div style="background: #ffffff; padding: 24px; border-left: 1px solid #e0e0e0;
                        border-right: 1px solid #e0e0e0;">
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align: center; padding: 16px;">
                            <div style="font-size: 12px; color: #5f6368; text-transform: uppercase;
                                        letter-spacing: 1px;">Net Cost</div>
                            <div style="font-size: 32px; font-weight: 700; color: #1a73e8;
                                        margin-top: 4px;">${total_cost:.2f}</div>
                        </td>
                        <td style="text-align: center; padding: 16px;
                                    border-left: 1px solid #e0e0e0;">
                            <div style="font-size: 12px; color: #5f6368; text-transform: uppercase;
                                        letter-spacing: 1px;">Credits Applied</div>
                            <div style="font-size: 32px; font-weight: 700; color: #34a853;
                                        margin-top: 4px;">${abs(total_credits):.2f}</div>
                        </td>
                    </tr>
                </table>
            </div>

            <!-- Cost Table -->
            <div style="background: #ffffff; border: 1px solid #e0e0e0; border-top: none;">
                <table width="100%" cellpadding="0" cellspacing="0">
                    <thead>
                        <tr style="background-color: #f1f3f4;">
                            <th style="padding: 12px 16px; text-align: left; font-size: 12px;
                                        color: #5f6368; text-transform: uppercase;
                                        letter-spacing: 1px; font-weight: 600;">
                                Service
                            </th>
                            <th style="padding: 12px 16px; text-align: right; font-size: 12px;
                                        color: #5f6368; text-transform: uppercase;
                                        letter-spacing: 1px; font-weight: 600;">
                                Cost (USD)
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                        {rows_html}
                    </tbody>
                    <tfoot>
                        <tr style="background-color: #e8f0fe;">
                            <td style="padding: 14px 16px; font-weight: 700; font-size: 15px;
                                        color: #1a73e8;">
                                Total Estimated Cost
                            </td>
                            <td style="padding: 14px 16px; text-align: right; font-weight: 700;
                                        font-size: 15px; color: #1a73e8;">
                                ${total_cost:.2f}
                            </td>
                        </tr>
                    </tfoot>
                </table>
            </div>

            <!-- Footer -->
            <div style="background: #f1f3f4; border-radius: 0 0 16px 16px;
                        padding: 20px; text-align: center;
                        border: 1px solid #e0e0e0; border-top: none;">
                <p style="color: #5f6368; font-size: 12px; margin: 0;">
                    Generated by <strong>GCP Cloud Cost Calculator</strong> •
                    Powered by BigQuery Billing Export
                </p>
            </div>
        </div>
    </body>
    </html>
    """
    return html


def _send_email(html_body: str, start_date: str, end_date: str):
    """Sends the cost report email via SendGrid API."""
    subject = f"GCP Weekly Cost Report: {start_date} to {end_date}"

    message = Mail(
        from_email=SENDER_EMAIL,
        to_emails=RECIPIENT_EMAIL,
        subject=subject,
        html_content=Content("text/html", html_body),
    )

    sg = SendGridAPIClient(SENDGRID_API_KEY)
    response = sg.send(message)
    print(f"SendGrid response status: {response.status_code}")
