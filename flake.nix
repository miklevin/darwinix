{
  description = "A flake that explicitly reports the OS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Detect OS
        isMacOS = pkgs.stdenv.isDarwin;
        isLinux = pkgs.stdenv.isLinux;
        
        # Determine OS string
        osString = if isMacOS then "macOS" else if isLinux then "Linux" else "Unknown OS";
        
        # Set up conditional package selection
        defaultShell = if isMacOS then pkgs.zsh else pkgs.bash;
        
        # Script that reports the OS
        reportOS = pkgs.writeScriptBin "report-os" ''
          #!${defaultShell}/bin/sh
          echo "Current OS: ${osString}"
          echo "Nix-detected system: ${system}"
          echo "isMacOS: ${toString isMacOS}"
          echo "isLinux: ${toString isLinux}"
        '';

        # Platform-specific packages
        platformSpecificPackages = if isMacOS then [
          pkgs.darwin.apple_sdk.frameworks.CoreFoundation
        ] else if isLinux then [
          pkgs.libGL
        ] else [];

      in
      {
        packages = {
          default = reportOS;
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/report-os";
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = [
            reportOS
          ] ++ platformSpecificPackages;
          
          shellHook = ''
            ${reportOS}/bin/report-os
          '';
        };
      });
}