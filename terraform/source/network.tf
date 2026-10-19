locals {
  tags = { project = "rerail" }
}

resource "alicloud_resource_manager_resource_group" "rerail" {
  resource_group_name = "rerail"
  display_name        = "ReRail"
}

resource "alicloud_vpc" "rerail" {
  resource_group_id = alicloud_resource_manager_resource_group.rerail.id
  vpc_name          = "rerail-vpc"
  cidr_block        = "192.168.0.0/16"
  tags              = local.tags
}

resource "alicloud_vswitch" "rerail" {
  vswitch_name = "rerail-vsw"
  vpc_id       = alicloud_vpc.rerail.id
  cidr_block   = "192.168.0.0/24"
  zone_id      = var.zone
}

# 普通安全组：组内互通覆盖中间件端口，公网只开 80/22
resource "alicloud_security_group" "rerail" {
  security_group_name = "rerail-sg"
  vpc_id              = alicloud_vpc.rerail.id
  inner_access_policy = "Accept"
}

# HTTP（Nginx）：Part B 收口——仅 VPC 内网放行，公网流量只走 ALB（内网转发）。
# 2026-10-18 实测：DNS 同步归零后关闭旧路径，压测 0 错误（T0 验证见 evidence/part-b-dns/）
resource "alicloud_security_group_rule" "allow_http" {
  security_group_id = alicloud_security_group.rerail.id
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  nic_type          = "intranet"
  cidr_ip           = "192.168.0.0/16"
  policy            = "accept"
  priority          = 1
}

# 仅 VPC 内网 SSH
resource "alicloud_security_group_rule" "allow_ssh_vpc" {
  security_group_id = alicloud_security_group.rerail.id
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  nic_type          = "intranet"
  cidr_ip           = "192.168.0.0/16"
  policy            = "accept"
  priority          = 1
}

# Prometheus 抓取：node_exporter + cAdvisor
resource "alicloud_security_group_rule" "allow_prometheus_node" {
  security_group_id = alicloud_security_group.rerail.id
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "9100/9100"
  nic_type          = "intranet"
  cidr_ip           = "192.168.0.0/16"
  policy            = "accept"
  priority          = 1
  description       = "node_exporter from VPC"
}

resource "alicloud_security_group_rule" "allow_prometheus_cadvisor" {
  security_group_id = alicloud_security_group.rerail.id
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "8080/8080"
  nic_type          = "intranet"
  cidr_ip           = "192.168.0.0/16"
  policy            = "accept"
  priority          = 1
  description       = "cAdvisor from VPC"
}

# OTel metrics（Prometheus 抓取 9464-9467）
resource "alicloud_security_group_rule" "allow_prometheus_otel" {
  security_group_id = alicloud_security_group.rerail.id
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "9464/9467"
  nic_type          = "intranet"
  cidr_ip           = "192.168.0.0/16"
  policy            = "accept"
  priority          = 1
  description       = "OTel metrics from VPC"
}

# ============================================================
# Part C：ACK worker/Pod（192.168.2.0/23 覆盖节点段+Pod段）→ 共享层放行
# 源端服务靠 rerail-sg 组内互通访问 db/mw；ACK 节点在另一个安全组，
# 必须显式放行（08 方案 §2 暗坑清单，9848/10911 是 Part A 踩过的雷）
# ============================================================
resource "alicloud_security_group_rule" "ack_to_shared" {
  count = length(var.ack_shared_ports)

  security_group_id = alicloud_security_group.rerail.id
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "${var.ack_shared_ports[count.index]}/${var.ack_shared_ports[count.index]}"
  nic_type          = "intranet"
  cidr_ip           = "192.168.2.0/23"
  policy            = "accept"
  priority          = 1
  description       = "ACK workers/pods -> shared layer ${var.ack_shared_ports[count.index]}"
}

variable "ack_shared_ports" {
  description = "ACK 节点/Pod 访问共享层(db/mw/builder观测)的端口"
  type        = list(string)
  default     = ["3306", "6379", "8848", "9848", "9876", "10911", "9411"]
}
