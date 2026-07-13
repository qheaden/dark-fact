group "default" {
  targets = ["factory"]
}

target "factory" {
  context    = "."
  dockerfile = "docker/factory.dockerfile"
  tags       = ["dark-factory"]
}
