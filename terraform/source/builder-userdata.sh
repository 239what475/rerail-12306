#!/bin/bash
# Builder 节点初始化：sysctl + Docker（官方源最新版）+ Ansible + k6 + SSH 密钥对
# builder 绑定 EIP（terraform/builder/main.tf），公网可达用于下载。
set -euxo pipefail

# 1. 系统调优
cat > /etc/sysctl.d/99-rerail.conf << 'SYSCTL'
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 16384
net.core.netdev_max_backlog = 16384
SYSCTL
sysctl --system > /dev/null

# 2. Docker：阿里云内网镜像源（VPC 内直达，无需公网出口）；
#    实测 2026-10 同步官方版本 29.9.1；要求主版本 >= 29，低于则报错终止
DOCKER_REPO="mirrors.cloud.aliyuncs.com"
apt-get update -qq
apt-get install -y -qq ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://${DOCKER_REPO}/docker-ce/linux/ubuntu/gpg" -o /etc/apt/keyrings/docker.asc \
  || curl -fsSL "http://${DOCKER_REPO}/docker-ce/linux/ubuntu/gpg" -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] http://${DOCKER_REPO}/docker-ce/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
DOCKER_MAJOR=$(dpkg -s docker-ce | awk '/^Version:/{split($2,v,"[.:-]"); print v[2]}')
[ "${DOCKER_MAJOR:-0}" -ge 29 ] || { echo "ERROR: docker-ce major version ${DOCKER_MAJOR} < 29"; exit 1; }

# 3. Ansible（Ubuntu 官方源，ECS 默认 apt 源即阿里云内网镜像）
apt-get install -y -qq ansible

# 4. k6（版本锁定，经 ghfast 代理下载 GitHub release）
K6_VERSION="v2.3.0"
curl -sL --max-time 300 "https://ghfast.top/https://github.com/grafana/k6/releases/download/${K6_VERSION}/k6-${K6_VERSION}-linux-amd64.tar.gz" -o /tmp/k6.tgz
tar xzf /tmp/k6.tgz -C /tmp
mv /tmp/k6-${K6_VERSION}-linux-amd64/k6 /usr/local/bin/k6
rm -f /tmp/k6.tgz

# 5. SSH 密钥对（Ansible 引导用）
if [ ! -f /root/.ssh/id_ed25519 ]; then
  ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519 -q
fi

# 6. 自身公钥写入 authorized_keys（builder 自身免密）
grep -qF "$(cat /root/.ssh/id_ed25519.pub)" /root/.ssh/authorized_keys 2>/dev/null || \
  cat /root/.ssh/id_ed25519.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# 7. 标记完成
touch /root/.rerail-ready
echo "Builder initialization complete"
