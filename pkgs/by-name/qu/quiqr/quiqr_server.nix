{
  lib,
  buildNpmPackage,
  git,
  hugo,
  nodejs,
  go,
  src,
  version,
  embgit,
  npmDepsHash,
  nativeBuildInputs,
  patches,
  meta
}:

buildNpmPackage (finalAttrs: {
  pname = "quiqr-server";
  inherit src version npmDepsHash patches nativeBuildInputs nodejs;

  npmDepsFetcherVersion = 2;
  npmFlags = [ "--legacy-peer-deps" ];
  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  makeCacheWritable = true;
  dontNpmBuild = true;

  # Skip optional dependencies to avoid missing platform-specific packages
  #npmInstallFlags = [ "--omit=optional" ];
  postBuild = ''
    npm run build:packages
    npm run build:frontend
  '';


  installPhase = ''
    runHook preInstall

    # needed for server
    mkdir -p $out/opt/quiqr-server
    cp -r . $out/opt/quiqr-server

    makeWrapper '${lib.getExe nodejs}' "$out/bin/quiqr-server" \
      --add-flags $out/opt/quiqr-server/packages/adapters/standalone/dist/main.js \
      --set PATH ${
        lib.makeBinPath [
          go
          hugo
          git
        ]
      } \
      --set EMBGIT_PATH ${embgit}/bin/embgit \
      --set HUGO_PATH ${hugo}/bin/hugo \
      --inherit-argv0

    runHook postInstall
  '';

  meta = meta // {
    mainProgram = "quiqr-server";
    description = "A local first flat-file CMS, headless server application.";
  };


})
