{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Development tools
    nodejs
    python3
    virtualenv
    jdk
    claude-code

    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer

    gcc
    gnumake
    cmake
    pkg-config
    gdb
  ];

  environment.sessionVariables.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
}
