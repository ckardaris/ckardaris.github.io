{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        IMAGE = "localhost/ckardaris.github.io";
        buildInputs = with pkgs; [
          python313
          python313Packages.pyyaml
          python313Packages.feedgen
          python313Packages.markdown
          ruff
        ];
      };
    };
}
