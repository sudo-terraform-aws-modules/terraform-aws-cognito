provider "aws" {
  region = "eu-west-1"
}

module "cognito" {
  source = "../../"

  name = "example-minimal"

  clients = {
    web = {}
  }
}
