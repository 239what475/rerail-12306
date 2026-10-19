# ============================================================
# ALB Ingress Controller 服务角色
# 托管组件操作 ALB（建组/挂 Pod endpoint/健康检查）需以本角色身份调 OpenAPI。
# 缺失时 addon 半装死：CRD/RBAC 就位但控制器 Deployment 永不部署
# （与 Part C 期间 AliyunCSManagedAcrRole 需控制台授权是同一机制，
#  这里用 Terraform 等价创建，权限挂系统策略 AliyunALBFullAccess）
# ============================================================
resource "alicloud_ram_role" "cs_managed_alb" {
  name        = "AliyunCSManagedALBRole"
  description = "Service role for ACK managed component alb-ingress-controller"
  document = jsonencode({
    Version = "1"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = ["cs.aliyuncs.com"] }
    }]
  })
}

resource "alicloud_ram_role_policy_attachment" "cs_managed_alb" {
  role_name   = alicloud_ram_role.cs_managed_alb.name
  policy_name = "AliyunALBFullAccess"
  policy_type = "System"
}

# ============================================================
# RRSA 角色：自管 alb-ingress-controller 的 SA 通过 OIDC 假冒本角色
# 调 ALB OpenAPI（免 AK/SK）
# ============================================================
resource "alicloud_ram_role" "alb_ingress_rrsa" {
  name        = "rerail-alb-ingress-rrsa"
  description = "RRSA role for self-managed alb-ingress-controller SA"
  document = jsonencode({
    Version = "1"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Federated = [alicloud_cs_managed_kubernetes.ack.rrsa_metadata[0].ram_oidc_provider_arn] }
      Condition = {
        StringEquals = {
          "oidc:sub" = "system:serviceaccount:kube-system:alb-ingress-controller"
          "oidc:aud" = "sts.aliyuncs.com"
        }
      }
    }]
  })
}

resource "alicloud_ram_role_policy_attachment" "alb_ingress_rrsa_alb" {
  role_name   = alicloud_ram_role.alb_ingress_rrsa.name
  policy_name = "AliyunALBFullAccess"
  policy_type = "System"
}

# 控制器建后端组/健康检查时需读 VPC/交换机信息
resource "alicloud_ram_role_policy_attachment" "alb_ingress_rrsa_vpc" {
  role_name   = alicloud_ram_role.alb_ingress_rrsa.name
  policy_name = "AliyunVPCReadOnlyAccess"
  policy_type = "System"
}
