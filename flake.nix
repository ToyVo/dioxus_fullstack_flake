{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    rust-overlay.url = "github:oxalica/rust-overlay";
    # crane.url = "github:ipetkov/crane";
    # crane.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem =
        {
          config,
          self',
          pkgs,
          lib,
          system,
          ...
        }:
        let
          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            extensions = [
              "rust-src"
              "rust-analyzer"
              "clippy"
            ];
            targets = [ "wasm32-unknown-unknown" ];
          };
          rustBuildInputs =
            [
              pkgs.openssl
              pkgs.libiconv
              pkgs.pkg-config
            ]
            ++ lib.optionals pkgs.stdenv.isLinux [
              pkgs.glib
              pkgs.gtk3
              pkgs.libsoup_3
              pkgs.webkitgtk_4_1
              pkgs.xdotool
            ]
            ++ lib.optionals pkgs.stdenv.isDarwin (
              with pkgs.darwin.apple_sdk.frameworks;
              [
                SystemConfiguration
                IOKit
                Carbon
                WebKit
                Security
                Cocoa
              ]
            );

        in
        # This is useful when building crates as packages
        # Note that it does require a `Cargo.lock` which this repo does not have
        # craneLib = (inputs.crane.mkLib pkgs).overrideToolchain rustToolchain;
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.rust-overlay.overlays.default
            ];
          };

          formatter = pkgs.nixfmt-rfc-style;
          packages = rec {
            wasm-bindgen-cli = pkgs.wasm-bindgen-cli.override {
              version = "0.2.99";
              hash = "sha256-1AN2E9t/lZhbXdVznhTcniy+7ZzlaEp/gwLEAucs6EA=";
              cargoHash = "sha256-DbwAh8RJtW38LJp+J9Ht8fAROK9OabaJ85D9C/Vkve4=";
            };
            dioxus-cli = pkgs.dioxus-cli.overrideAttrs (drv: rec {
              version = "0.6.1";
              src = pkgs.fetchCrate {
                inherit version;
                pname = drv.pname;
                hash = "sha256-mQnSduf8SHYyUs6gHfI+JAvpRxYQA1DiMlvNofImElU=";
              };
              cargoDeps = drv.cargoDeps.overrideAttrs (
                lib.const {
                  name = "${drv.cargoDeps.name}-vendor";
                  inherit src;
                  outputHash = "sha256-QiGnBoZV4GZb5MQ3K/PJxCfw0p/7qDmoE607hlGKOns=";
                }
              );
              postFixup =
                if pkgs.stdenv.isDarwin then
                  ''
                    mkdir -p "$out/home/Library/Application Support/dioxus/wasm-bindgen"
                    ln -s ${lib.getExe wasm-bindgen-cli} "$out/home/Library/Application Support/dioxus/wasm-bindgen/wasm-bindgen-${wasm-bindgen-cli.version}"
                    wrapProgram $out/bin/dx \
                      --set HOME $out/home
                  ''
                else
                  ''
                    mkdir -p $out/share/dioxus/wasm-bindgen
                    ln -s ${lib.getExe wasm-bindgen-cli} $out/share/dioxus/wasm-bindgen/wasm-bindgen-${wasm-bindgen-cli.version}
                    wrapProgram $out/bin/dx \
                      --set XDG_DATA_HOME $out/share
                  '';
              checkFlags = drv.checkFlags ++ [ "--skip=wasm_bindgen::test" ];
              nativeBuildInputs = drv.nativeBuildInputs ++ [ pkgs.makeBinaryWrapper ];
            });
            default =
              let
                cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
                rev = self'.shortRev or self'.dirtyShortRev or "dirty";
              in
              pkgs.rustPlatform.buildRustPackage {
                pname = cargoToml.package.name;
                version = "${cargoToml.package.version}-${rev}";
                src = ./.;
                strictDeps = true;
                buildInputs = rustBuildInputs;
                nativeBuildInputs = [
                  dioxus-cli
                  rustToolchain
                  pkgs.rustPlatform.bindgenHook
                ] ++ rustBuildInputs;
                buildPhase = ''
                  dx build --release --platform web
                '';
                installPhase = ''
                  mkdir -p $out
                  cp -r target/dx/$pname/release/web $out/bin
                '';
                cargoLock.lockFile = ./Cargo.lock;
                meta.mainProgram = "server";
              };
          };

          devShells.default = pkgs.mkShell {
            name = "dioxus-dev";
            buildInputs = rustBuildInputs;
            nativeBuildInputs = [
              # Add shell dependencies here
              rustToolchain
            ];
            shellHook = ''
              # For rust-analyzer 'hover' tooltips to work.
              export RUST_SRC_PATH="${rustToolchain}/lib/rustlib/src/rust/library";
            '';
          };
        };
    };
}
