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
## CI/CD (GitHub Actions)
`.github/workflows/terraform.yml` runs on every PR and push to `main`:
- **PR** → `fmt -check`, `validate`, `plan`; the plan is posted as a PR comment.
- **Push to `main`** (or manual run) → plan, then `apply` in the `production` environment.

CI authenticates to AWS via GitHub OIDC (no long-lived keys) and passes `-var aws_profile=` so the local `admin` profile is ignored.

### One-time setup
1. Create the GitHub OIDC provider in AWS (skip if it already exists):
   ```bash
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com
   ```
2. Create an IAM role (e.g. `github-actions-single-env`) with this trust policy, and attach permissions for EC2, security groups, and the S3 state bucket:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": { "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" },
       "Action": "sts:AssumeRoleWithWebIdentity",
       "Condition": {
         "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
         "StringLike": { "token.actions.githubusercontent.com:sub": "repo:lbarb06/single-env:*" }
       }
     }]
   }
   ```
3. Add the role ARN as a repo secret:
   ```bash
   gh secret set AWS_ROLE_ARN -R lbarb06/single-env --body arn:aws:iam::<ACCOUNT_ID>:role/github-actions-single-env
   ```
4. (Optional) In repo Settings → Environments → `production`, add required reviewers to gate applies.
