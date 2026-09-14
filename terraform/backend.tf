terraform {
  backend "s3" {
    bucket       = "jrribeeiro-tc3-tfstate-2026"
    key          = "techchallenge3/infra.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
