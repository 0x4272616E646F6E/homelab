{
  description = "RSPS (Kronos) Server Build";

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
          rspsImage = n2c.buildImage {
            name = "rsps";
            config = {
              Cmd = [ "/bin/sh" "-c" "java -Xmx2G -jar kronos-server.jar" ];
              WorkingDir = "/app";
            };
            
            copyToRoot = pkgs.buildEnv {
              name = "root";
              paths = [
                pkgs.openjdk17
                pkgs.bash
                (pkgs.writeTextDir "/app/server.properties" ''
                  # Server configuration
                  server.port=43594
                  # Add other required configuration here
                '')
              ];
            };
            
            copyToRoot = pkgs.buildEnv {
              name = "rsps-files";
              paths = [
                # Copy the application files from the repo
                (pkgs.runCommand "app-files" {} ''
                  mkdir -p $out/app
                  cp -r ${./Kronos-master}/* $out/app/
                  # Build the server using gradle
                  cd $out/app
                  ./gradlew build
                '')
              ];
            };
          };
        };
      }
    );
}
