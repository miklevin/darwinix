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
          git
          zlib
          figlet
          tmux
        ] ++ (with pkgs; pkgs.lib.optionals isLinux [
          gcc
          stdenv.cc.cc.lib
        ]);

        runScript = pkgs.writeShellScriptBin "run-script" ''
          #!/usr/bin/env bash
          # Activate the virtual environment
          source .venv/bin/activate

          # Use the Proper case repo name in the figlet output
          REPO_NAME=$(basename "$PWD")
          PROPER_REPO_NAME=$(echo "$REPO_NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
          echo "Welcome to the $PROPER_REPO_NAME development environment on ${system}!"
          figlet "$PROPER_REPO_NAME"
          
          # Install packages from requirements.txt
          echo "- Checking if numpy is importable..."
          if pip install -r requirements.txt; then
              package_count=$(pip list --format=freeze | wc -l)
              echo "- Done. $package_count pip packages installed."
          else
              echo "Warning: An error occurred during pip setup."
          fi
          if python -c "import numpy" 2>/dev/null; then
            echo "- numpy is importable (good to go!)"
          else
            echo "Error: numpy could not be imported. Check your installation."
          fi


        '';

        linuxDevShell = pkgs.mkShell {
          buildInputs = commonPackages;  # Added commonPackages
          shellHook = ''
            # Create the Python virtual environment
            test -d .venv || ${pkgs.python311}/bin/python -m venv .venv
            export VIRTUAL_ENV="$(pwd)/.venv"
            export PATH="$VIRTUAL_ENV/bin:$PATH"
            export PS1='$(printf "\033[01;34m(nix) \033[00m\033[01;32m[%s@%s:%s]$\033[00m " "\u" "\h" "\w")'
            # Run the common runScript
            ${runScript}/bin/run-script  # Ensure to call the script correctly
          '';
        };

        darwinDevShell = pkgs.mkShell {
          buildInputs = commonPackages;  # Added commonPackages
          shellHook = ''
            # Create the Python virtual environment
            test -d .venv || ${pkgs.python311}/bin/python -m venv .venv
            export VIRTUAL_ENV="$(pwd)/.venv"
            export PATH="$VIRTUAL_ENV/bin:$PATH"
            export PS1='$(printf "\033[01;34m(nix) \033[00m\033[01;32m[%s@%s:%s]$\033[00m " "\u" "\h" "\w")'
            # Run the common runScript
            ${runScript}/bin/run-script  # Ensure to call the script correctly
          '';
        };

      in {
        devShell = if isLinux then linuxDevShell else darwinDevShell;  # Ensure multi-OS support
      });
}
