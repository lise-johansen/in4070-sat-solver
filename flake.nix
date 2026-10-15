{
  description = "IN4070 Oblig 3: DPLL SAT solver in Haskell";

  inputs =
  {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-26.05" ;
    flake-utils.url = "github:numtide/flake-utils"       ;
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          manager  = import nixpkgs { inherit system; }               ;
          haskell  = manager.haskellPackages                          ;
          solver   = haskell.callCabal2nix "sat-solver" ./. { }       ;
        in
        {
          # nix build / nix run
          packages.default = solver ;
          apps.default     = flake-utils.lib.mkApp { drv = solver; } ;

          # nix develop: ghc with the project's dependencies, cabal, hls, hlint
          devShells.default = haskell.shellFor
          { packages    = _: [ solver ];
            withHoogle  = false;
            nativeBuildInputs =
            [ manager.cabal-install
              haskell.haskell-language-server
              haskell.hlint
            ];
          };
        }
      );
}
