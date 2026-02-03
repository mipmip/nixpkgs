{
  lib,
  stdenv,
  buildNpmPackage,
  electron_39,
  hugo,
  makeDesktopItem,

  src,
  version,
  embgit,
  npmDepsHash,
  meta,
  patches,
  postPatch,
  nodejs,
  nativeBuildInputs

}:

let
  electron = electron_39;
  description = "A local first flat-file CMS, desktop application";
  icon = "quiqr";

in
buildNpmPackage (finalAttrs: {
  pname = "quiqr";
  inherit src version npmDepsHash patches nativeBuildInputs nodejs postPatch;

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  makeCacheWritable = true;

  dontNpmBuild = true;

  postBuild = ''
    #npm run _build_info # TODO with nix methods

    npm run build:packages
    npm run build:frontend

    #&& npm run _pack_embgit && # TODO
    npm exec electron-builder -- \
      --dir \
      --c.electronDist=${electron.dist} \
      --c.electronVersion=${electron.version}
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out

    pushd dist/linux-${lib.optionalString stdenv.hostPlatform.isAarch64 "arm64-"}unpacked
    mkdir -p $out/opt/quiqr

    # needed for electron
    cp -r locales resources{,.pak} $out/opt/quiqr

    popd

    makeWrapper '${lib.getExe electron}' "$out/bin/quiqr-desktop" \
      --add-flags $out/opt/quiqr/resources/app.asar \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --set-default ELECTRON_IS_DEV 0 \
      --set EMBGIT_PATH ${embgit}/bin/embgit \
      --set HUGO_PATH ${hugo}/bin/hugo \
      --inherit-argv0

    pushd packages/frontend/public
    for icon in icon.*; do
      dir=$out/share/icons/hicolor/"''${icon%.*}"/apps
      mkdir -p "$dir"
      cp "$icon" "$dir"/${icon}.png
    done
    popd

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "Quiqr";
      exec = "Quiqr %U";
      inherit icon;
      comment = description;
      desktopName = "Quiqr";
      categories = [ "Development" ];
    })
  ];

  meta = meta // {
    mainProgram = "quiqr-desktop";
    description = description;
    platforms = electron.meta.platforms;
  };

})
