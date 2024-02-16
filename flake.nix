{
  description = "ChaosAttractor's Router Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { nixpkgs, deploy-rs, ... } @ inputs : 
  let
    network.interface = {
      lan = "enp6s18";
      wan = "enp6s19";
      ppp = "pppoe-wan";
    };
  in rec {
    # Router@PVE2.home.lostattractor.net
    nixosConfigurations."router" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit network; };
      modules = [
        ./hardware/kvm
        ./configuration
        { networking.hostName = "router"; }
        inputs.sops-nix.nixosModules.sops
      ];
    };

    # Deploy-RS Configuration
    deploy = {
      sshUser = "root";
      magicRollback = false;

      nodes."router@pve2.home.lostattractor.net" = {
        hostname = "192.168.8.1"; # router.home.lostattractor.net
        profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations."router";
      };
    };

    # This is highly advised, and will prevent many possible mistakes
    checks = builtins.mapAttrs (_system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;

    hydraJobs = {
      nixosConfigurations = nixpkgs.lib.mapAttrs' (name: config:
        nixpkgs.lib.nameValuePair name config.config.system.build.toplevel)
        nixosConfigurations;
    };
  };
}
