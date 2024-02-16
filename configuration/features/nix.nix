_:
{
  # Enabling Flake
  nix.settings.experimental-features = [ "nix-command" "flakes" "ca-derivations" ];

  # Substituters
  nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];

  # Store Optimise
  nix.settings.auto-optimise-store = true;
}