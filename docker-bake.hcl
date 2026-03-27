group "default" {
  targets = ["claude-code"]
}

target "claude-code" {
  context    = "."
  dockerfile = "docker/claude-code.dockerfile"
  tags       = ["df-claude-code"]
}
