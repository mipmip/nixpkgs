{
  lib,
  callPackage,
  fetchFromGitHub,
  buildGoModule,
}:

let

  version = "0.21.6";

  #src = fetchFromGitHub {
  #  owner = "quiqr";
  #  repo = "quiqr-desktop";
  #  tag = "v${version}";
  #  hash = "sha256-AAreDkzc0sQ+f8GZz/Uy4xDMerpQ01JLyXltlZMhJk0=";
  #};

  src = fetchFromGitHub {
    owner = "mipmip";
    repo = "quiqr-desktop";
    rev = "a1c414c5a04acc7be573f2b1c39695f662d77e34";
    hash = "sha256-t1eIFfmdwdSV4dA6xCPI9tv+VAa8uAz7fmB5TloG0fc=";
  };

  npmDepsHash = "sha256-MNQ14v6/0BC27vD0B1sBoJKT9D69Bvnap9YPCK12hyY=";

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
