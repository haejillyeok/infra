# Terraform Infra

이 디렉터리는 AWS, GCP, Azure별로 동일한 목적의 최소 인프라를 관리합니다.

- `bootstrap/aws`: AWS S3 backend bucket
- `bootstrap/gcp`: GCP GCS backend bucket
- `bootstrap/azure`: Azure Storage backend account와 container
- `aws`: EC2 1대, RDS PostgreSQL 1대, VPC/subnet/security group, Elastic IP
- `gcp`: Compute Engine 1대, Cloud SQL PostgreSQL 1대, VPC/subnet/firewall, static external IP
- `azure`: VM 1대, PostgreSQL Flexible Server 1대, VNet/subnet/NSG, static public IP

각 클라우드 디렉터리는 독립적인 Terraform root module입니다. 따라서 `terraform/aws`, `terraform/gcp`, `terraform/azure`별로 한 번씩 `terraform apply`하면 되고, state도 클라우드별 remote backend로 분리됩니다. backend 저장소는 `terraform/bootstrap/*`에서 먼저 생성합니다.

## tfstate 관리

main infra의 tfstate는 로컬 파일로 관리하지 않습니다.

- AWS: S3 backend + S3 native lockfile
- GCP: GCS backend
- Azure: Azure Storage backend with Blob Storage native locking and Entra ID authentication

처음에는 bootstrap 스택을 local state로 한 번 실행해서 remote backend 저장소를 만듭니다. 이후 각 클라우드 디렉터리의 커밋된 `backend.hcl` 값으로 초기화합니다. `backend.hcl`에는 인증정보가 없고, state가 어느 remote backend에 저장되는지 코드에서 확인할 수 있게 형상관리합니다.

```bash
cd terraform/bootstrap/aws
terraform init
terraform apply

cd terraform/aws
terraform init -backend-config=backend.hcl
```

## 민감값 관리

실제 값은 Git에 커밋하지 않습니다.

- DB 사용자명: `db_username`
- DB 비밀번호: `db_password`
- 기본 접속용 SSH public key: `ssh_public_key`
- 배포용 SSH public key: `deploy_ssh_public_key`
- Agent가 `deploy` 유저로 접속할 때 추가로 넣을 SSH public key: `agent_ssh_public_key`

각 클라우드 디렉터리의 `terraform.tfvars.example`을 복사해서 `terraform.tfvars`로 사용하거나, `TF_VAR_...` 환경변수로 주입하세요. `terraform.tfvars`와 `.env`는 `.gitignore`에 포함되어 있습니다.

`AGENT_SSH_KEY`를 쓰는 환경에서는 값이 SSH public key일 때만 `TF_VAR_agent_ssh_public_key="$AGENT_SSH_KEY"`로 넘기세요. Private key는 VM의 `authorized_keys`에 넣을 수 없습니다.

Azure VM의 기본 접속용 `ssh_public_key`는 RSA 형식이어야 합니다.
