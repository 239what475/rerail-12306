#!/usr/bin/env bash
# OTel Java Agent 下载（版本锁定 + SHA256 校验）
# 产出: build/artifacts/opentelemetry-javaagent.jar
# 分发: Ansible role app/entry 从此路径 copy 到节点 /opt/rerail/otel/
set -euo pipefail

OTEL_VERSION="v2.32.0"
# 基准值 = 当前生产在用 jar（f787eb6…，产自 2026-10 全链路压测环境）
OTEL_SHA256="f787eb6c7f3d18e69a431e108a15278d25ee37f83d68b678f621e063f3988f82"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/artifacts/opentelemetry-javaagent.jar"
mkdir -p "$HERE/artifacts"

URLS=(
  "https://ghfast.top/https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/${OTEL_VERSION}/opentelemetry-javaagent.jar"
  "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/${OTEL_VERSION}/opentelemetry-javaagent.jar"
)

# 已存在且校验通过则跳过
if [ -f "$OUT" ] && echo "$OTEL_SHA256  $OUT" | sha256sum -c --quiet 2>/dev/null; then
  echo "已存在且校验通过: $OUT"
  exit 0
fi

for url in "${URLS[@]}"; do
  echo "==> 下载 $OTEL_VERSION（$url）"
  if curl -fSL --retry 3 --max-time 600 "$url" -o "$OUT"; then
    if echo "$OTEL_SHA256  $OUT" | sha256sum -c --quiet; then
      echo "SHA256 校验通过: $OUT"
      exit 0
    fi
    echo "SHA256 不匹配，尝试下一个源"
  fi
done

echo "错误: 下载或校验失败" >&2
rm -f "$OUT"
exit 1
