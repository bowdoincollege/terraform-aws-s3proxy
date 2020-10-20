# AWS S3 Proxy

A autoscaling proxy to allow access to S3 gateway endpoints from
outside the VPC.

<!-- markdownlint-disable -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| aws | ~> 3.11.0 |
| tls | ~> 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.11.0 |
| tls | ~> 3.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| egress\_allowed\_cidr | allowed oubound networks | `list` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| environment | environment in names and tags | `string` | n/a | yes |
| instance\_type | instance type | `string` | `"m5.xlarge"` | no |
| max\_size | maximum number of proxy instances | `number` | `9` | no |
| min\_size | minimum number of proxy instances | `number` | `2` | no |
| proxy\_allowed\_cidr | networks to allow proxy | `string` | n/a | yes |
| proxy\_port | squid proxy port | `number` | `3128` | no |
| region | AWS region | `string` | n/a | yes |
| ssh\_allowed\_cidr | networks to allow ssh | `string` | n/a | yes |
| subnet\_ids | list of subnet ids | `list` | n/a | yes |
| tags | additional tags | `map` | n/a | yes |
| vpc\_id | VPC id | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| nlb\_dns\_name | network load balancer dns endpoint |
| nlb\_zone\_id | network load balancer dns zone id |
| private\_key | s3proxy instance private ssh key |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-restore -->
