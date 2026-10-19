#!/bin/bash
# reset-test-data-k8s.sh — Part C：清空测试产生的订单/支付/座位状态（MySQL/Redis 已迁入 ACK）
# 在本地执行（依赖 kubectl + ~/.kube/rerail-ack）；对应源端版 reset-test-data.sh
set -e
KC="kubectl --kubeconfig $HOME/.kube/rerail-ack -n rerail"

SQL="SET FOREIGN_KEY_CHECKS=0;"
# 分表为全局索引命名：db_0 存 _0..15，db_1 存 _16..31（源端脚本按 0..15 清 db_1 是无效语句，
# 被静默吞错——即 Part A 的重置从未真正清过 db_1，此处一并修正）
for dbIdx in 0 1; do
  db="12306_order_${dbIdx}"
  for i in $(seq 0 15); do
    t=$((dbIdx * 16 + i))
    SQL="${SQL} TRUNCATE ${db}.t_order_${t}; TRUNCATE ${db}.t_order_item_${t}; TRUNCATE ${db}.t_order_item_passenger_${t};"
  done
done
for dbIdx in 0 1; do
  db="12306_pay_${dbIdx}"
  for i in $(seq 0 15); do
    t=$((dbIdx * 16 + i))
    SQL="${SQL} TRUNCATE ${db}.t_pay_${t};"
  done
done
SQL="${SQL} UPDATE 12306_ticket.t_seat SET seat_status = 0; SET FOREIGN_KEY_CHECKS=1;"

echo "=== 清订单/支付/座位（单次 exec） ==="
echo "$SQL" | $KC exec -i mysql-0 -- mysql -uroot -proot 2>/dev/null
echo "表已清"

echo "=== 清 Redis（登录态为无状态 JWT，FLUSH 安全；同时清余量缓存强制回源） ==="
$KC exec redis-0 -- redis-cli -a 123456 --no-auth-warning FLUSHDB 2>/dev/null
echo "Redis 已清"

echo "=== 验证 ==="
$KC exec mysql-0 -- mysql -uroot -proot -N -e "
SELECT CONCAT('剩余订单: ', COUNT(*)) FROM 12306_order_0.t_order_0;
SELECT CONCAT('剩余支付: ', COUNT(*)) FROM 12306_pay_0.t_pay_0;
SELECT CONCAT('可用座位: ', COUNT(*)) FROM 12306_ticket.t_seat WHERE seat_status = 0;
" 2>/dev/null
echo "=== 完成 ==="
