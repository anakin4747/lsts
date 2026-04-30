{
  description = "Language Server Test Suite – bats-based LSP testing library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    kconfig-language-server.url = "github:anakin4747/kconfig-language-server";
    kconfig-language-server.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, kconfig-language-server }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        kls = kconfig-language-server.packages.${system}.default;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "lsts";

          packages = with pkgs; [
            bash
            bats
            cocogitto
            jq
            shellcheck
            kls
            go
            gopls
            lua-language-server
            pyright
            bash-language-server
            nil
            typescript
            typescript-language-server
            sonar-scanner-cli
          ];

          env.SONAR_SCANNER_OPTS = "-Dsonar.scanner.skipJreProvisioning=true";
        };
      });
}
