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

        # Create a clang-bpf wrapper: unwrapped clang (no hardening flags) with libbpf headers
        clangBpf = pkgs.writeShellScriptBin "clang-bpf" ''
          exec ${pkgs.llvmPackages.clang-unwrapped}/bin/clang -I${pkgs.libbpf}/include "$@"
        '';

      in {
        devShells.default = pkgs.mkShell {
          name = "bpfilter-dev";

          nativeBuildInputs = with pkgs; [
            # Build system
            cmake
            ninja
            gnumake
            pkg-config

            # Compilers
            clang
            clang-tools  # clang-tidy, clang-format
            include-what-you-use
            gcc

            # BPF-compatible clang (unwrapped, no hardening flags)
            clangBpf

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

            # Transitive dependencies (for pkg-config)
            elfutils  # libelf, required by libbpf
            openssl   # required by libgit2
            zlib      # commonly required
            zstd      # libzstd, required by libelf
            pcre2     # libpcre2-8, required by libgit2

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
            # Add libbpf headers to include path for clang-tidy
            export CPATH="${pkgs.libbpf}/include''${CPATH:+:$CPATH}"

            echo "bpfilter development environment"
            echo ""
            echo "Configure with BPF-compatible clang:"
            echo "  cmake -GNinja -DCLANG_BIN=$(which clang-bpf) .."
            echo ""
            echo "Build:  ninja"
            echo "Test:   ninja test"
            echo "Docs:   ninja doc"
          '';
        };
      }
    );
}
