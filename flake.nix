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
        osString = if isDarwin then "macOS" else if isLinux then "Linux" else "Unknown OS";

        reportOS = pkgs.writeShellScriptBin "report-os" ''
          echo "Hello from ${osString}!"
          echo "Nix-detected system: ${system}"
        '';

        linuxDevShell = pkgs.mkShell {
          buildInputs = [ reportOS ];
          shellHook = ''
            ${reportOS}/bin/report-os
            echo "This is a Linux-specific message."
          '';
        };

        darwinDevShell = pkgs.mkShell {
          buildInputs = [ reportOS ];
          shellHook = ''
            ${reportOS}/bin/report-os
            echo "This is a macOS-specific message."
          '';
        };

      in {
        devShell = if isLinux then linuxDevShell else darwinDevShell;
      });
}