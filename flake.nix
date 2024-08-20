{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    esp-dev-rust = {
      url = "github:shymega/esp32-dev.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { ... }@inputs:
    let
      system = "x86_64-linux";
      overlays = [
        inputs.fenix.overlays.default
        inputs.esp-dev-rust.overlays.default
      ];

      pkgs = import inputs.nixpkgs {
        inherit system overlays;
      };
      rustToolchain = with inputs.fenix.packages.${system}; combine [
        pkgs.rust-esp
        pkgs.rust-src-esp
      ];
    in
    {
      inherit (inputs) self;
      inherit pkgs;

      devShells.${system}.default = pkgs.mkShellNoCC {
        buildInputs = with pkgs; [
          cargo-binutils
          cargo-espflash
          cargo-espmonitor
          cargo-leptos
          cargo-sort
          clang
          esp-idf-esp32
          espflash
          git
          gnumake
          just
          ldproxy
          llvmPackages_17.bintools
          pkg-config
          platformio
          probe-rs
          rustToolchain
          rustup
          wget
        ];
        shellHook = ''
          unset IDF_PATH
          unset IDF_TOOLS_PATH
          unset IDF_PYTHON_CHECK_CONSTRAINTS
          unset IDF_PYTHON_ENV_PATH
          export PLATFORMIO_CORE_DIR=$PWD/.platformio

          # NOTE: this is installed by nixpkgs-esp-dev, but not given as part
          # of the available packages and thus being able to be referenced.
          export CLANG_PATH="$(dirname $(which clang))"
          export LIBCLANG_PATH="$CLANG_PATH/../lib"
          export LIBCLANG_BIN_PATH="$CLANG_PATH/../lib"

          rustup toolchain link esp ${pkgs.rust-esp}
          export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
        '';
      };
    };
}
