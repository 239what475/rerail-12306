#!/usr/bin/env bash
# ReRail 一键部署入口（本地执行）：
#   ./deploy.sh init    # 首次：同步仓库到 builder + --ask-pass 引导 SSH 密钥
#   ./deploy.sh         # 之后：同步仓库 + ansible-playbook（免密）
# BUILDER_EIP 未设置时自动从 terraform state 读取（terraform apply 已并入单工作区）
# inventory（ansible/inventory/hosts.yml）由 terraform apply 的 local_file 直接生成
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

if [ -z "${BUILDER_EIP:-}" ]; then
  BUILDER_EIP=$(python3 -c "
import json
s=json.load(open(r'$HERE/terraform/source/terraform.tfstate'))
print(s['outputs']['builder_public_ip']['value'])
")
fi
echo "builder EIP: $BUILDER_EIP"

echo "==> [1/3] 同步仓库到 builder（/opt/rerail）"
ssh "root@$BUILDER_EIP" "mkdir -p /opt/rerail"
scp -qr "$HERE/ansible" "$HERE/deploy" "$HERE/load-test" "$HERE/build" "$HERE/terraform" "root@$BUILDER_EIP:/opt/rerail/"

echo "==> [2/3] inventory 由 terraform apply 生成，随仓库同步（无需在 builder 生成）"
[ -f "$HERE/ansible/inventory/hosts.yml" ] || { echo "缺少 hosts.yml：请先 terraform apply（terraform/source）"; exit 1; }

echo "==> [3/3] 运行 Ansible"
if [ "${1:-}" = "init" ]; then
  ssh -t "root@$BUILDER_EIP" "cd /opt/rerail/ansible && ansible-playbook site.yml --ask-pass"
else
  ssh "root@$BUILDER_EIP" "cd /opt/rerail/ansible && ansible-playbook site.yml"
fi
