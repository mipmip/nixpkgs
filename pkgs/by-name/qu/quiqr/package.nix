{
  lib,
  callPackage,
  fetchFromGitHub,
  buildGoModule,
}:

let

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
    rev = "70faf07d3efe6d1919d4dfd7ce0760445bb3b822";
    hash = "sha256-Dt8GKvWnw1Nje/N1Gh9xiFGmu/mnnwReM1pn4DMjZKU=";
  };

  npmDepsHash = "sha256-a+XPKouW4ogz+tMQiTla+hQNhz+rsH4w2hZrmlfLi04=";

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
