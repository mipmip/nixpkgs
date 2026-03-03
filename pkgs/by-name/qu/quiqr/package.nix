{
  lib,
  callPackage,
  fetchFromGitHub,
  buildGoModule,
  jq,
  git,
  nodejs_22,
  npm-lockfile-fix,
}:

let
  version = "0.22.4";
  quiqrGitHash = "sha256-4HYZGTnJgssUv2nEqTnSxh1Aryq5Ri6hhGxxAojNNXI=";
  npmDepsHash = "sha256-IUnAVhiJTiSNfvg1Oo5ZgB/1Nn0hskxl+XuVLAN0nL0=";

  srcOfficial = fetchFromGitHub {
    owner = "quiqr";
    repo = "quiqr-desktop";
    tag = "v${version}";
    hash = quiqrGitHash;
    postFetch = ''
      ${lib.getExe npm-lockfile-fix} $out/package-lock.json
    '';
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

  pkgsArgs = {
    nodejs = nodejs_22;
    inherit src version embgit npmDepsHash patches nativeBuildInputs meta;
  };

in

lib.recurseIntoAttrs {
  desktop = callPackage ./quiqr_desktop.nix pkgsArgs;
  server = callPackage ./quiqr_server.nix pkgsArgs;
}
