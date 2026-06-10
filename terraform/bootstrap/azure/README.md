# Azure Backend Bootstrap

Creates the Storage Account and blob container used by `terraform/azure`. The main backend uses Azure Blob Storage native state locking and Microsoft Entra ID authentication.

```bash
cd terraform/bootstrap/azure
terraform init
terraform apply
```

After apply, confirm the output values match `terraform/azure/backend.hcl`.
