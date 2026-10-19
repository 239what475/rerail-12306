#!/bin/bash
# run-test.sh — 压测一键启动（清残留进程 → 重置数据 → 检查种子 → 启动 k6）
# 用法: ./run-test.sh <RATE> <DURATION>   （BASE 未设时自动从 terraform state 读入口 IP）
# 例如: ./run-test.sh 4000 300s
set -e
RATE=${1:-4000}
DUR=${2:-300s}
cd "$(dirname "$0")"

# 入口：优先 BASE 环境变量（内网压测填 entry 内网 IP；真实用户路径填域名走 ALB），
# 否则从 terraform state 自动取 entry 内网 IP（零公网带宽变量；entry EIP 已于 Part B 释放）
if [ -z "${BASE:-}" ]; then
  STATE=/opt/rerail/terraform/source/terraform.tfstate
  if [ -f "$STATE" ]; then
    ENTRY=$(python3 -c "import json; print(json.load(open('$STATE'))['outputs']['instance_private_ips']['value']['entry'])")
    BASE="http://$ENTRY"
  else
    BASE="http://<你的域名>"   # 兜底：走域名（经 ALB）
  fi
fi
echo "BASE=$BASE"
export BASE

echo "=== 0. 清理残留进程 ==="
pkill -f "seat-resetter" 2>/dev/null || true
pkill -f "temp/seat" 2>/dev/null || true
rm -f /tmp/seat-resetter.pid
echo "已清理"

echo "=== 1. 数据重置（提示：在本地执行 reset-test-data-k8s.sh）==="

echo "=== 2. 检查账号池 ==="
if [ -s users.json ]; then
    COUNT=$(python3 -c "import json; d=json.load(open('users.json')); print(len(d))" 2>/dev/null || echo 0)
    PAX=$(python3 -c "import json; d=json.load(open('users.json')); print(sum(len(u.get('passengers',[])) for u in d))" 2>/dev/null || echo 0)
    echo "已有 $COUNT 个代理, $PAX 个乘客"
else
    echo "users.json 不存在或为空，重新生成..."
    ./seed-agents.sh
fi

echo "=== 3. 启动压测: ${RATE} RPS × ${DUR} ==="
k6 run -e RATE=$RATE -e DUR=$DUR full-flow.js
