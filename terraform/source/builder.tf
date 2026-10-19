# ============================================================
# Builder：构建/压测/观测机（与源端同 VPC，2026-10-18 由独立工作区并入）
# 生命周期独立需求用 targeted destroy 满足：
#   terraform destroy -target=alicloud_instance.builder
# ============================================================

# --- Builder 实例（4C16G，EIP 用于公网下载与 SSH 管理）---
resource "alicloud_instance" "builder" {
  instance_name        = "rerail-builder"
  host_name            = "rerail-builder"
  instance_type        = var.builder_instance_type
  image_id             = data.alicloud_images.ubuntu2204.images[0].id
  security_groups      = [alicloud_security_group.rerail.id, alicloud_security_group.builder_admin.id]
  vswitch_id           = alicloud_vswitch.rerail.id
  system_disk_category = "cloud_essd"
  system_disk_size     = 60
  password             = var.builder_password
  user_data            = file("builder-userdata.sh")
  tags                 = merge(local.tags, { role = "builder" })
}

# --- 管理安全组：仅公网 SSH（deploy.sh 从本地 ssh builder 触发 Ansible）---
resource "alicloud_security_group" "builder_admin" {
  security_group_name = "rerail-builder-admin"
  vpc_id              = alicloud_vpc.rerail.id
  inner_access_policy = "Accept"
}

resource "alicloud_security_group_rule" "builder_admin_ssh" {
  security_group_id = alicloud_security_group.builder_admin.id
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  nic_type          = "intranet"
  cidr_ip           = "0.0.0.0/0"
  policy            = "accept"
  priority          = 1
  description       = "builder admin SSH"
}

# 观测面公网访问（演示用：Grafana 3000，admin/ReRailGrafana_2026）
resource "alicloud_security_group_rule" "builder_grafana" {
  security_group_id = alicloud_security_group.builder_admin.id
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "3000/3000"
  nic_type          = "intranet"
  cidr_ip           = "0.0.0.0/0"
  policy            = "accept"
  priority          = 1
  description       = "Grafana public (demo)"
}

# --- EIP：按流量计费，仅下载与 SSH 管理 ---
resource "alicloud_eip" "builder" {
  address_name         = "rerail-builder-ip"
  internet_charge_type = "PayByTraffic"
  bandwidth            = 100
}

resource "alicloud_eip_association" "builder" {
  allocation_id = alicloud_eip.builder.id
  instance_id   = alicloud_instance.builder.id
}

# ============================================================
# Inventory 生成：apply 时直接写出 ansible/inventory/hosts.yml
# （替代原 generate.sh + 内嵌 python 解析 tfstate 的方案，2026-10-18）
# ============================================================
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/hosts.yml.tftpl", {
    entry_ip       = alicloud_instance.rerail_entry.private_ip
    app_ip         = alicloud_instance.rerail_app_2.private_ip
    db_ip          = alicloud_instance.rerail_db.private_ip
    mw_ip          = alicloud_instance.rerail_mw.private_ip
    builder_ip     = alicloud_instance.builder.private_ip
    builder_public = alicloud_eip.builder.ip_address
  })
  filename        = "${path.module}/../../ansible/inventory/hosts.yml"
  file_permission = "0644"
}
