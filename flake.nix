{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/22.05;
    utils.url = github:numtide/flake-utils;
  };

  outputs = inputs@{ nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem (system:
      let nixpkgs' = import nixpkgs {
            inherit system;
          };
          unwords = nixpkgs'.lib.concatStringsSep " ";
          options = [
            "-Wall"
            "-Wcompat"
            "-Wincomplete-uni-patterns"
            "-Wredundant-constraints"
            # "-Wmissing-export-lists"
            "-Wincomplete-record-updates"
            "-Wmissing-deriving-strategies"
          ];
          this = ghcVersion:
            let pkgs = nixpkgs'.haskell.packages.${ghcVersion}.override {
                  overrides = (import ./nix/dependencies.nix inputs ghcVersion);
                };
                vcache = pkgs.mkDerivation {
                  pname = "vcache";
                  version = "0.2.6";
                  src = ./.;
                  isExecutable = true;
                  executableHaskellDepends = with pkgs; [
                    direct-murmur-hash
                    bytestring
                    transformers
                    containers
                    stm
                    lmdb
                    filelock
                    easy-file
                    random
                  ];
                  license = nixpkgs.lib.licenses.gpl3Plus;
                  passthru = { inherit pkgs; };
                };
                ghcWithPackages = nixpkgs'.lib.removeSuffix "\n" (builtins.readFile vcache.env);
                ghci = nixpkgs'.writeScript "ghci"
                  ''
                  set -x
                  ${ghcWithPackages}/bin/ghci ${unwords options} $(find . -name '*.hs')
                  '';
             in { inherit vcache ghci; };

          thisNative = this "ghc922";
       in
      {
        packages.default = thisNative.vcache;

        apps =
          let binaryToApp = bin: { type = "app"; program = "${bin}/bin/${bin.pname}"; };
           in
          {
            default = binaryToApp thisNative.vcache;
            ghci = {
              type = "app";
              program = thisNative.ghci.outPath;
            };
          };

        devShells = {
          default = thisNative.vcache.env;
        };
      });
}
