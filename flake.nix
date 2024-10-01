{
  description = "A flake that reports the OS using separate scripts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        isDarwin = pkgs.stdenv.isDarwin;
        isLinux = pkgs.stdenv.isLinux;

        # Define common packages used across all platforms
        commonPackages = with pkgs; [
          python311
          python311.pkgs.pip
          python311.pkgs.virtualenv
          cmake
          ninja
          git
          zlib
          figlet
          tmux
        ] ++ (with pkgs; pkgs.lib.optionals isLinux [
          gcc
          stdenv.cc.cc.lib
        ]);

        reportOS = pkgs.writeShellScriptBin "report-os" ''
          echo "Hello from ${if isDarwin then "macOS" else "Linux"}!"
          echo "Nix-detected system: ${system}"
        '';

        linuxDevShell = pkgs.mkShell {
          buildInputs = commonPackages ++ [ reportOS ];  # Added commonPackages
          shellHook = ''
            # Create the Python virtual environment
            test -d .venv || ${pkgs.python311.interpreter} -m venv .venv
            export VIRTUAL_ENV="$(pwd)/.venv"
            export PATH="$VIRTUAL_ENV/bin:$PATH"
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath commonPackages}:$LD_LIBRARY_PATH"  # Ensure libraries are available
            export PS1='$(printf "\033[01;34m(nix:nix-shell-env) \033[00m\033[01;32m[%s@%s:%s]$\033[00m " "\u" "\h" "\w")'
            ${reportOS}/bin/report-os
            echo "This is a Linux-specific message."
          '';
        };

        darwinDevShell = pkgs.mkShell {
          buildInputs = commonPackages;  # Added commonPackages
          shellHook = ''
            # Create the Python virtual environment
            test -d .venv || ${pkgs.python311.interpreter} -m venv .venv
            export VIRTUAL_ENV="$(pwd)/.venv"
            export PATH="$VIRTUAL_ENV/bin:$PATH"
            export PS1='$(printf "\033[01;34m(nix:nix-shell-env) \033[00m\033[01;32m[%s@%s:%s]$\033[00m " "\u" "\h" "\w")'
            ${reportOS}/bin/report-os
            echo "This is a macOS-specific message."
          '';
        };

      in {
        devShell = if isDarwin then darwinDevShell else linuxDevShell;  # Ensure multi-OS support
      });
}
