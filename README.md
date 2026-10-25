# AWS EC2 CI/CD Personal Project

An end-to-end example that tests and containerizes a small HTTP service, stores
versioned Docker releases in S3, and deploys them directly to an EC2 instance.
Terraform provisions the network, instance, artifact bucket, and least-privilege
IAM roles. GitHub Actions uses OIDC and AWS Systems Manager (SSM), so no SSH
keys or long-lived AWS credentials are needed.

The application runs as a Docker container on EC2. Kubernetes, Prometheus, and
Grafana are intentionally not part of this project.

## Architecture

```text
Pull request / push to main
          |
          v
GitHub Actions -- unit tests, Docker build, optional SonarQube scan
          |
          | OIDC role; on main, upload image archive to S3
          v
AWS Systems Manager ----------> EC2 (Docker) -- HTTP :80
                                     |
                                     +-- downloads release from private S3
```

The deployment workflow runs on pushes to `main` (and manual dispatches from
`main`). It health-checks the new container and restores the previous container
if the new release fails to start. Replacing a container can cause a brief
request interruption; this single-instance project is not a zero-downtime
deployment setup.

## Prerequisites

- An AWS account with permissions to create VPC, EC2, S3, IAM, and Systems
  Manager resources.
- Terraform 1.5 or newer, AWS CLI, and Docker for local development.
- A GitHub repository with Actions enabled.

## Provision AWS infrastructure

Terraform creates a public subnet and EC2 instance. The security group exposes
only HTTP; administrative access uses SSM rather than inbound SSH. The instance
needs outbound internet access to install packages, reach SSM, and retrieve
release archives.

```sh
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set github_repository to owner/repository.
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Keep the Terraform state private. For shared or production use, configure a
remote encrypted backend and state locking before applying.

After apply, note the outputs:

- `github_actions_role_arn`
- `ec2_instance_id`
- `artifact_bucket`
- `app_url`

The AWS account must not already have a GitHub Actions OIDC provider at
`https://token.actions.githubusercontent.com`. If it does, import that provider
into this Terraform state before applying rather than attempting to create a
duplicate.

## Configure GitHub

In **Settings → Secrets and variables → Actions → Variables**, create:

| Variable | Value |
| --- | --- |
| `AWS_ROLE_ARN` | Terraform output `github_actions_role_arn` |
| `AWS_REGION` | The Terraform `aws_region` value |
| `EC2_INSTANCE_ID` | Terraform output `ec2_instance_id` |
| `ARTIFACT_BUCKET` | Terraform output `artifact_bucket` |

The IAM trust policy allows only this repository's `main` branch. Update
`infra/terraform/main.tf` if your deployment branch differs.

To enable SonarQube analysis, add `SONAR_HOST_URL` as a repository variable and
`SONAR_TOKEN` as a repository secret. Without both, the analysis step is
skipped; tests and Docker builds still run.

## Run locally

```sh
python -m unittest discover -s tests -v
docker build -t personal-project:local .
docker run --rm -p 8000:8000 personal-project:local
curl http://localhost:8000/health
```

The service responds at `/` with its name and version, and at `/health` with a
health status.

## Deployment and operations

Every pull request runs tests and builds the image. A push to `main` uploads the
image archive to the private S3 bucket, invokes the instance with SSM, and
checks the deployed container's health. GitHub receives short-lived AWS
credentials through OIDC; EC2 can only read release objects from the artifact
bucket.

To remove the AWS resources when finished:

```sh
cd infra/terraform
terraform destroy
```
