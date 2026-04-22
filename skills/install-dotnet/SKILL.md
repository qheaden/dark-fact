---
name: install-dotnet
description: Use this skill when you want to install the .NET SDK for building apps with C# or F#
---

Before attempting to install .NET, please run `dotnet --version` and verify the binary is not found. If you get a valid version returned, let the user know .NET is already installed and stop.

If you verified .NET is not installed, follow these steps to install it.

1) Run `curl -L https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh --channel 10.0`
2) Run `sudo apt-get update && sudo apt-get install -y libicu74`
3) Add `export PATH="$HOME/.dotnet:$PATH"` to `.bashrc`
4) Run `source .bashrc` to make the PATH update immediately available
5) Run `dotnet --version` and verify it returns version number
6) Let the user know .NET has been installed and which version was installed
