# copier-flake

Copier binary with [jinja2-git-dir](https://github.com/gordon-code/jinja2-git-dir) extension, packaged as a Nix flake.

## Usage

### As a flake input
```nix
{
  inputs.copier-flake.url = "github:gordon-code/copier-flake";
  # Then use: copier-flake.packages.${system}.copier
}
```

### Direct run
```shell
nix run github:gordon-code/copier-flake -- <copier-args>
```
