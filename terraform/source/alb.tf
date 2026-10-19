# ============================================================
# Part B · ALB 流量总开关（2026-10-18）
# 唯一公网入口：域名 CNAME → ALB → 后端组A（源端 nginx）
# Part C 灰度时在同一 ALB 上加后端组B（ACK NodePort）调权重
# 实验要点：DNS 衰减实测 + 服务下线窗口计量（evidence/part-b-dns/）
# ============================================================

resource "alicloud_alb_load_balancer" "rerail" {
  load_balancer_name    = "rerail-alb"
  vpc_id                = alicloud_vpc.rerail.id
  address_type          = "Internet" # 公网型（按量计费，实验量级每天个位数元）
  load_balancer_edition = "Standard"

  # 必须显式声明（Optional, ForceNew，默认 Dynamic）：Basic 版实际返回 Fixed，
  # 缺省时 state(Fixed) vs config(null) 永久漂移 → 每次 apply 整链重建 ALB
  # （2026-10-18 事故根因：重建换新 dns_name → CNAME 悬空 NXDOMAIN）
  address_allocated_mode = "Fixed"

  load_balancer_billing_config {
    pay_type = "PayAsYouGo" # 按量付费
  }

  zone_mappings {
    zone_id    = var.zone
    vswitch_id = alicloud_vswitch.rerail.id
  }
  # ALB 强制多 AZ：副区用 ALB 专用交换机（不承载业务实例）
  zone_mappings {
    zone_id    = var.alb_backup_zone
    vswitch_id = alicloud_vswitch.alb_backup.id
  }

  modification_protection_config {
    status = "NonProtection"
  }
}

# ALB 副可用区交换机（仅满足 ALB 多 AZ 要求）
resource "alicloud_vswitch" "alb_backup" {
  vswitch_name = "rerail-vsw-alb"
  vpc_id       = alicloud_vpc.rerail.id
  cidr_block   = "192.168.1.0/24"
  zone_id      = var.alb_backup_zone
}

resource "alicloud_alb_server_group" "source_nginx" {
  server_group_name = "rerail-backend-a-source"
  vpc_id            = alicloud_vpc.rerail.id
  protocol          = "HTTP"

  health_check_config {
    health_check_enabled     = true
    health_check_protocol    = "TCP" # TCP 探活，不依赖业务返回码
    health_check_connect_port = "80"
    health_check_interval    = 2
    health_check_timeout     = 3
    healthy_threshold        = 2
    unhealthy_threshold      = 3
  }

  sticky_session_config {
    sticky_session_enabled = false
  }

  # 此 provider 版本无独立 server_group_server 资源，servers 内联在组里
  servers {
    server_type = "Ecs"
    server_id   = alicloud_instance.rerail_entry.id
    port        = 80
    weight      = 100
    description = "源端 nginx（后端组A，灰度前 100%）"
  }
}

# Part C：监听器 80 移交 ALB Ingress Controller（AlbConfig forceOverride=true 接管；回滚=取消注释+apply）
# # Part C 终态：监听器 80 已移交 ALB Ingress Controller（AlbConfig forceOverride=true，
# 混合转发由 Ingress actions 注解定义，源端组经 ServerGroupID 保留）。回滚=取消注释+apply
# resource "alicloud_alb_listener" "http80" {
# #   load_balancer_id  = alicloud_alb_load_balancer.rerail.id
# #   listener_protocol = "HTTP"
# #   listener_port     = 80

# #   default_actions {
# #     type = "ForwardGroup"
# #     forward_group_config {
# #       server_group_tuples {
# #         server_group_id = alicloud_alb_server_group.source_nginx.id
# #       }
# #     }
# #   }
# # }

output "alb_dns_name" {
  description = "ALB 域名（DNS CNAME 指向此地址）"
  value       = alicloud_alb_load_balancer.rerail.dns_name
}
