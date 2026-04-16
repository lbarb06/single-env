output "web_public_ip" {
  value = module.web_ec2.public_ip
}

output "web_url" {
  value = "http://${module.web_ec2.public_ip}"
}
