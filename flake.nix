{
  description = "A robust flake that reports the OS for both macOS and Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Detect OS
        isDarwin = pkgs.stdenv.isDarwin;
        isLinux = pkgs.stdenv.isLinux;
        
        # Determine OS string
        osString = if isDarwin then "macOS" else if isLinux then "Linux" else "Unknown OS";
        
        # Script that reports the OS
        reportOS = pkgs.writeScriptBin "report-os" ''
          #!${pkgs.bash}/bin/bash
          set -e

          echo "Attempting to detect OS..."
          
          if [ "$(uname)" = "Darwin" ]; then
            echo "Current OS: macOS (detected by uname)"
          elif [ "$(uname)" = "Linux" ]; then
            echo "Current OS: Linux (detected by uname)"
          else
            echo "Current OS: Unknown (uname reports: $(uname))"
          fi
          
          echo "Nix-detected system: ${system}"
          echo "isDarwin: ${toString isDarwin}"
          echo "isLinux: ${toString isLinux}"
          echo "osString: ${osString}"
          
          echo "Script execution completed successfully."
        '';

        # Platform-specific packages
        platformSpecificPackages = if isDarwin then [
          pkgs.darwin.apple_sdk.frameworks.CoreFoundation
        ] else if isLinux then [
          pkgs.libGL
        ] else [];

      in
      {
        packages = {
          default = reportOS;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = reportOS;
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = [
            reportOS
            pkgs.bash  # Explicitly include bash
          ] ++ platformSpecificPackages;
          
          shellHook = ''
            ${reportOS}/bin/report-os || echo "Error: Failed to execute report-os script"
          '';
        };
      });
}
