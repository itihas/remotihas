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

        focalboard-server = pkgs.buildGoModule {
          name = "focalboard-server";
          inherit version;
          src = "${self'.packages.focalboard-src}";
          vendorHash = "sha256-uw4/n42SE0s/DFOP/8tkSnrw+H4pUJrZqQwx88/ennI=";
          buildInputs = [ pkgs.sqlite self'.packages.focalboard-npm-package ];
          modRoot = "./server";
          ldflags = [
            "-X github.com/mattermost/focalboard/server/model.BuildNumber=dev"
            "-X github.com/mattermost/focalboard/server/model.BuildDate=1970-01-01"
            "-X github.com/mattermost/focalboard/server/model.BuildHash=nix-build"
            "-X github.com/mattermost/focalboard/server/model.Edition=linux"
          ];

          tags = [ "json1" "sqlite3" ];
          buildPhase = ''
            runHook preBuild

            # Build server
            cd server
            go build -tags "json1 sqlite3" -o focalboard-server ./main

            runHook postBuild
          '';
          doCheck = false;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            ls -R
            chmod +x focalboard-server
            cp focalboard-server $out/bin/

            cp app-config.json $out/share/focalboard/config.json
            cp NOTICE.txt $out/share/focalboard/
            cp webapp/NOTICE.txt $out/share/focalboard/webapp-NOTICE.txt

            runHook postInstall
          '';
        };

        focalboard-app = pkgs.buildGoModule {
          name = "focalboard-app";
          inherit version;
          src = "${self'.packages.focalboard-src}";
          vendorHash = "sha256-0Nn101c9DSGuqCdAD38L5POSqNruH+Igs9WCZWjfrDU=";
          buildInputs = [ pkgs.sqlite ];
          nativeBuildInputs = [ pkgs.pkg-config pkgs.webkitgtk_4_0 pkgs.gtk3 ];
          modRoot = "./linux";
          tags = [ "json1" "sqlite3" ];

          doCheck = false;
        };
      };
    };
}
