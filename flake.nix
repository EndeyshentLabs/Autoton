{
  description = "Basic love2d dev flake.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [ love rlwrap luajit ];

      shellHook = ''
        alias love="rlwrap love"
      '';
    };
  };
}
