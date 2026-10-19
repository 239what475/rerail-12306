variable "aliyun_profile" {
  description = "aliyun CLI 配置文件（~/.aliyun/config.json）中的 profile 名"
  type        = string
  default     = "thinkbook"
}

variable "region" {
  description = "地域"
  type        = string
  default     = "cn-beijing"
}

variable "zone" {
  description = "可用区（交换机所在区，所有实例同区）"
  type        = string
  default     = "cn-beijing-f"
}

variable "ecs_password" {
  description = "五台 ECS 的 root 密码（敏感，经 terraform.tfvars 提供，不入库）"
  type        = string
  sensitive   = true
}

variable "type_small" {
  description = "非核心机型（entry / app-1，2C4G）"
  type        = string
  default     = "ecs.u2a-c1m2.large"
}

variable "type_large" {
  description = "核心机型（app-2 / db / mw，4C8G）"
  type        = string
  default     = "ecs.u2a-c1m2.xlarge"
}

variable "builder_password" {
  description = "builder 机的 root 密码（敏感，经 terraform.tfvars 提供，不入库）"
  type        = string
  sensitive   = true
}

variable "builder_instance_type" {
  description = "builder 机型（默认 4C16G，跑 Maven/Docker 构建用；临时可降配）"
  type        = string
  default     = "ecs.u2a-c1m4.xlarge"
}

variable "alb_backup_zone" {
  description = "ALB 副可用区（ALB 强制多 AZ；主区=var.zone）"
  type        = string
  default     = "cn-beijing-g"
}
