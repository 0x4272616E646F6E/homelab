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

          # prefer 'packages' over deprecated 'buildInputs' for devShells
          packages = with pkgs; [
            # Shell + framework
            zsh
            oh-my-zsh
            zsh-autocomplete
            zsh-autosuggestions
            zsh-syntax-highlighting

            # Core packages
            age
            curl
            git
            jq
            nushell
            vim
            wget
            yq-go

            # Homelab packages
            ansible
            fluxcd
            kubeconform
            kubectl
            kustomize
            opentofu
            sops
            talosctl
            terragrunt
          ];

          shellHook = ''
            echo "Homelab Dev Environment 🚀"
            export KUBECONFIG=$PWD/kubeconfig

            export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
            export ZDOTDIR="$PWD/.dev-zsh"     # keep zsh files local to the project
            mkdir -p "$ZDOTDIR"

            if [ ! -f "$ZDOTDIR/.zshrc" ]; then
              cat > "$ZDOTDIR/.zshrc" <<'EOF'
# Project-local zshrc
export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
ZSH_THEME="robbyrussell"
plugins=(
  ansible
  fluxcd
  git
  kubectl
  opentofu
)
source "$ZSH/oh-my-zsh.sh"

autoload -Uz colors && colors
PROMPT='%F{blue}%n@%m%f %F{red}%~%f %# '
EOF
            fi

            # Start interactive zsh
            if [ -z "$ZSH_VERSION" ]; then
              exec ${pkgs.zsh}/bin/zsh -i
            fi
          '';
        };
      });
}