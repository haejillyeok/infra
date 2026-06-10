# AWS Backend Bootstrap

Creates the S3 bucket used by `terraform/aws`. State locking uses Terraform's S3 native lockfile support.

```bash
cd terraform/bootstrap/aws
terraform init
terraform apply
```

After apply, confirm the output values match `terraform/aws/backend.hcl`.
