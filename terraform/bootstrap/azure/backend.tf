terraform {
  # Bootstrap creates the remote backend storage account itself, so its initial state is local.
  backend "local" {
    path = "terraform.tfstate"
  }
}
