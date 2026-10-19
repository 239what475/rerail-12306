data "alicloud_images" "ubuntu2204" {
  name_regex  = "^ubuntu_22_04_x64"
  most_recent = true
  owners      = "system"
}

# --- 接入层（2C4G）：Nginx + gateway，公网 EIP 绑定于此 ---
resource "alicloud_instance" "rerail_entry" {
  resource_group_id    = alicloud_resource_manager_resource_group.rerail.id
  instance_name        = "rerail-entry"
  host_name            = "rerail-entry"
  instance_type        = "ecs.u2a-c1m1.xlarge"  # 4C4G：缩容（内存捡漏），2026-10-17 二轮
  image_id             = data.alicloud_images.ubuntu2204.images[0].id
  security_groups      = [alicloud_security_group.rerail.id]
  vswitch_id           = alicloud_vswitch.rerail.id
  system_disk_category = "cloud_essd"
  system_disk_size     = 40
  password             = var.ecs_password
  user_data            = file("userdata.sh")
  tags                 = local.tags
}

# --- 应用层（合并节点：user+ticket+order+pay，2026-10-17 合并调优）---
# --- 应用层·核心（4C8G）：order + pay ---
resource "alicloud_instance" "rerail_app_2" {
  resource_group_id    = alicloud_resource_manager_resource_group.rerail.id
  instance_name        = "rerail-app-2"
  host_name            = "rerail-app-2"
  instance_type        = "ecs.u2a-c1m2.2xlarge"  # 8C16G：8C8G不在u2a系列(c1m1最大4C4G)
  image_id             = data.alicloud_images.ubuntu2204.images[0].id
  security_groups      = [alicloud_security_group.rerail.id]
  vswitch_id           = alicloud_vswitch.rerail.id
  system_disk_category = "cloud_essd"
  system_disk_size     = 40
  password             = var.ecs_password
  user_data            = file("userdata.sh")
  tags                 = local.tags
}

# --- 数据层（4C8G）：MySQL（7 库）---
resource "alicloud_instance" "rerail_db" {
  resource_group_id    = alicloud_resource_manager_resource_group.rerail.id
  instance_name        = "rerail-db"
  host_name            = "rerail-db"
  instance_type        = "ecs.u2a-c1m1.xlarge"  # 4C4G：缩容
  image_id             = data.alicloud_images.ubuntu2204.images[0].id
  security_groups      = [alicloud_security_group.rerail.id]
  vswitch_id           = alicloud_vswitch.rerail.id
  system_disk_category = "cloud_essd"
  system_disk_size     = 40
  password             = var.ecs_password
  user_data            = file("userdata.sh")
  tags                 = local.tags
}

# --- 中间件层（4C8G）：Redis + RocketMQ + Nacos ---
resource "alicloud_instance" "rerail_mw" {
  resource_group_id    = alicloud_resource_manager_resource_group.rerail.id
  instance_name        = "rerail-mw"
  host_name            = "rerail-mw"
  instance_type        = "ecs.u2a-c1m1.xlarge"  # 4C4G：缩容
  image_id             = data.alicloud_images.ubuntu2204.images[0].id
  security_groups      = [alicloud_security_group.rerail.id]
  vswitch_id           = alicloud_vswitch.rerail.id
  system_disk_category = "cloud_essd"
  system_disk_size     = 40
  password             = var.ecs_password
  user_data            = file("userdata.sh")
  tags                 = local.tags
}

# --- entry 公网 EIP 已于 2026-10-18 释放（Part B 收口）：
#     公网入口唯一化为 ALB（域名 CNAME），EIP 直连路径安全组已关、无流量 ---

# --- 纯出口 EIP：app/db/mw 装 Docker 等软件需要公网（安全组未开这些节点的
#     公网入方向，绑定后仅出站，按流量计费闲时零成本；建机完成后可 terraform
#     destroy -target 释放）---
resource "alicloud_eip" "app" {
  address_name         = "rerail-ip-app-egress"
  internet_charge_type = "PayByTraffic"
  bandwidth            = 100
}

resource "alicloud_eip_association" "app" {
  allocation_id = alicloud_eip.app.id
  instance_id   = alicloud_instance.rerail_app_2.id
}

resource "alicloud_eip" "db" {
  address_name         = "rerail-ip-db-egress"
  internet_charge_type = "PayByTraffic"
  bandwidth            = 100
}

resource "alicloud_eip_association" "db" {
  allocation_id = alicloud_eip.db.id
  instance_id   = alicloud_instance.rerail_db.id
}

resource "alicloud_eip" "mw" {
  address_name         = "rerail-ip-mw-egress"
  internet_charge_type = "PayByTraffic"
  bandwidth            = 100
}

resource "alicloud_eip_association" "mw" {
  allocation_id = alicloud_eip.mw.id
  instance_id   = alicloud_instance.rerail_mw.id
}
