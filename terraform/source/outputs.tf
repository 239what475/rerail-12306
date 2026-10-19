# 公网入口 = ALB（Part B 起），见 alb_dns_name 输出；entry EIP 已释放

# Ansible inventory 数据源：ansible/inventory/generate.sh 消费此输出
# （builder 的 IP 在 terraform/builder 工作区输出：terraform output -raw builder_private_ip）
output "instance_private_ips" {
  description = "四台源端机器的内网 IP（generate.sh 生成 hosts.yml；部署时填入各机 .env 与 SECRETS.local.md）"
  value = {
    entry = alicloud_instance.rerail_entry.private_ip
    app   = alicloud_instance.rerail_app_2.private_ip
    db    = alicloud_instance.rerail_db.private_ip
    mw    = alicloud_instance.rerail_mw.private_ip
  }
}

output "instance_ids" {
  value = {
    entry = alicloud_instance.rerail_entry.id
    app   = alicloud_instance.rerail_app_2.id
    db    = alicloud_instance.rerail_db.id
    mw    = alicloud_instance.rerail_mw.id
  }
}

output "vpc_cidr" {
  description = "源端 VPC 网段（安全组放行范围，builder 也在其中）"
  value        = alicloud_vpc.rerail.cidr_block
}

output "builder_private_ip" {
  description = "builder 内网 IP"
  value        = alicloud_instance.builder.private_ip
}

output "builder_public_ip" {
  description = "builder EIP（本地 ssh root@此IP 触发 deploy.sh / Ansible）"
  value        = alicloud_eip.builder.ip_address
}
