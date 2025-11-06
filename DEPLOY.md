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
   - Cloud Storage API

4. **Cloud Storage Bucket**: A Cloud Storage bucket for persistent pgAdmin data (will be created by the script if it doesn't exist, or you can create it manually)

5. **Service Accounts**: Cloud Run service account with permissions to access the Cloud Storage bucket (the deployment uses service accounts for secure access)

## Quick Start

### Option 1: Using the Deployment Script (Recommended)

1. Set your project ID (required):
   ```bash
   export PROJECT_ID="your-project-id"
   ```

2. (Optional) Customize deployment settings:
   ```bash
   export REGION="us-central1"
   export REPO_NAME="docker-repo"
   export SERVICE_NAME="pgadmin"
   export BUCKET_NAME="pgadmin-bucket-name"
   export SERVICE_ACCOUNT="pgadmin-service-account@project.iam.gserviceaccount.com"
   export CLOUD_BUILD_SERVICE_ACCOUNT="cloudbuild@project.iam.gserviceaccount.com"
   ```

3. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

The script will:
- Enable required APIs
- Create Artifact Registry repository if needed
- Build and push the Docker image to Artifact Registry
- Deploy to Cloud Run with Cloud Storage volume mount for persistent data

4. Set pgAdmin credentials after deployment:
   ```bash
   gcloud run services update pgadmin \
     --region=us-central1 \
     --set-env-vars="PGADMIN_DEFAULT_EMAIL=admin@example.com,PGADMIN_DEFAULT_PASSWORD=your-password"
   ```

### Option 2: Using Cloud Build Command Directly

```bash
gcloud builds submit \
  --config=cloudbuild.yaml \
  --substitutions="_REGION=us-central1,_REPO_NAME=docker-repo,_SERVICE_NAME=pgadmin,_MIN_INSTANCES=0,_MAX_INSTANCES=10,_BUCKET_NAME=your-bucket-name,_SERVICE_ACCOUNT=your-service-account@project.iam.gserviceaccount.com"
```

## Configuration Options

You can customize the deployment by setting environment variables before running the script:

```bash
export REGION="us-central1"                           # GCP region
export REPO_NAME="docker-repo"                       # Artifact Registry repo name
export SERVICE_NAME="pgadmin"                        # Cloud Run service name
export MIN_INSTANCES="0"                             # Minimum instances (0 for scale-to-zero)
export MAX_INSTANCES="10"                            # Maximum instances
export BUCKET_NAME="your-bucket-name"                # Cloud Storage bucket for pgAdmin data
export SERVICE_ACCOUNT="service-account@project.iam.gserviceaccount.com"  # Cloud Run service account
export CLOUD_BUILD_SERVICE_ACCOUNT="cloudbuild@project.iam.gserviceaccount.com"  # Cloud Build service account (for impersonation)
```

**Note**: pgAdmin credentials (email and password) should be configured via Cloud Run environment variables after deployment, or set during the initial deployment using Cloud Run environment variables. See the "Setting pgAdmin Credentials" section below.

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

### 3. Create Cloud Storage Bucket
Create a Cloud Storage bucket for pgAdmin persistent data:

```bash
gsutil mb -p ${PROJECT_ID} -l us-central1 gs://pgadmin-bucket-name
```

### 4. Create Service Accounts
Create a service account for Cloud Run:

```bash
gcloud iam service-accounts create pgadmin-service-account \
  --display-name="pgAdmin Cloud Run Service Account"
```

Grant the service account permissions to access the Cloud Storage bucket:

```bash
gsutil iam ch serviceAccount:pgadmin-service-account@${PROJECT_ID}.iam.gserviceaccount.com:objectAdmin gs://pgadmin-bucket-name
```

### 5. Build and Deploy
```bash
gcloud builds submit \
  --config=cloudbuild.yaml \
  --substitutions="_REGION=us-central1,_REPO_NAME=docker-repo,_SERVICE_NAME=pgadmin,_MIN_INSTANCES=0,_MAX_INSTANCES=10,_BUCKET_NAME=pgadmin-bucket-name,_SERVICE_ACCOUNT=pgadmin-service-account@${PROJECT_ID}.iam.gserviceaccount.com"
```

### 6. Set pgAdmin Credentials
Set environment variables for pgAdmin login:

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

## Setting pgAdmin Credentials

pgAdmin requires email and password to be set via environment variables. You can set these during or after deployment:

### During Initial Deployment

Add environment variables when deploying:

```bash
gcloud run deploy pgadmin \
  --image=your-image \
  --region=us-central1 \
  --set-env-vars="PGADMIN_DEFAULT_EMAIL=admin@example.com,PGADMIN_DEFAULT_PASSWORD=your-password"
```

### After Deployment

Update the service with credentials:

```bash
gcloud run services update pgadmin \
  --region=us-central1 \
  --set-env-vars="PGADMIN_DEFAULT_EMAIL=admin@example.com,PGADMIN_DEFAULT_PASSWORD=your-password"
```

### Using Secret Manager (Recommended for Production)

For better security, use Google Secret Manager:

```bash
# Create secret
echo -n "your-password" | gcloud secrets create pgadmin-password --data-file=-

# Update service to use secret
gcloud run services update pgadmin \
  --region=us-central1 \
  --update-secrets="PGADMIN_DEFAULT_PASSWORD=pgadmin-password:latest"
```

## Persistent Storage

This deployment uses Cloud Storage buckets mounted as volumes to persist pgAdmin data. This ensures that:
- Server registrations are preserved
- User settings are maintained
- Data persists across container restarts and deployments

The Cloud Storage bucket is mounted at `/var/lib/pgadmin` in the container.

## Security Best Practices

1. **Use Secrets Manager for Passwords**: See the "Setting pgAdmin Credentials" section above for details on using Secret Manager.

2. **Enable Authentication** (remove `--allow-unauthenticated`):
   ```bash
   gcloud run services update pgadmin \
     --region=us-central1 \
     --no-allow-unauthenticated
   ```

3. **Use HTTPS**: Cloud Run automatically provides HTTPS for your service

4. **Service Account Permissions**: Ensure the Cloud Run service account has only the minimum required permissions (objectAdmin on the Cloud Storage bucket)

5. **Secure Cloud Storage Bucket**: Configure bucket-level permissions and consider enabling bucket versioning for data protection

## Troubleshooting

### Build Fails
- Check that all required APIs are enabled
- Verify your gcloud authentication: `gcloud auth list`
- Check Cloud Build logs in the Google Cloud Console

### Service Won't Start
- Verify environment variables are set correctly (especially `PGADMIN_DEFAULT_EMAIL` and `PGADMIN_DEFAULT_PASSWORD`)
- Check Cloud Run logs: `gcloud run services logs read pgadmin --region=us-central1`
- Ensure PORT is set to 8080 (already configured in Dockerfile)
- Verify the Cloud Storage bucket exists and is accessible
- Check that the service account has proper permissions to access the bucket

### Cannot Access Service
- Verify the service is deployed: `gcloud run services list`
- Check IAM permissions if authentication is enabled
- Verify the service URL is correct
- Ensure pgAdmin credentials are set correctly

### Cloud Storage Issues
- Verify the bucket exists: `gsutil ls gs://your-bucket-name`
- Check service account permissions: `gsutil iam get gs://your-bucket-name`
- Ensure the service account has `objectAdmin` role on the bucket

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

To remove the Cloud Storage bucket (⚠️ **Warning**: This will delete all pgAdmin data):

```bash
gsutil rm -r gs://your-bucket-name
```

Or to delete the bucket and all contents:

```bash
gsutil rb gs://your-bucket-name
```

To remove the service account:

```bash
gcloud iam service-accounts delete pgadmin-service-account@${PROJECT_ID}.iam.gserviceaccount.com
```

## Additional Resources

- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)



