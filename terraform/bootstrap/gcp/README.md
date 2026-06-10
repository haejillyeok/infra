# GCP Backend Bootstrap

Creates the GCS bucket used by `terraform/gcp`.

```bash
cd terraform/bootstrap/gcp
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

After apply, confirm the output values match `terraform/gcp/backend.hcl`.
