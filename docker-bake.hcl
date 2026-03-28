group "default" {
  targets = ["claude-code", "opencode"]
}

target "claude-code" {
  context    = "."
  dockerfile = "docker/claude-code.dockerfile"
  tags       = ["df-claude-code"]
}

target "opencode" {
  context    = "."
  dockerfile = "docker/opencode.dockerfile"
  tags       = ["df-opencode"]
}
