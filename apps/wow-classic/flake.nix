{
  description = "WoW Classic Server Build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix2container.url = "github:nlewo/nix2container";
  };

  outputs = { self, nixpkgs, flake-utils, nix2container }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        n2c = nix2container.packages.${system}.nix2container;
      in
      {
        packages = {
          wowClassicImage = n2c.buildImage {
            name = "wow-classic";
            config = {
              Cmd = [ "/bin/sh" "-c" "/app/bin/start.sh" ];
              WorkingDir = "/app";
              ExposedPorts = {
                "8085/tcp" = {};  # World server port
                "3724/tcp" = {};  # Auth server port
              };
            };
            
            copyToRoot = pkgs.buildEnv {
              name = "root";
              paths = [
                pkgs.gcc
                pkgs.cmake
                pkgs.mariadb
                pkgs.openssl
                pkgs.zlib
                pkgs.bash
                (pkgs.writeTextDir "/app/bin/start.sh" ''
                  #!/bin/bash
                  set -e
                  
                  # Start the WoW Classic server
                  cd /app/bin
                  ./worldserver
                '')
              ];
            };
            
            copyToRoot = pkgs.buildEnv {
              name = "wow-classic-files";
              paths = [
                # Copy the application files and build
                (pkgs.runCommand "app-files" {} ''
                  mkdir -p $out/app
                  cp -r ${./server}/* $out/app/
                  
                  # Build the server
                  cd $out/app
                  mkdir -p build
                  cd build
                  cmake ..
                  make -j$(nproc)
                  
                  # Create necessary directories
                  mkdir -p $out/app/bin
                  cp bin/* $out/app/bin/
                  chmod +x $out/app/bin/start.sh
                '')
              ];
            };
          };
        };
      }
    );
}
