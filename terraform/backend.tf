terraform {
  backend "s3" {
    bucket       = "BUCKET_DO_BOOTSTRAP"
    key          = "techchallenge3/infra.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
