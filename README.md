# 换轨 ReRail

出行购票系统从传统 ECS 集群零停机迁入阿里云 ACK。

## 架构

```
用户 → ALB（按权重切流）
  → ACK 集群
      ├─ gateway / user / ticket / order / pay（HPA 1→3）
      ├─ HAProxy（数据代理，runtime API 热切换后端）
      │    ├─ :6379 → Redis
      │    └─ :3306 → MySQL
      ├─ RocketMQ / Nacos / Zipkin / Prometheus / Grafana
```

## 部署

```bash
# 1. 云资源
cd terraform/source && terraform apply
cd ../ack && terraform apply

# 2. 镜像（在 builder 上）
cd build && ./sync-images.sh <ACR地址> && ./build-services.sh <ACR地址>

# 3. 服务
kubectl apply -f deploy/k8s/
```

## 迁移协议（零停机切换）

以 MySQL 为例（Redis 同理，写暂停命令不同）：

```
① 目标实例作为源端的从库，等追平
② 源端 SET GLOBAL read_only = ON     ← 写拒绝（读不受影响）
③ 目标 STOP REPLICA                  ← 升主
④ HAProxy runtime API 切后端          ← 秒级
⑤ 源端 SET GLOBAL read_only = OFF    ← 回滚保险
```

实测写停机：Redis 4s，MySQL 10s（Job 版 136ms）。双向回滚验证通过。

## 结果

300 RPS 域名全链路：99.84% 通过，med 21.79ms。

## 目录

```
deploy/k8s/       ACK 清单
deploy/source/    源端 compose
terraform/        基础设施
build/            镜像构建
load-test/        压测工具
ansible/          源端部署
```
