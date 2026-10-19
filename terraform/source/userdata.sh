#!/bin/bash
# ReRail 源端节点初始化：sysctl + Docker（官方源最新版，依赖节点 EIP 公网出口）
# 注意：OTel agent 不在此下载 —— 由 build/fetch-otel-agent.sh 在 builder 下载，
#       Ansible role app/entry 分发到节点（保证版本统一 + SHA256 校验）。
set -euxo pipefail

# 1. 系统调优（全部节点统一）
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

echo "Node initialization complete"
