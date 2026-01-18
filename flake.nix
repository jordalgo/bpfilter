{
  description = "bpfilter - eBPF-based packet filtering framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        # Python packages for documentation and testing
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          breathe
          sphinx
          furo
          python-dateutil
          gitpython
          scapy
        ]);

      in {
        devShells.default = pkgs.mkShell {
          name = "bpfilter-dev";

          nativeBuildInputs = with pkgs; [
            # Build system
            cmake
            gnumake
            pkg-config

            # Compilers
            clang
            clang-tools  # clang-tidy, clang-format
            gcc

            # Parser generators
            bison
            flex

            # Autotools (for some dependencies)
            autoconf
            automake
            libtool

            # Version control
            git
          ];

          buildInputs = with pkgs; [
            # Core libraries
            libbpf
            libnl
            libgit2

            # Testing
            cmocka
            gbenchmark

            # BPF tools
            bpftools

            # Networking tools (for e2e tests)
            iproute2
            iputils

            # Utilities
            gawk
            jq
            gnused
            xxd
            procps
            lcov

            # Documentation
            doxygen
            pythonEnv
          ];

          shellHook = ''
            echo "bpfilter development environment"
            echo "  Build: cmake -S . -B build && make -C build"
            echo "  Test:  make -C build test"
            echo "  Docs:  make -C build doc"
          '';
        };
      }
    );
}
