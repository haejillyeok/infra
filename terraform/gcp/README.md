# GCP Terraform

GCP는 Ubuntu 26.04 LTS Compute Engine VM 1대와 Cloud SQL for PostgreSQL 1대를 최소 구성으로 관리합니다.

적용:

```bash
cd terraform/bootstrap/gcp
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply

cd terraform/gcp
terraform init -backend-config=backend.hcl
terraform apply
```

구성 의도:

- Compute Engine은 public subnet에 배치하고 static external IP를 연결합니다.
- Compute Engine boot disk는 `ubuntu-os-cloud`의 Ubuntu 26.04 LTS image family를 사용합니다.
- 기본 접속은 `ubuntu` 유저와 `ssh_public_key`를 사용합니다.
- 배포 접속은 `deploy` 유저와 `deploy_ssh_public_key`를 사용합니다. `agent_ssh_public_key`가 있으면 같은 `deploy` 유저의 SSH metadata에 추가합니다.
- Cloud SQL은 public IPv4를 비활성화하고 private IP만 사용합니다.
- 로컬 DB 접속은 VM을 bastion으로 쓰는 SSH tunnel로만 열도록 `cloud_sql_ssh_tunnel_command`를 출력합니다.

비용 주의:

- Compute Engine free tier와 Cloud SQL free trial/credit는 계정, 리전, 기간에 따라 달라질 수 있습니다.
- Cloud SQL은 always-free DB가 아니므로, free trial 또는 credit 소진 이후 과금될 수 있습니다.
