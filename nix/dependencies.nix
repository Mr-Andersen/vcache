inputs:
ghcVersion:
final: prev:
with builtins; mapAttrs (_: v:
                          if isAttrs v && hasAttr "isHaskellLibrary" v
                            then v.overrideAttrs (_: {
                              doCheck = false;
                              doBenchmark = false;
                              doHaddock = false;
                              doHoogle = false;
                            })
                            else v) prev //
{}
