{
  description = "A flake that reports the OS using separate scripts with optional CUDA support and unfree packages allowed.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Import nixpkgs with allowUnfree enabled
        pkgs = import nixpkgs {
          system = system;
          config = {
            allowUnfree = true;  # Allow unfree packages like CUDA
          };
        };

        isDarwin = pkgs.stdenv.isDarwin;
        isLinux = pkgs.stdenv.isLinux;

        # Define common packages used across all platforms
        commonPackages = with pkgs; [
          python311
          python311.pkgs.pip
          python311.pkgs.virtualenv
          figlet
          tmux
          zlib
          git
        ] ++ (with pkgs; pkgs.lib.optionals isLinux [
          gcc
          stdenv.cc.cc.lib
        ]);

        # Define optional CUDA packages for Linux
        cudaPackages = with pkgs; [
          cudatoolkit
          cudnn
          nccl
        ];

        # Create a common shell script to run on both Linux and macOS
        runScript = pkgs.writeShellScriptBin "run-script" ''
          #!/usr/bin/env bash
          # Activate the virtual environment
          source .venv/bin/activate

          # Use the Proper case repo name in the figlet output
          REPO_NAME=$(basename "$PWD")
          PROPER_REPO_NAME=$(echo "$REPO_NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
          figlet "$PROPER_REPO_NAME"
          echo "Welcome to the $PROPER_REPO_NAME development environment on ${system}!"
          echo 
          # Install packages from requirements.txt
          echo "- Installing pip packages..."
          if pip install --upgrade pip --quiet && \
            pip install -r requirements.txt --quiet; then
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

          # Create the start script
          cat << EOF > .venv/bin/start
          #!/bin/sh
          stop
          echo "Starting JupyterLab..."
          tmux new-session -d -s jupyter 'source .venv/bin/activate && jupyter lab'
          echo "JupyterLab started."
          echo "To view JupyterLab server: tmux attach -t jupyter"
          echo "To stop JupyterLab server: stop"
          EOF
          chmod +x .venv/bin/start

          # Create the stop script
          cat << EOF > .venv/bin/stop
          #!/bin/sh
          echo "Stopping tmuxs..."
          tmux kill-server 2>/dev/null || echo "No tmux session is running."
          echo "All tmux sessions have been stopped."
          EOF
          chmod +x .venv/bin/stop

        '';

        linuxDevShell = pkgs.mkShell {
          buildInputs = commonPackages ++ (with pkgs; pkgs.lib.optionals (builtins.pathExists "/usr/bin/nvidia-smi") cudaPackages);  # Add CUDA packages if nvidia-smi exists
          shellHook = ''
            # Create the Python virtual environment
            test -d .venv || ${pkgs.python311}/bin/python -m venv .venv
            export VIRTUAL_ENV="$(pwd)/.venv"
            export PATH="$VIRTUAL_ENV/bin:$PATH"
            export PS1='$(printf "\033[01;34m(nix) \033[00m\033[01;32m[%s@%s:%s]$\033[00m " "\u" "\h" "\w")'
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath commonPackages}:$LD_LIBRARY_PATH

            # Optional CUDA support
            if command -v nvidia-smi &> /dev/null; then
              echo "CUDA hardware detected."
              export CUDA_HOME=${pkgs.cudatoolkit}
              export PATH=$CUDA_HOME/bin:$PATH
              export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
            else
              echo "No CUDA hardware detected."
            fi

            # Run the common runScript
            ${runScript}/bin/run-script  # Ensure to call the script correctly
          '';
        };

        darwinDevShell = pkgs.mkShell {
          buildInputs = commonPackages;  # Added commonPackages for macOS
          shellHook = ''
            # Create the Python virtual environment
            test -d .venv || ${pkgs.python311}/bin/python -m venv .venv
            export VIRTUAL_ENV="$(pwd)/.venv"
            export PATH="$VIRTUAL_ENV/bin:$PATH"
            export PS1='$(printf "\033[01;34m(nix) \033[00m\033[01;32m[%s@%s:%s]$\033[00m " "\u" "\h" "\w")'
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath commonPackages}:$LD_LIBRARY_PATH

            # Run the common runScript
            ${runScript}/bin/run-script  # Ensure to call the script correctly
          '';
        };

      in {
        devShell = if isLinux then linuxDevShell else darwinDevShell;  # Ensure multi-OS support
      });
}