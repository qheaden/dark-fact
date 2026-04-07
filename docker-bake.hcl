group "default" {
  targets = ["claude-code", "opencode", "codex"]
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

target "codex" {
  context    = "."
  dockerfile = "docker/codex.dockerfile"
  tags       = ["df-codex"]
}
