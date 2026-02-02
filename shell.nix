{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.python313
    pkgs.python313Packages.pyyaml
    pkgs.python313Packages.feedgen
    pkgs.python313Packages.markdown
    pkgs.ruff
  ];
}
