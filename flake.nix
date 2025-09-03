{
  description = "Homelab Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; # stable channel
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        devShells.default = pkgs.mkShell {
          name = "homelab";
          NIX_SHELL_PRESERVE_PROMPT = 1;

          buildInputs = with pkgs; [
            # Core packages
            curl
            git
            vim
            wget

            # Homelab packages
            nodePackages_latest.cdk8s-cli
            fluxcd
            kubectl
            kustomize
            openjdk21
            maven
            sops
            talosctl
          ];

          shellHook = ''
            echo "Homelab Dev Environment 🚀"
            export KUBECONFIG=$PWD/kubeconfig
            export JAVA_HOME=${pkgs.openjdk21}/lib/openjdk
          '';
        };
      });
}