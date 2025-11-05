# Google Cloud Run Deployment Guide

This guide explains how to deploy pgAdmin to Google Cloud Run using Cloud Build.

## Prerequisites

1. **Google Cloud SDK**: Install and authenticate with `gcloud`
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Project ID**: Set your Google Cloud Project ID
   ```bash
   export PROJECT_ID="your-project-id"
   ```

3. **APIs Enabled**: The deployment script will enable these automatically, or you can enable them manually:
   - Cloud Build API
   - Cloud Run API
   - Artifact Registry API

## Quick Start

### Option 1: Using the Deployment Script (Recommended)

1. Set your project ID:
   ```bash
   export PROJECT_ID="your-project-id"
   ```

2. Set your pgAdmin password (required):
   ```bash
   export PGADMIN_PASSWORD="your-secure-password"
   ```

3. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

The script will:
- Enable required APIs
- Create Artifact Registry repository if needed
- Build and push the Docker image
- Deploy to Cloud Run

### Option 2: Using Cloud Build Command Directly

```bash
gcloud builds submit \
  --config=cloudbuild.yaml \
  --substitutions="_REGION=us-central1,_REPO_NAME=docker-repo,_SERVICE_NAME=pgadmin,_PGADMIN_EMAIL=admin@example.com,_PGADMIN_PASSWORD=your-password,_PGADMIN_SERVER_MODE=False"
```

## Configuration Options

You can customize the deployment by setting environment variables before running the script:

```bash
export REGION="us-west1"                    # GCP region
export REPO_NAME="docker-repo"              # Artifact Registry repo name
export SERVICE_NAME="pgadmin"               # Cloud Run service name
export PGADMIN_EMAIL="admin@example.com"    # pgAdmin login email
export PGADMIN_PASSWORD="secure-password"   # pgAdmin login password
export PGADMIN_SERVER_MODE="False"          # Server mode (True/False)
export MEMORY="1Gi"                         # Container memory
export CPU="2"                              # Number of CPUs
export MIN_INSTANCES="1"                    # Minimum instances (0 for scale-to-zero)
export MAX_INSTANCES="10"                   # Maximum instances
export TIMEOUT="600"                        # Request timeout in seconds
```

## Manual Deployment Steps

If you prefer to deploy manually:

### 1. Enable APIs
```bash
gcloud services enable \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com
```

### 2. Create Artifact Registry Repository
```bash
gcloud artifacts repositories create docker-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Docker repository for pgAdmin"
```

### 3. Build and Deploy
```bash
gcloud builds submit --config=cloudbuild.yaml
```

### 4. Set Environment Variables (if not in cloudbuild.yaml)
```bash
gcloud run services update pgadmin \
  --region=us-central1 \
  --set-env-vars="PGADMIN_DEFAULT_EMAIL=admin@example.com,PGADMIN_DEFAULT_PASSWORD=your-password"
```

## Access Your Service

After deployment, get your service URL:

```bash
gcloud run services describe pgadmin \
  --region=us-central1 \
  --format="value(status.url)"
```

Then access pgAdmin in your browser using:
- **URL**: The URL from above
- **Email**: The email you configured (default: `admin@example.com`)
- **Password**: The password you configured

## Security Best Practices

1. **Use Secrets Manager for Passwords**:
   Instead of passing passwords in substitutions, use Google Secret Manager:
   
   ```bash
   # Create secret
   echo -n "your-password" | gcloud secrets create pgadmin-password --data-file=-
   
   # Update Cloud Run service to use secret
   gcloud run services update pgadmin \
     --region=us-central1 \
     --update-secrets="PGADMIN_DEFAULT_PASSWORD=pgadmin-password:latest"
   ```

2. **Enable Authentication** (remove `--allow-unauthenticated`):
   ```bash
   gcloud run services update pgadmin \
     --region=us-central1 \
     --no-allow-unauthenticated
   ```

3. **Use HTTPS**: Cloud Run automatically provides HTTPS for your service

## Troubleshooting

### Build Fails
- Check that all required APIs are enabled
- Verify your gcloud authentication: `gcloud auth list`
- Check Cloud Build logs in the Google Cloud Console

### Service Won't Start
- Verify environment variables are set correctly
- Check Cloud Run logs: `gcloud run services logs read pgadmin --region=us-central1`
- Ensure PORT is set to 8080 (already configured in Dockerfile)

### Cannot Access Service
- Verify the service is deployed: `gcloud run services list`
- Check IAM permissions if authentication is enabled
- Verify the service URL is correct

## Updating the Service

To update the service with new code:

```bash
# Just run the deployment script again
./deploy.sh
```

Or rebuild and redeploy:

```bash
gcloud builds submit --config=cloudbuild.yaml
```

## Cleanup

To remove the service:

```bash
gcloud run services delete pgadmin --region=us-central1
```

To remove the Artifact Registry repository:

```bash
gcloud artifacts repositories delete docker-repo --location=us-central1
```

## Additional Resources

- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)



