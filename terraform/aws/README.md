# AWS Terraform

AWS는 Ubuntu 26.04 LTS EC2 1대와 RDS for PostgreSQL 1대를 최소 구성으로 관리합니다.

적용:

```bash
cd terraform/bootstrap/aws
terraform init
terraform apply

cd terraform/aws
terraform init -backend-config=backend.hcl
terraform apply
```

구성 의도:

- EC2는 public subnet에 배치하고 Elastic IP를 연결합니다.
- EC2 AMI는 Canonical public SSM parameter에서 Ubuntu 26.04 LTS 최신 이미지를 조회합니다.
- 기본 접속은 Ubuntu 기본 유저와 `ssh_public_key`를 사용합니다.
- 배포 접속은 cloud-init으로 생성한 `deploy` 유저와 `deploy_ssh_public_key`를 사용합니다. `agent_ssh_public_key`가 있으면 같은 `deploy` 유저의 authorized_keys에 추가합니다.
- RDS는 private subnet에 배치하고 public access를 비활성화합니다.
- RDS security group은 EC2 security group에서 오는 PostgreSQL 5432만 허용합니다.
- 로컬 DB 접속은 EC2를 bastion으로 쓰는 SSH tunnel로만 열도록 `rds_ssh_tunnel_command`를 출력합니다.

비용 주의:

- EC2/RDS free tier 또는 credit 조건은 계정 생성 시점과 리전에 따라 달라질 수 있습니다.
- 고정 public IPv4 주소는 클라우드 정책에 따라 과금될 수 있습니다.
