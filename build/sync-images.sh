#!/usr/bin/env bash
# ReRail 官方镜像同步：拉 10 个官方镜像 → retag → 推用户 ACR
# 版本与 deploy/*/compose.yml 严格对应（compose 默认值即 ACR 内 tag）
#
# 用法（在 builder 上）:
#   ./sync-images.sh <ACR地址>
#
# 前置: docker login ACR；daemon.json 已配镜像加速（cadvisor/gcr 需要额外源，手动）
set -euo pipefail

ACR="${1:-${ACR:?用法: ./sync-images.sh <ACR地址>}}"
# 目标tag（ACR 内）         <- 官方源
declare -A IMAGES=(
  # --- 运行时镜像（compose 引用） ---
  ["12306-mysql:8.0"]            "mysql:8.0"
  ["12306-redis:7-alpine"]       "redis:7-alpine"
  ["12306-rocketmq:4.9.4"]       "apache/rocketmq:4.9.4"
  ["12306-nacos:v2.2.3"]         "nacos/nacos-server:v2.2.3"
  ["12306-nginx:1.25-alpine"]    "nginx:1.25-alpine"
  ["12306-prometheus:v3.1.0"]    "prom/prometheus:v3.1.0"
  ["12306-grafana:11.5.2"]       "grafana/grafana:11.5.2"
  ["12306-zipkin:3"]             "openzipkin/zipkin:3"
  ["12306-node-exporter:v1.9.1"] "prom/node-exporter:v1.9.1"
  ["12306-cadvisor:v0.60.6"]     "cadvisor/cadvisor:v0.60.6"   # 官方源 gcr.io/cadvisor/cadvisor，docker.io 同名同步
  # --- 构建基础镜像（build/Dockerfile FROM 引用，入 ACR 后构建不再依赖 docker.io） ---
  ["12306-maven:3.9-temurin17"]  "maven:3.9-eclipse-temurin-17"
  ["12306-jre:17"]               "eclipse-temurin:17-jre"
  ["12306-alpine:3.19"]          "alpine:3.19"
)

fail=0
for dst in "${!IMAGES[@]}"; do
  src="${IMAGES[$dst]}"
  echo "==> $src  →  $ACR/$dst"
  if ! docker pull "$src"; then
    echo "    拉取失败（镜像加速源需手动配置时：请手动 docker pull + push 这一条）"
    fail=1
    continue
  fi
  docker tag "$src" "$ACR/$dst"
  docker push "$ACR/$dst"
done

[ "$fail" = "0" ] && echo "全部同步完成。" || echo "存在失败项，见上方日志。"
exit "$fail"
