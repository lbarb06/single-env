# small_project

Minimal Terraform deployment for a small webapp on EC2 with remote state in S3.

## What it deploys
- EC2 instance (`t3.micro`) in default VPC/subnet
- Security group allowing HTTP (`80`)
- Nginx installed via `user_data`
- Static page: `small_project webapp is running`

## State
Terraform state is stored in an external S3 backend (not managed by this stack).

- Backend config file: `backend.hcl`
- Expected bucket: `small-project-tfstate-us-east-1`
- State key: `small_project/terraform.tfstate`

## Project structure
```text
small_project/
  providers.tf
  variables.tf
  main.tf
  outputs.tf
  terraform.tfvars
  backend.hcl
  modules/
    ec2/
      main.tf
      variables.tf
      outputs.tf

Prerequisites
Terraform >= 1.6
AWS CLI configured
AWS profile with permissions for EC2/VPC and S3 backend access

Set env:

export AWS_PROFILE=admin
export AWS_REGION=us-east-1
cd ~/repos/lbarb06/terraform/small_project

One-time backend bucket setup (if needed)

aws s3api create-bucket --bucket small-project-tfstate-us-east-1 --region us-east-1
aws s3api put-bucket-versioning --bucket small-project-tfstate-us-east-1 --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket small-project-tfstate-us-east-1 --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket small-project-tfstate-us-east-1 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

Deploy

terraform init -backend-config=backend.hcl
terraform plan
terraform apply

Non-interactive:

terraform apply -auto-approve

Verify

terraform output web_url
curl -I "$(terraform output -raw web_url)"

Destroy

terraform destroy

Non-interactive:

terraform destroy -auto-approve

Troubleshooting
Backend initialization required
Re-init backend:

terraform init -reconfigure -backend-config=backend.hcl

S3 bucket does not exist
Create backend bucket first, then rerun terraform init.

Orphaned resources after lost state
If state backend was deleted prematurely, remove leftovers manually with AWS CLI.

Security notes
Do not commit *.tfstate* or .terraform/.
Keep backend bucket private and encrypted.
Do not place plaintext secrets in Terraform variables.