output "backend_config" {
  value = {
    bucket       = aws_s3_bucket.terraform_state.bucket
    key          = "haejillyeok/aws/terraform.tfstate"
    region       = var.region
    encrypt      = true
    use_lockfile = true
  }
}
