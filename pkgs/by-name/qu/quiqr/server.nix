{
  lib,
  buildNpmPackage,
  jq,
  git,
  hugo,
  nodejs,
  go,
  src,
  version,
  embgit,
  npmDepsHash,

}:

let
  description = "A local first flat-file CMS, headless server application.";
in
buildNpmPackage (finalAttrs: {
  pname = "quiqr-server";
  inherit src version npmDepsHash;

  nativeBuildInputs = [
    jq
    git
  ];

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  makeCacheWritable = true;
  dontNpmBuild = true;

  postBuild = ''
    #npm run _build_info # TODO with nix methods
    npm run build:packages
    npm run build:frontend
  '';

  installPhase = ''
    runHook preInstall

    #mkdir $out

    # needed for server
    mkdir -p $out/opt/quiqr-server
    cp -r . $out/opt/quiqr-server

    makeWrapper '${lib.getExe nodejs}' "$out/bin/quiqr-server" \
      --add-flags $out/opt/quiqr-server/packages/adapters/standalone/dist/main.js \
      --set PATH ${
        lib.makeBinPath [
          go
          hugo
        ]
      } \
      --set EMBGIT_PATH ${embgit}/bin/embgit \
      --set HUGO_PATH ${hugo}/bin/hugo \
      --inherit-argv0

    runHook postInstall
  '';

  meta = {
    changelog = "https://github.com/quiqr/quiqr-desktop/releases/tag/v${finalAttrs.version}";
    inherit description;
    homepage = "https://quiqr.org";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mipmip ];
    mainProgram = "quiqr-server";
  };
})
