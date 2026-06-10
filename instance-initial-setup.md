# Initial instance setup

생성된 인스턴스에서 처음 실행할 터미널 작업을 정리합니다.

## 4GB swap memory

현재 스왑 상태를 먼저 확인합니다.

```bash
free -h
swapon --show
```

4GB 스왑 파일을 생성하고 즉시 활성화합니다.

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

재부팅 후에도 스왑이 유지되도록 `/etc/fstab`에 등록합니다.

```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

적용 결과를 확인합니다.

```bash
free -h
swapon --show
```

필요하면 스왑 사용 성향을 낮게 조정합니다.

```bash
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl --system
```

## Docker

Ubuntu 계열 서버에서 Docker 공식 apt 저장소를 등록한 뒤 Docker Engine과 Compose 플러그인을 설치합니다.

### 1. 필수 도구 설치

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
```

### 2. GPG 키 디렉토리 생성

```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

### 3. Docker 공식 GPG 키 다운로드

```bash
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

### 4. Docker apt 저장소 추가

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 5. 저장소 갱신

```bash
sudo apt-get update
```

### 6. Docker 설치

```bash
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

설치 후 Docker를 활성화하고 상태를 확인합니다.

```bash
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker
docker --version
docker compose version
```

### 7. deploy 유저에 Docker 권한 추가

`deploy` 유저가 `sudo` 없이 Docker 명령을 실행할 수 있도록 `docker` 그룹에 추가합니다.

```bash
sudo usermod -aG docker deploy
```

그룹 변경은 새 로그인 세션부터 적용됩니다. `deploy` 유저로 다시 접속한 뒤 확인합니다.

```bash
id deploy
docker ps
```

현재 SSH 세션에서 바로 반영해 테스트하려면 아래 명령을 사용할 수 있습니다.

```bash
newgrp docker
docker ps
```

### 8. 버전 고정

자동 업데이트로 Docker 버전이 바뀌는 것을 막고 싶다면 패키지를 hold 처리합니다.

```bash
sudo apt-mark hold docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

hold 상태를 확인합니다.

```bash
apt-mark showhold
```

## Infra Docker Compose

OpenTelemetry Collector, Prometheus, Tempo, Loki, Promtail, Grafana는 루트의 `docker-compose.yml`로 관리합니다.

서버 배포 경로는 `/opt/haejillyeok/infra`를 기준으로 합니다.

```bash
sudo install -d -o deploy -g deploy /opt/haejillyeok/infra
cd /opt/haejillyeok/infra
```

필요한 설정 파일 구조는 아래와 같습니다.

```text
/opt/haejillyeok/infra
├── docker-compose.yml
├── .env
├── otel-collector/config.yml
├── prometheus/prometheus.yml
├── tempo/tempo.yml
├── loki/loki.yml
├── promtail/promtail.yml
├── grafana/provisioning/datasources/prometheus.yml
├── grafana/provisioning/datasources/tempo.yml
├── grafana/provisioning/datasources/loki.yml
├── grafana/provisioning/dashboards/dashboards.yml
└── grafana/dashboards/*.json
```

### 1. Docker 네트워크 준비

`docker-compose.yml`의 `backend_default` 네트워크는 external network이므로 compose 실행 전에 존재해야 합니다.

앱 서버 compose가 이미 `backend_default`를 만들었다면 이 단계는 생략할 수 있습니다.

```bash
docker network ls
docker network inspect backend_default
```

네트워크가 없다면 생성합니다.

```bash
docker network create backend_default
```

반복 실행해도 안전하게 처리하려면 아래 명령을 사용합니다.

```bash
docker network inspect backend_default >/dev/null 2>&1 || docker network create backend_default
```

### 2. 볼륨 경로 준비

bind mount로 연결하는 host 경로가 없으면 Docker가 의도치 않은 디렉토리를 만들 수 있습니다. 특히 `config.yml`, `prometheus.yml`, `tempo.yml`처럼 파일로 마운트하는 경로는 미리 실제 파일로 준비해야 합니다.

먼저 필요한 디렉토리를 생성합니다.

```bash
sudo install -d -o deploy -g deploy /opt/haejillyeok/infra/otel-collector
sudo install -d -o deploy -g deploy /opt/haejillyeok/infra/prometheus/data
sudo install -d -o deploy -g deploy /opt/haejillyeok/infra/tempo/data
sudo install -d -o deploy -g deploy /opt/haejillyeok/infra/loki/data
sudo install -d -o deploy -g deploy /opt/haejillyeok/infra/promtail/data
sudo install -d -o deploy -g deploy /opt/haejillyeok/infra/grafana/data
sudo install -d -o deploy -g deploy /opt/haejillyeok/infra/grafana/provisioning/datasources
sudo install -d -o deploy -g deploy /opt/haejillyeok/infra/grafana/provisioning/dashboards
sudo install -d -o deploy -g deploy /opt/haejillyeok/infra/grafana/dashboards
sudo install -d -o deploy -g deploy /var/log/haejillyeok
```

설정 파일이 배포되어 있는지 확인합니다.

```bash
test -f /opt/haejillyeok/infra/otel-collector/config.yml
test -f /opt/haejillyeok/infra/prometheus/prometheus.yml
test -f /opt/haejillyeok/infra/tempo/tempo.yml
test -f /opt/haejillyeok/infra/loki/loki.yml
test -f /opt/haejillyeok/infra/promtail/promtail.yml
test -f /opt/haejillyeok/infra/grafana/provisioning/datasources/prometheus.yml
test -f /opt/haejillyeok/infra/grafana/provisioning/datasources/tempo.yml
test -f /opt/haejillyeok/infra/grafana/provisioning/datasources/loki.yml
test -f /opt/haejillyeok/infra/grafana/provisioning/dashboards/dashboards.yml
```

파일이 없다면 컨테이너를 올리기 전에 각 설정 파일을 먼저 배치합니다. 빈 파일만 만들어두면 컨테이너가 설정 파싱 단계에서 실패할 수 있습니다.

대시보드 JSON은 백엔드 레포의 아래 파일을 `/opt/haejillyeok/infra/grafana/dashboards/`에 복사합니다.

```text
docker/grafana/dashboards/fastapi-apm.json
docker/grafana/dashboards/fastapi-traces.json
```

컨테이너가 데이터 디렉토리에 쓸 수 있도록 실행 UID에 맞춰 소유권을 조정합니다. 특히 Grafana는 `/var/lib/grafana/plugins` 디렉토리를 생성해야 하므로 `grafana/data`가 `deploy` 소유이면 `Permission denied`가 발생할 수 있습니다.

```bash
sudo chown -R 472:472 /opt/haejillyeok/infra/grafana/data
sudo chown -R 65534:65534 /opt/haejillyeok/infra/prometheus/data
sudo chown -R 10001:10001 /opt/haejillyeok/infra/tempo/data
sudo chown -R 10001:10001 /opt/haejillyeok/infra/loki/data
```

### 3. 환경 변수 설정

필요하면 `.env` 파일로 host port와 Grafana 관리자 계정을 조정합니다. 이 레포의 `.env.example`을 서버에서는 `.env`로 복사해서 사용합니다.

```bash
sudo -u deploy cp /opt/haejillyeok/infra/.env.example /opt/haejillyeok/infra/.env
```

직접 생성하거나 값을 덮어쓸 수도 있습니다.

```bash
sudo -u deploy tee /opt/haejillyeok/infra/.env > /dev/null <<EOF
OTEL_HTTP_HOST_PORT=4318
OTEL_PROMETHEUS_HOST_PORT=9464
PROMETHEUS_HOST_PORT=9090
TEMPO_HOST_PORT=3200
LOKI_HOST_PORT=3100
PROMTAIL_HOST_PORT=9080
GRAFANA_HOST_PORT=3000
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=change-me
EOF
```

`.env`에는 비밀번호가 들어가므로 `deploy` 유저만 읽고 쓸 수 있게 설정합니다.

```bash
sudo chown deploy:deploy /opt/haejillyeok/infra/.env
sudo chmod 600 /opt/haejillyeok/infra/.env
ls -l /opt/haejillyeok/infra/.env
```

권한은 아래처럼 `-rw-------`로 보여야 합니다.

```text
-rw------- 1 deploy deploy ... /opt/haejillyeok/infra/.env
```

운영 서버에서는 `GRAFANA_ADMIN_PASSWORD`를 반드시 변경합니다.

### 4. 실행

```bash
docker compose up -d
docker compose ps
docker compose logs -f
```

Grafana에서 `/var/lib/grafana/plugins: Permission denied`가 발생했다면 권한을 다시 맞춘 뒤 컨테이너를 재시작합니다.

```bash
sudo chown -R 472:472 /opt/haejillyeok/infra/grafana/data
docker compose restart grafana
docker compose logs -f grafana
```

설정 파일이나 볼륨 경로를 수정한 뒤에는 다시 반영합니다.

```bash
docker compose up -d
```

## Nginx, domain, SSL

Ubuntu 계열 서버에서 Nginx를 설치하고, 도메인을 서버에 연결한 뒤 Certbot으로 SSL 인증서를 발급합니다.

아래 예시에서 도메인과 앱 포트는 실제 값으로 바꿉니다.

```bash
DOMAIN=example.com
APP_PORT=3000
```

### 1. Nginx 설치

```bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx
```

방화벽을 사용하는 경우 HTTP/HTTPS 트래픽을 허용합니다.

```bash
sudo ufw allow 'Nginx Full'
sudo ufw status
```

### 2. 도메인 DNS 연결

DNS 제공자 콘솔에서 A 레코드를 추가합니다.

```text
Type: A
Name: @
Value: 서버 Public IPv4
TTL: Auto 또는 300
```

`www` 서브도메인을 사용할 경우 CNAME 또는 A 레코드를 추가합니다.

```text
Type: CNAME
Name: www
Value: example.com
TTL: Auto 또는 300
```

DNS 전파가 되었는지 서버 또는 로컬 터미널에서 확인합니다.

```bash
dig +short $DOMAIN
dig +short www.$DOMAIN
```

반환된 IP가 서버 Public IPv4와 같아야 합니다.

### 3. Nginx 서버 블록 생성

앱이 서버 내부에서 `APP_PORT`로 실행 중이라고 가정한 reverse proxy 예시입니다.

```bash
sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN www.$DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
```

설정을 활성화하고 Nginx 문법을 확인합니다.

```bash
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
sudo nginx -t
sudo systemctl reload nginx
```

HTTP로 도메인이 서버에 연결되는지 확인합니다.

```bash
curl -I http://$DOMAIN
```

### 4. Certbot 설치

Certbot 공식 안내는 snap 설치를 기본 경로로 권장합니다.

이미 apt로 설치한 Certbot이 있다면 snap 버전과 충돌하지 않도록 먼저 제거합니다.

```bash
sudo apt remove -y certbot python3-certbot-nginx
sudo apt install -y snapd
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/local/bin/certbot
```

### 5. SSL 인증서 발급

Nginx 설정을 Certbot이 읽어서 인증서를 발급하고 HTTPS 설정까지 반영합니다.

```bash
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN
```

`www` 도메인을 사용하지 않는다면 하나만 발급합니다.

```bash
sudo certbot --nginx -d $DOMAIN
```

발급 후 HTTPS 응답을 확인합니다.

```bash
curl -I https://$DOMAIN
```

### 6. Certbot 자동 갱신 확인

Certbot 설치에는 보통 자동 갱신용 cron 또는 systemd timer가 함께 구성됩니다. 실제 서버에서는 아래 명령으로 확인합니다.

```bash
systemctl list-timers | grep certbot
systemctl status snap.certbot.renew.timer
```

cron 기반으로 설치된 경우 아래 위치 중 하나에 `certbot renew`가 등록되어 있을 수 있습니다.

```bash
grep -R "certbot renew" /etc/crontab /etc/cron.* 2>/dev/null
```

자동 갱신이 정상 동작하는지 dry-run으로 검증합니다.

```bash
sudo certbot renew --dry-run
```

`Congratulations, all simulated renewals succeeded` 형태의 메시지가 나오면 갱신 테스트가 성공한 것입니다.

인증서 목록과 만료일은 아래 명령으로 확인합니다.

```bash
sudo certbot certificates
```

참고 문서:

- Certbot Nginx instructions: https://certbot.eff.org/instructions?ws=nginx&os=snap
- Certbot automated renewals: https://eff-certbot.readthedocs.io/en/latest/using.html#automated-renewals
