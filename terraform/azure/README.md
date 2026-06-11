# Azure Terraform

Azure는 Ubuntu 26.04 LTS Virtual Machine 1대와 Azure Database for PostgreSQL Flexible Server 1대를 최소 구성으로 관리합니다.

초기 셋업은 `INITIAL_SETUP.md`를 먼저 확인합니다.

적용:

```bash
cd terraform/bootstrap/azure
terraform init
terraform apply

cd terraform/azure
terraform init -backend-config=backend.hcl
terraform apply
```

구성 의도:

- Resource Group은 기존 `terraform`을 그대로 관리합니다.
- Resource Group 위치는 `koreasouth`, VM/DB 등 실제 워크로드 리소스 위치는 `koreacentral`을 사용합니다.
- `koreasouth`는 현재 구독에서 PostgreSQL Flexible Server 프로비저닝이 제한되어 있습니다.
- VM은 public subnet에 배치하고 static public IP를 연결합니다.
- VM public IP에는 DNS label을 연결하고, SSH 명령은 FQDN 기준으로 출력합니다.
- VM NSG는 SSH 22, HTTP 80, HTTPS 443 inbound를 허용합니다.
- 기본 접속은 `ubuntu` 유저와 RSA 형식의 `ssh_public_key`를 사용합니다.
- 배포 접속은 cloud-init으로 생성한 `deploy` 유저와 `deploy_ssh_public_key`를 사용합니다. 기존 VM에 추가 키가 필요하면 VM 안에서 `deploy` 유저의 `authorized_keys`에 직접 추가합니다.
- VM 이미지는 Canonical의 Ubuntu 26.04 LTS server 이미지를 사용합니다.
- VM OS 디스크는 Azure 무료 계정의 P6 managed disk 한도에 맞춰 `Premium_LRS` 64 GiB를 기본값으로 사용합니다.
- PostgreSQL Flexible Server는 delegated private subnet에 배치하고 public network access를 비활성화합니다.
- DB subnet NSG는 VM subnet에서 오는 PostgreSQL 5432만 허용합니다.
- 로컬 DB 접속은 VM을 bastion으로 쓰는 SSH tunnel로만 열도록 `postgres_ssh_tunnel_command`를 출력합니다.

비용 주의:

- VM/PostgreSQL 비용은 계정 혜택, 지역, SKU 조건에 따라 달라질 수 있습니다.
- Static public IP, 스토리지, 백업은 무료 한도와 사용량을 초과하면 과금될 수 있습니다.
