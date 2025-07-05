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
        focalboard-npm-deps = pkgs.importNpmLock {
          npmRoot = "${self'.packages.focalboard-src}/webapp";
          inherit version;
          packageSourceOverrides = {
            "node_modules/eslint-plugin-mattermost" = pkgs.fetchFromGitHub {
              owner = "mattermost";
              repo = "eslint-plugin-mattermost";
              rev = "5b0c972eacf19286e4c66221b39113bf8728a99e";
              hash = "sha256-JMWqcHaoequGXp8Z+k5KmXEMyteEROgKo94MX3MSOLE=";
            };
          };
        };
        focalboard-npm-package = pkgs.buildNpmPackage (final: {
          pname = "focalboard";
          inherit version;
          src = "${self'.packages.focalboard-src}/webapp";
          npmDeps = self'.packages.focalboard-npm-deps;
          npmConfigHook = pkgs.importNpmLock.npmConfigHook;
          configurePhase = ''
            mkdir node_modules
            ln -s ${pkgs.cypress} ./node_modules/cypress || ls -lah node_modules/cypress
          '';
          makeCacheWriteable = true;
          buildPhase = ''
          npm pack
          ls -R
          '';
          # dontNpmBuild = true;
          npmFlags = [ "--loglevel=verbose" ];
        });

        focalboard-server = pkgs.stdenv.mkDerivation {
          name = "focalboard-server";
          inherit version;
          src = self'.packages.focalboard-src;
          buildInputs = with pkgs; [
            go
            self'.focalboard-npm-package
            gtk3.dev
            webkitgtk_4_0.dev
          ];
          # buildPhase = ''
          #   make prebuild
          #   make
          # '';
        };
      };
    };
}
