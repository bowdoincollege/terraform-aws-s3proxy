output "private_key" {
  description = "s3proxy instance private ssh key"
  value       = "${tls_private_key.this.private_key_pem}"
}

output "nlb_dns_name" {
  description = "network load balancer dns endpoint"
  value       = "${aws_lb.s3proxy.dns_name}"
}

output "nlb_zone_id" {
  description = "network load balancer dns zone id"
  value       = "${aws_lb.s3proxy.zone_id}"
}
