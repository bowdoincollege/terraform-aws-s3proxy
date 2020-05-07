###
# Required variables.
###
variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "subnet_ids" {
  description = "list of subnet ids"
  type        = list
}

variable "proxy_allowed_cidr" {
  description = "networks to allow proxy"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "networks to allow ssh"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

# Environment (ex: dev or prod) gets appended to names and tags.
variable "environment" {
  description = "environment in names and tags"
  type        = string
}

###
# Optional variables. Generally okay to leave at the default.
###

# Additional tags to apply to all tagged resources.
variable "tags" {
  description = "additional tags"
  type        = map
}

variable "proxy_port" {
  description = "squid proxy port"
  default     = 3128
}

variable "egress_allowed_cidr" {
  description = "allowed oubound networks"
  default = [
    "0.0.0.0/0",
  ]
}

variable "min_size" {
  description = "minimum number of proxy instances"
  default     = 2
}

variable "max_size" {
  description = "maximum number of proxy instances"
  default     = 9
}

variable "instance_type" {
  description = "instance type"
  default     = "m5.xlarge"
}
