# GitHub Actions Deployment Setup

This repository contains a GitHub Actions workflow that automatically builds and deploys your Flutter web application to AWS S3 with CloudFront invalidation.

## Required GitHub Repository Secrets

To enable the deployment pipeline, you need to configure the following secrets in your GitHub repository:

### How to Add Secrets:
1. Go to your GitHub repository
2. Click on **Settings**
3. Navigate to **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each of the following secrets:

### Required Secrets:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret access key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | AWS region where your S3 bucket is located | `us-east-1` |
| `AWS_S3_BUCKET` | Name of your S3 bucket | `my-flutter-web-app-bucket` |
| `AWS_CLOUDFRONT_DISTRIBUTION_ID` | CloudFront distribution ID | `E1234567890123` |

## What the Pipeline Does

When you push code to the `main` branch, the pipeline will:

1. **Checkout** your code
2. **Setup Flutter** environment (version 3.24.0)
3. **Install dependencies** (`flutter pub get`)
4. **Analyze code** (`flutter analyze`)
5. **Run tests** (`flutter test`)
6. **Build web app** (`flutter build web --release`)
7. **Deploy to S3** (sync build files, overwrite existing)
8. **Invalidate CloudFront cache** (clear CDN cache for immediate updates)

## S3 Bucket Configuration

Make sure your S3 bucket is configured for static website hosting:

1. **Enable static website hosting** in S3 bucket properties
2. **Set index document** to `index.html`
3. **Set error document** to `index.html` (for SPA routing)
4. **Configure bucket policy** for public read access (if needed)

## CloudFront Configuration

Ensure your CloudFront distribution is set up to:

1. **Origin** points to your S3 bucket
2. **Default root object** is set to `index.html`
3. **Error pages** redirect to `index.html` for SPA routing
4. **Caching behavior** is configured appropriately

## IAM Permissions

Your AWS user needs the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-bucket-name",
                "arn:aws:s3:::your-bucket-name/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation"
            ],
            "Resource": "*"
        }
    ]
}
```

## Triggering Deployment

The deployment will automatically trigger when you:

- Push commits to the `main` branch
- Merge pull requests into the `main` branch

## Monitoring Deployment

You can monitor the deployment progress by:

1. Going to your repository on GitHub
2. Clicking on the **Actions** tab
3. Selecting the latest workflow run

The deployment typically takes 3-5 minutes to complete.
