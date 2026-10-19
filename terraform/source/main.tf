terraform {
  required_version = ">= 1.5"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      # v2.0.0 在部分流程有 bug，锁定 1.x 稳定线
      version = ">= 1.230, < 2.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "alicloud" {
  region  = var.region
  profile = var.aliyun_profile
}
