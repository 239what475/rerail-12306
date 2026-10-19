terraform {
  required_version = ">= 1.5"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.230, < 2.0.0"
    }
  }
}

provider "alicloud" {
  region  = var.region
  profile = var.aliyun_profile
}

variable "aliyun_profile" {
  type    = string
  default = "thinkbook"
}

variable "region" {
  type    = string
  default = "cn-beijing"
}

variable "zone" {
  type    = string
  default = "cn-beijing-f"
}

variable "ack_password" {
  description = "worker 节点 root 密码（敏感，tfvars 提供，不入库）"
  type        = string
  sensitive   = true
}

data "alicloud_vpcs" "rerail" {
  name_regex = "^rerail-vpc$"
}

locals {
  vpc_id = data.alicloud_vpcs.rerail.vpcs[0].id
}

# --- ACK 专用交换机：节点段 2.0/24 + Pod 段 3.0/24（Terway，与节点段不重叠）---
resource "alicloud_vswitch" "node" {
  vswitch_name = "rerail-vsw-ack-node"
  vpc_id       = local.vpc_id
  cidr_block   = "192.168.2.0/24"
  zone_id      = var.zone
}

resource "alicloud_vswitch" "pod" {
  vswitch_name = "rerail-vsw-ack-pod"
  vpc_id       = local.vpc_id
  cidr_block   = "192.168.3.0/24"
  zone_id      = var.zone
}

# --- ACK 托管集群 Basic（管理面免费）+ 独立节点池（provider 1.294 强制分离）---
resource "alicloud_cs_managed_kubernetes" "ack" {
  name         = "rerail-ack"
  cluster_spec = "ack.standard" # 托管标准版（Basic，管理面免费）

  vswitch_ids     = [alicloud_vswitch.node.id] # vpc 由 vswitch 推导（vpc_id 不可直设）
  service_cidr    = "172.21.0.0/20"
  pod_vswitch_ids = [alicloud_vswitch.pod.id] # Terway：Pod IP 直入 VPC（addon 必须叫 terway-eniip，见下）

  # 不建 NAT（镜像走 ACR VPC endpoint + acs 内网 registry，零公网依赖）；
  # API Server 公网端点默认开（本地 kubectl 用）
  new_nat_gateway = false

  # alb-ingress-controller：2026-10-19 经 Terraform 安装的实例因配置参数问题未正常工作，已卸载；
  # 改由控制台「组件管理」安装并选择「使用已有」关联 alb-3fm0b4rrxch8g8nzdh（勿在此重复声明）
  addons {
    name = "terway-eniip" # 共享 ENI 模式（默认）—— ALB Ingress Controller 自动发现 Pod，不依赖独占 ENI
    config = jsonencode({
      PodVswitchIds = jsonencode({ (var.zone) = alicloud_vswitch.pod.id })
    })
  }
  addons {
    name = "csi-provisioner"
  }
  addons {
    name = "csi-plugin"
  }
  addons {
    name = "coredns"
  }
  addons {
    name = "kube-proxy"
  }
  addons {
    name = "metrics-server"
  }
  addons {
    name = "aliyun-acr-credential-helper"
    config = jsonencode({
      watch-namespace = "all" # 监控全部 namespace，为有 rerail-sa 的 SA 注入 pull secret
    })
  }

  deletion_protection = false

  # RRSA（服务账户 OIDC 假冒角色）：自管 alb-ingress-controller 免 AK/SK
  # 调 ALB OpenAPI（托管 addon 因缺控制器部署失效，自管走这条路）
  enable_rrsa = true

  timeouts {
    create = "90m"
    delete = "60m"
  }
}

# --- ACK 自动创建安全组补 VPC 放行 ---
# Terway 共享 ENI 模式下 Pod IP（192.168.3.0/24）本身 VPC 可路由，
# 但 ACK 建群时自动创建的 SG 只放行了 NodePort/KubeProxy 等系统端口；
# 显式放行 VPC 网段，使 builder 等集群外 ECS 可直连 Pod IP（绕过 ALB 压测，定位瓶颈层）
data "alicloud_security_groups" "ack_auto" {
  name_regex = "alicloud-cs-auto-created-security-group-${alicloud_cs_managed_kubernetes.ack.id}"
}

resource "alicloud_security_group_rule" "vpc_to_nodes_and_pods" {
  security_group_id = data.alicloud_security_groups.ack_auto.groups[0].id
  type              = "ingress"
  ip_protocol       = "all"
  port_range        = "-1/-1"
  nic_type          = "intranet"
  cidr_ip           = "192.168.0.0/16"
  policy            = "accept"
  priority          = 1
  description       = "VPC -> ACK nodes/pods (Terway Pod IP direct access for capacity diagnosis)"
}

# --- Worker 节点池：2×4C8G（与源端 app 同级，容量对比公平）---
resource "alicloud_cs_kubernetes_node_pool" "workers" {
  cluster_id         = alicloud_cs_managed_kubernetes.ack.id
  node_pool_name     = "rerail-workers"
  vswitch_ids        = [alicloud_vswitch.node.id]
  instance_types     = ["ecs.u2a-c1m2.xlarge"]
  desired_size       = 4 # 3×8G 内存已 95%+：终态 17 pod 无弹性空间，SystemOOM 前科；加 1 节点承载 HPA 扩容
  system_disk_category = "cloud_essd"
  system_disk_size   = 60
  # platform 不指定：provider 枚举 AliyunLinux 映射 AliyunLinux 2（不支持 cgroup v2，API 拒绝）
  password           = var.ack_password
}

output "cluster_id" {
  value = alicloud_cs_managed_kubernetes.ack.id
}

output "api_server_slb_ip" {
  description = "API Server 公网端点 IP"
  value       = alicloud_cs_managed_kubernetes.ack.slb_internet
}

# kubeconfig 手动导出（不入仓库）：
#   terraform output -raw kube_config > ~/.kube/rerail-ack
output "kube_config" {
  description = "kubeconfig（敏感）"
  value       = alicloud_cs_managed_kubernetes.ack.kube_config
  sensitive   = true
}
