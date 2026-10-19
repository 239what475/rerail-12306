#!/bin/bash
# monitor6.sh <秒> <输出> —— 资源画像：每服务 pod 的 JVM CPU 利用率 + 堆用量（OTel :port）
# 参数由调用方展开为 ip:port:名 列表
DUR=$1; OUT=$2; shift 2
PODS="$@"
END=$((SECONDS + DUR))
while [ $SECONDS -lt $END ]; do
  TS=$(date +%H:%M:%S); LINE="$TS"
  for p in $PODS; do
    ip=${p%%:*}; rest=${p#*:}; port=${rest%%:*}; name=${rest##*:}
    m=$(curl -s --max-time 3 http://$ip:$port/metrics 2>/dev/null)
    cpu=$(echo "$m" | grep '^jvm_cpu_recent_utilization' | head -1 | awk '{print $NF}' | cut -c1-5)
    heap=$(echo "$m" | grep '^jvm_memory_used_bytes' | grep 'jvm_memory_type="heap"' | awk '{s+=$NF} END {printf "%.0f", s/1048576}')
    echo "$m" | grep '^jvm_memory_used_bytes' | grep 'jvm_memory_type="heap"' | awk -v n="$name" '{s+=$NF} END {printf "%s_heap_mb %.0f\n", n, s/1048576}' >> /dev/null
    LINE="$LINE $name[cpu=$cpu heap=${heap}MB]"
  done
  echo "$LINE" >> "$OUT"
  sleep 10
done
