# Azure Terraform Initial Setup

Azure에서 Terraform을 실행하기 위한 최초 준비 절차입니다. 목적은 Terraform 전용 Entra ID 계정에 구독 권한을 부여하고, remote state 저장소를 만든 뒤 backend를 연결하는 것입니다.

## 목차

- [0. 준비 값](#0-준비-값)
- [1. Entra ID에 Terraform 계정 생성](#1-entra-id에-terraform-계정-생성)
- [2. 구독 IAM 역할 할당](#2-구독-iam-역할-할당)
- [3. State 저장소 생성](#3-state-저장소-생성)
- [4. tfstate Container IAM 부여](#4-tfstate-container-iam-부여)
- [5. 터미널 로그인](#5-터미널-로그인)
- [6. Backend 설정 확인](#6-backend-설정-확인)
- [체크리스트](#체크리스트)
- [Storage Account 생성 옵션](#storage-account-생성-옵션)
  - [기본](#기본)
  - [고급](#고급)
  - [네트워킹](#네트워킹)
  - [데이터 보호](#데이터-보호)
  - [보안](#보안)
  - [암호화](#암호화)

## 0. 준비 값

| 항목 | 값 |
| --- | --- |
| Terraform 계정 | `terraform` |
| State Resource Group | `terraform` |
| State Storage Account | `haejillyeokstate` |
| State Container | `tfstate` |
| Backend Key | `haejillyeok/azure/terraform.tfstate` |
| Region | `koreasouth` |

## 1. Entra ID에 Terraform 계정 생성

Azure Portal에서 진행합니다.

1. Microsoft Entra ID > Users > New user > Create new user
2. User principal name 입력: `terraform`
3. Display name 입력: `terraform`
4. Password는 자동 생성 후 안전한 곳에 저장
5. Create

## 2. 구독 IAM 역할 할당

구독 전체 인프라를 생성할 수 있도록 Terraform 계정에 Contributor를 부여합니다.

1. Subscriptions > 대상 구독 선택
2. Access control (IAM) > Add role assignment
3. Role: `Contributor`
4. Members: `terraform`
5. Review + assign

## 3. State 저장소 생성

Terraform state 전용 리소스를 생성합니다.

1. Resource groups > Create
   - Name: `terraform`
   - Region: `koreasouth`
2. Storage accounts > Create
   - Resource group: `terraform`
   - Name: `haejillyeokstate`
   - Performance: `Standard`
   - Redundancy: `Locally-redundant storage (LRS)`
3. Storage Account > Data storage > Containers > Add
   - Name: `tfstate`
   - Public access level: `Private`

## 4. tfstate Container IAM 부여

Terraform backend가 Azure Blob state를 읽고 쓸 수 있도록 권한을 부여합니다.

1. Storage Account > Data storage > Containers > `tfstate`
2. Access control (IAM) > Add role assignment
3. Role: `Storage Blob Data Contributor`
4. Members: `terraform`
5. Review + assign

## 5. 터미널 로그인

Portal 설정이 끝나면 로컬 터미널에서 Terraform 계정으로 Azure CLI에 로그인합니다.

```bash
az login
```

브라우저가 열리면 Entra ID에 만든 `terraform` 계정으로 로그인합니다. 로그인 후 사용할 구독을 지정합니다.

```bash
az account set --subscription "<subscription-id>"
az account show
```

`az account show` 결과의 `user.name`이 `terraform` 계정이고, `id`가 대상 구독 ID인지 확인합니다.

## 6. Backend 설정 확인

`terraform/azure/backend.hcl` 값이 state 저장소와 일치해야 합니다.

```hcl
resource_group_name  = "terraform"
storage_account_name = "haejillyeokstate"
container_name       = "tfstate"
key                  = "haejillyeok/azure/terraform.tfstate"
use_azuread_auth     = true
```

초기화와 적용:

```bash
cd terraform/azure
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## 체크리스트

- [ ] Entra ID에 `terraform` 계정 생성
- [ ] 구독 IAM에 `Contributor` 역할 부여
- [ ] state용 Resource Group 생성
- [ ] state용 Storage Account 생성
- [ ] `tfstate` Container 생성
- [ ] Container IAM에 `Storage Blob Data Contributor` 역할 부여
- [ ] Azure CLI에서 `terraform` 계정으로 로그인
- [ ] `az account set --subscription "<subscription-id>"` 실행
- [ ] `terraform init -backend-config=backend.hcl` 실행

## Storage Account 생성 옵션

Portal에서 Storage Account를 만들 때 아래 값으로 진행합니다.

### 기본

| 항목 | 선택 |
| --- | --- |
| Resource Group | `terraform` |
| Storage Account Name | `haejillyeokstate` |
| Region | `(Asia Pacific) Korea South` |
| Primary service | `Azure Blob Storage 또는 Azure Data Lake Storage` |
| Performance | `Standard` |
| Redundancy | `LRS` |

### 고급

| 항목 | 선택 |
| --- | --- |
| 계층 구조 네임스페이스 | 사용 안 함 |
| SFTP | 사용 안 함 |
| NFS v3 | 사용 안 함 |
| 테넌트 간 복제 | 허용 안 함 |
| 액세스 계층 | `Hot` |
| SMB 관리 ID | 사용 안 함 |
| SMB 전송 중 암호화 | 사용 |

### 네트워킹

초기 셋업은 로컬 PC에서 Terraform을 실행하기 쉽게 아래 값으로 시작합니다.

| 항목 | 선택 |
| --- | --- |
| 공용 네트워크 액세스 | 사용 |
| 공용 네트워크 액세스 범위 | 모든 네트워크에서 사용 |
| 프라이빗 엔드포인트 | 추가 안 함 |

운영 단계에서 더 제한하려면 `선택한 가상 네트워크 및 IP 주소에서 사용`으로 변경하고 현재 공인 IP만 허용합니다.

### 데이터 보호

| 항목 | 선택 |
| --- | --- |
| 컨테이너 특정 시점 복원 | 사용 안 함 |
| Blob 일시 삭제 | 사용, `7일` |
| 컨테이너 일시 삭제 | 사용, `7일` |
| 클래식 파일 공유 일시 삭제 | 사용 안 함 |
| Blob 버전 관리 | 사용 |
| Blob 변경 피드 | 사용 안 함 |

### 보안

| 항목 | 선택 |
| --- | --- |
| REST API 보안 전송 필요 | 사용 |
| 개별 컨테이너 익명 액세스 | 허용 안 함 |
| 스토리지 계정 키 액세스 | 사용 안 함 |
| Azure Portal Entra 인증 기본값 | 사용 |
| 최소 TLS 버전 | `1.2` |
| 복사 작업 허용 범위 | 모든 스토리지 계정 |
| Microsoft Defender for Storage | 사용 안 함 |

### 암호화

| 항목 | 선택 |
| --- | --- |
| 암호화 형식 | `MMK(Microsoft 관리형 키)` |
| 고객 관리형 키 지원 | `Blob 및 파일만` |
| 인프라 암호화 | 사용 안 함 |
