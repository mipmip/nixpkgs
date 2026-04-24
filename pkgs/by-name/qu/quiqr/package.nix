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
  quiqrGitHash = "sha256-1AZilyWRbUVxHfGMll6qJhJSwCsJS0h2kaszJJLIkfQ=";
  npmDepsHash = "sha256-3mSx5tW5a9c11xC7v9/AmxRzVtuwDEvaBAhQAkj0SSI=";

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
    rev = "5f13c9ff70eed00eb7c7d4133f29177476b29c2b";
    hash = quiqrGitHash;
    postFetch = ''
      chmod +w $out/package-lock.json
      ${lib.getExe npm-lockfile-fix} $out/package-lock.json
    '';
  };

  src = srcMipmip;

  patches = [
    # Fix globals version mismatch: package.json says ^17.0.0 but lockfile has 16.5.0
      # ./fix-globals-version.patch
  ];

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
