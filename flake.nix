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
          packages.default =
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
              nativeBuildInputs = with pkgs; [
                dioxus-cli
                rustToolchain
              ];
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
