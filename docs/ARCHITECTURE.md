# Architecture Decision Record — GCP Cloud Cost Calculator

## ADR-001: Migration from AWS to GCP

**Status:** Accepted
**Date:** 2026-04-28
**Context:** The original Cloud Cost Calculator was built on AWS using Lambda, API Gateway, S3, CloudFront, CloudWatch, SNS, SES, and KMS. The goal was to rebuild it as a production-grade GCP-native project demonstrating equivalent or superior cloud engineering practices.

---

## Architecture Overview

### Design Principles

1. **Serverless-First** — All compute runs on Cloud Functions (Gen2) with scale-to-zero. No VMs, no containers to manage.
2. **Event-Driven** — Cloud Scheduler → Pub/Sub → Cloud Functions for the reporting pipeline. Budget alerts flow through Pub/Sub → Cloud Monitoring.
3. **Infrastructure as Code** — 100% of infrastructure defined in 9 modular Terraform modules. Zero manual console clicks.
4. **Least Privilege** — Each Cloud Function has a dedicated service account with only the permissions it needs.
5. **Defense in Depth** — Cloud KMS encryption, Secret Manager for API keys, Checkov security scanning in CI.

---

## Service Selection Rationale

### Compute: Cloud Functions (Gen2) over Cloud Run

Cloud Functions Gen2 was chosen over Cloud Run because:
- The workload is pure request/response (API) and event-triggered (report) — no long-running processes
- Gen2 provides built-in HTTP endpoints (no API Gateway needed)
- Gen2 supports Pub/Sub triggers natively via Eventarc
- Scale-to-zero reduces cost to near-zero during idle periods

### Data: BigQuery Billing Export over Cloud Billing API

BigQuery billing export was chosen because:
- It provides granular, service-level cost breakdowns (the Cloud Billing API does not)
- Supports arbitrary date ranges and SQL-based analysis
- Data is automatically exported — no polling required
- First 1TB of queries per month is free

### CDN: Cloud CDN + Global LB over Firebase Hosting

The Global HTTP(S) Load Balancer with Cloud CDN was chosen because:
- URL-based routing enables both frontend (/*) and API (/costs) on a single IP
- Cloud CDN provides automatic caching for static assets
- The Load Balancer supports future HTTPS + custom domain upgrades
- It demonstrates enterprise-grade networking (vs. Firebase's simpler model)

### Email: SendGrid over Native GCP

SendGrid was chosen because:
- GCP has no native email delivery service equivalent to AWS SES
- SendGrid offers a free tier (100 emails/day)
- The API key is stored securely in Secret Manager and injected at runtime

### Scheduling: Cloud Scheduler + Pub/Sub over Direct HTTP

The Cloud Scheduler → Pub/Sub → Cloud Function pattern was chosen because:
- Pub/Sub provides automatic retries with exponential backoff
- The Cloud Function doesn't need to be publicly accessible (ingress: ALLOW_INTERNAL_ONLY)
- Decouples the trigger from the execution for better observability

---

## Security Architecture

```
┌─────────────────────────────────────────────────┐
│                  Security Layers                 │
├─────────────────────────────────────────────────┤
│  CI/CD Auth    │ Workload Identity Federation   │
│                │ (OIDC — no service account keys)│
├────────────────┼────────────────────────────────┤
│  Secrets       │ Secret Manager                  │
│                │ (SendGrid key never in code)     │
├────────────────┼────────────────────────────────┤
│  Encryption    │ Cloud KMS                       │
│                │ (auto-rotation every 90 days)    │
├────────────────┼────────────────────────────────┤
│  IAM           │ 2 dedicated service accounts    │
│                │ (least-privilege bindings)       │
├────────────────┼────────────────────────────────┤
│  Network       │ Report function: INTERNAL_ONLY  │
│                │ API function: Public (read-only) │
├────────────────┼────────────────────────────────┤
│  Code Scanning │ TFLint + Checkov in CI pipeline │
├────────────────┼────────────────────────────────┤
│  State         │ GCS with versioning enabled     │
└────────────────┴────────────────────────────────┘
```

---

## Cost Analysis

The GCP version is significantly cheaper than the AWS version:

| Component | AWS Cost | GCP Cost | Savings |
|-----------|---------|---------|---------|
| Compute (Lambda vs Functions) | ~$10-16 | ~$0-2 | 80-100% |
| CDN (CloudFront vs Cloud CDN) | ~$1-5 | Included in LB | 100% |
| Load Balancer | N/A (CloudFront) | ~$18 | — |
| Data queries | $0 (Cost Explorer API) | ~$0-1 (BigQuery) | — |
| Storage | ~$0.50 | ~$0.01 | 98% |
| **Total** | **~$45-55** | **~$18-22** | **~60%** |

The main cost driver is the Global HTTP(S) Load Balancer ($18/month). For a development environment, this could be eliminated by using the Cloud Function URL directly.
