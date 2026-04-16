module "web_ec2" {
  source       = "./modules/ec2"
  project_name = var.project_name
}
