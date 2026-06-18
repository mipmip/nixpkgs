{
  lib,
  callPackage,
  fetchFromGitHub,
  jq,
  git,
  nodejs_22,
  npm-lockfile-fix,
  embgit,
}:

let
  version = "0.23.0";
  quiqrGitHash = "sha256-ecfk6xVpNUZtDXtpAVACfmlh2sUS8tPGpgQ4iY/4h9c=";
  npmDepsHash = "sha256-TMzBsTy2vCzdsdfHtNilb45My0RgkwU1G74cSlov7RM=";

  srcOfficial = fetchFromGitHub {
    owner = "quiqr";
    repo = "quiqr-desktop";
    tag = "v${version}";
    hash = quiqrGitHash;
    postFetch = ''
      chmod +w $out/package-lock.json
      ${lib.getExe npm-lockfile-fix} $out/package-lock.json
    '';
  };

  srcMipmip = fetchFromGitHub {
    owner = "mipmip";
    repo = "quiqr-desktop";
    rev = "9578537f8031412968bd83244f3257febd6079b7";
    hash = "sha256-qZVnu4hjmtvdHhtUj1K7s//HtSv4qLwrQjuRa7zn8x8=";
    postFetch = ''
      chmod +w $out/package-lock.json
      ${lib.getExe npm-lockfile-fix} $out/package-lock.json
    '';
  };

  src = srcMipmip;

  patches = [ ];

  nativeBuildInputs = [
    jq
    git
  ];

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
