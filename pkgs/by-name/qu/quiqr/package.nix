{
  lib,
  callPackage,
  fetchFromGitHub,
  buildGoModule,
}:

let
  embgit = buildGoModule rec {
    name = "embgit";
    version = "0.6.4";

    src = fetchFromGitHub {
      owner = "quiqr";
      repo = "embgit";
      tag = "${version}";
      sha256 = "sha256-0eEBKhJIcKGoW8Nd1/L4849Ew99GAKoRh3otuVw4P3o=";
    };

    vendorHash = "sha256-e0CXBakEXyWOPOmw1ORHUmWfHCcWkNGR0dwtdNXG9Xo=";

    postInstall = ''
      cp "$out/bin/src" "$out/bin/embgit"
    '';

    meta = with lib; {
      description = "Embedded Git for electron apps";
      homepage = "https://github.com/quiqr/embgit";
      license = licenses.mit;
    };
  };

  version = "0.21.5";

  #src = fetchFromGitHub {
  #  owner = "quiqr";
  #  repo = "quiqr-desktop";
  #  tag = "v${finalAttrs.version}";
  #  hash = "sha256-M0UxttYzy4rpR17QgGe/hpXx2iBKx9I22XmPTOQ9epQ=";
  #};

  src = fetchFromGitHub {
    owner = "mipmip";
    repo = "quiqr-desktop";
    rev = "ae88dedef0b7617a9541d49091cff4f04f7d3849";
    hash = "sha256-/YzXy9yojScoMbnAHkXvcgtU9MZU4C8ifzeOh+slcXw=";
  };

  npmDepsHash = "sha256-a+XPKouW4ogz+tMQiTla+hQNhz+rsH4w2hZrmlfLi04=";

in

## inspired by pingvin-share
lib.recurseIntoAttrs {
  desktop = callPackage ./desktop.nix {
    inherit
      src
      version
      embgit
      npmDepsHash
      ;
  };

  server = callPackage ./server.nix {
    inherit
      src
      version
      embgit
      npmDepsHash
      ;
  };
}
