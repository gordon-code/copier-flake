{
  description = "Copier binary with jinja2-git-dir extension";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    rec {
      devShells = forEachSupportedSystem (
        {
          pkgs,
          system,
          ...
        }:
        {
          default = pkgs.mkShell {
            packages = [
              packages.${system}.copier
              pkgs.git
            ];
          };
        }
      );

      packages = forEachSupportedSystem (
        {
          pkgs,
          system,
          ...
        }:
        {
          copier = pkgs.writeShellApplication {
            name = "copier";
            runtimeInputs = [
              pkgs.git
              # Override upstream to use latest version and include additional extensions
              # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/co/copier/package.nix
              (pkgs.copier.overridePythonAttrs (old: rec {
                version = "9.13.1";
                src = pkgs.fetchFromGitHub {
                  owner = "copier-org";
                  repo = "copier";
                  tag = "v${version}";
                  # Conflict on APFS on darwin
                  postFetch = ''
                    rm $out/tests/demo/doc/ma*ana.txt
                  '';
                  hash = "sha256-2ejDj9qAdziAaXmgl6eJGEznhceYYKnFBcHznuHZrGQ=";
                };
                dependencies = old.dependencies ++ [
                  packages.${system}.gitDirExtension
                  pkgs.python3.pkgs.hatchling
                  pkgs.python3.pkgs.hatch-vcs
                ];
              }))
            ];
            text = ''copier "$@"'';
          };

          gitDirExtension = pkgs.python3Packages.buildPythonPackage rec {
            pname = "jinja2-git-dir";
            version = "0.5.0";
            pyproject = true;
            disabled = pkgs.python3Packages.pythonOlder "3.9";
            src = pkgs.fetchFromGitHub {
              owner = "gordon-code";
              repo = "jinja2-git-dir";
              tag = "v${version}";
              hash = "sha256-YYdwZ0Hypd2fihpsQ6gPht6vHqcpeYP41TahC9jgxzQ=";
            };
            build-system = [
              pkgs.python3Packages.hatchling
              pkgs.python3Packages.hatch-vcs
            ];
            dependencies = [ pkgs.python3Packages.jinja2 ];
            doCheck = false;
            pythonImportsCheck = [ "jinja2_git_dir" ];
          };
        }
      );

      apps = forEachSupportedSystem (
        {
          system,
          ...
        }:
        {
          default = {
            meta.description = "Copier binary for creating project templates";
            type = "app";
            program = "${packages.${system}.copier}/bin/copier";
          };
        }
      );

      formatter = forEachSupportedSystem (
        {
          pkgs,
          ...
        }:
        pkgs.nixfmt-rfc-style
      );
    };
}
