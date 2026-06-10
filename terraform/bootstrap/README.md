# Terraform Bootstrap

이 디렉터리는 main Terraform state를 저장할 remote backend 리소스를 먼저 만듭니다.

적용 순서:

```bash
cd terraform/bootstrap/aws
terraform init
terraform apply

cd ../gcp
terraform init
terraform apply

cd ../azure
terraform init
terraform apply
```

bootstrap 스택은 backend 저장소를 만들기 전 단계라 local state를 사용합니다. 생성이 끝나면 각 main cloud 디렉터리의 커밋된 `backend.hcl` 값과 bootstrap output이 일치하는지 확인하고 `terraform init -backend-config=backend.hcl`로 초기화합니다.
