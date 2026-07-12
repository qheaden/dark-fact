group "default" {
  targets = ["opencode"]
}

target "opencode" {
  context    = "."
  dockerfile = "docker/opencode.dockerfile"
  tags       = ["df-opencode"]
}
