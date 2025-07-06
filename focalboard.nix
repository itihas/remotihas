localFlake:

{ lib, config, self, inputs, ... }:

{
  perSystem = { config, self', pkgs, ... }:
    let version = "8.0.0";
    in {
      packages = {
        focalboard-src = pkgs.fetchFromGitHub {
          repo = "focalboard";
          owner = "mattermost-community";
          rev = "v${version}";
          hash = "sha256-b7iEcVhkV+Nt+S+KcmhVocr6RC0PMlRnPcpintzM69k=";
        };
        focalboard-npm-package = pkgs.buildNpmPackage (final: {
          pname = "focalboard";
          inherit version;
          src = "${self'.packages.focalboard-src}/webapp";
          npmDepsHash = "sha256-uJvXyoYthE9eShfBYjJt9FMVtEYE9NBdAxu6pLvuI0s=";
          makeCacheWritable = true;
          npmFlags = [ "--ignore-scripts" ];
          npmBuildScript = "pack";
        });

        focalboard-server = pkgs.stdenv.mkDerivation {
          name = "focalboard-server";
          inherit version;
          src = self'.packages.focalboard-src;
          buildInputs = with pkgs; [
            go
            git
            self'.packages.focalboard-npm-package
            gtk3.dev
            webkitgtk_4_0.dev
          ];
          BUILD_TAGS = "json1 sqlite3";
          
          buildPhase = "make server-linux";
        };
      };
    };
}
