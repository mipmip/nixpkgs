{
  lib,
  callPackage,
  fetchFromGitHub,
  buildGoModule,
  jq,
  git,
  nodejs_22,
}:

let
  version = "0.22.0";
  quiqrGitHash ="sha256-fjzqmcT4rKKasJeK64JQqZ8kiYjbWAaPPA85+tZYuvQ=";
  npmDepsHash = "sha256-iUNWhc3GPR7p39YQVLNQyKQfzZB5KcrzX6Iy0u43K9E=";

  srcOfficial = fetchFromGitHub {
    owner = "quiqr";
    repo = "quiqr-desktop";
    tag = "v${version}";
    hash = quiqrGitHash;
  };

  srcMipmip = fetchFromGitHub {
    owner = "mipmip";
    repo = "quiqr-desktop";
    rev = "dbe424b7007f86c492af399a0d857b1728eb3d6f";
    hash = quiqrGitHash;
  };

  src = srcOfficial;

  patches = [
    #./package-lock.json.patch
    #./package.json.patch
  ];

  nativeBuildInputs = [
    jq
    git
  ];

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

  meta = {
    changelog = "https://github.com/quiqr/quiqr-desktop/releases/tag/v${version}";
    homepage = "https://quiqr.org";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mipmip ];
  };

  postPatch = ''
    cp ${./package-lock.json} ./package-lock.json
  '';



  pkgsArgs = {
    nodejs = nodejs_22;
    inherit src version embgit npmDepsHash patches nativeBuildInputs meta postPatch;
  };

in

lib.recurseIntoAttrs {
  desktop = callPackage ./quiqr_desktop.nix pkgsArgs;
  server = callPackage ./quiqr_server.nix pkgsArgs;
}
