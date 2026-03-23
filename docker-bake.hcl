target "claude-code" {
  context    = "."
  dockerfile = "docker/claude-code.dockerfile"
  tags       = ["df-claude-code"]
}
