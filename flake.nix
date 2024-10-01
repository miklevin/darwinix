{
  description = "A flake that reports the OS using a single shell";

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
      in {
        devShell = pkgs.mkShell {
          buildInputs = [ pkgs.bash ];
          shellHook = ''
            echo "Hello from ${osString}!"
            echo "Nix-detected system: ${system}"
            if [ "${osString}" = "macOS" ]; then
              echo "This is a macOS-specific message."
            elif [ "${osString}" = "Linux" ]; then
              echo "This is a Linux-specific message."
            else
              echo "This is a message for an unknown OS."
            fi
          '';
        };
      });
}