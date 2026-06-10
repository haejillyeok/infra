terraform {
  # Bootstrap creates the remote backend bucket itself, so its initial state is local.
  backend "local" {
    path = "terraform.tfstate"
  }
}
