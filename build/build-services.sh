#!/usr/bin/env bash
# ReRail 服务镜像构建：clone 载体 → mvn 打包 → 5 个服务镜像 + 部署物料镜像 → 推 ACR
#
# 用法（在 builder 上）:
#   ./build-services.sh <ACR地址> [版本tag]
#   ACR 地址形如 crpi-xxxx-vpc.cn-beijing.personal.cr.aliyuncs.com/rerail
#
# 前置条件:
#   1. docker login 已完成（凭据见 ACR 控制台「访问凭证」，用户名见 acr.pass）
#   2. /etc/docker/daemon.json 已配置镜像加速（手动，见 README）
# 环境变量:
#   CARRIER_REPO  载体仓库地址（默认经 ghfast 代理克隆 GitHub）
#   SKIP_PUSH=1   只构建不推送
set -euo pipefail

ACR="${1:-${ACR:?用法: ./build-services.sh <ACR地址> [版本tag]}}"
TAG="${2:-latest}"
CARRIER_REPO="${CARRIER_REPO:-https://ghfast.top/https://github.com/nageoffer/12306.git}"
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/12306-src"

echo "==> [1/4] 载体源码"
if [ -d "$SRC/.git" ]; then
  echo "    已存在: $SRC（如需更新请手动 git pull）"
else
  git clone --depth 1 "$CARRIER_REPO" "$SRC"
fi

echo "==> [2/4] 准备构建上下文"
cp "$HERE/Dockerfile" "$HERE/settings-aliyun.xml" "$SRC/"
cd "$SRC"

echo "==> [3/4] 构建五个服务镜像（BuildKit 缓存挂载，首次较慢）"
# --provenance/--sbom=false：ACR 个人版不认 BuildKit 默认附带的 OCI 证明清单
# （unknown manifest class for application/vnd.oci.empty.v1+json）
for svc in gateway user ticket order pay; do
  echo "    ---- $svc ----"
  DOCKER_BUILDKIT=1 docker build --provenance=false --sbom=false \
    --build-arg SERVICE="$svc" --build-arg ACR_BASE="$ACR" \
    -t "$ACR/12306-$svc:$TAG" .
done

echo "==> [4/4] 部署物料镜像（SQL + 配置，供 Ansible/分发用）"
docker build --provenance=false --sbom=false --build-arg ACR_BASE="$ACR" \
  -f "$HERE/Dockerfile.deploy" -t "$ACR/12306-deploy:$TAG" "$HERE/.."

if [ "${SKIP_PUSH:-0}" = "1" ]; then
  echo "==> SKIP_PUSH=1，跳过推送。镜像保留在本地。"
else
  for img in gateway user ticket order pay deploy; do
    docker push "$ACR/12306-$img:$TAG"
  done
fi

echo "完成。镜像列表:"
docker images --format '{{.Repository}}:{{.Tag}}' | grep "$ACR/12306-" | sort
