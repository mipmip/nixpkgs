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
  inherit src version npmDepsHash patches nativeBuildInputs nodejs;

  npmDepsFetcherVersion = 2;
  npmFlags = [ "--legacy-peer-deps" ];
  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  makeCacheWritable = true;
  dontNpmBuild = true;

  postBuild = ''
    npm run build -w @quiqr/types
    npm run build -w @quiqr/backend
    npm run build -w @quiqr/frontend
    npm run build -w @quiqr/adapter-electron
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/quiqr

    # Copy the app resources directly (no need for electron-packager)
    # The main entry point is packages/adapters/electron/dist/main.js
    cp -r packages node_modules package.json $out/opt/quiqr/

    makeWrapper '${lib.getExe electron}' "$out/bin/quiqr-desktop" \
      --add-flags $out/opt/quiqr \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --set-default ELECTRON_IS_DEV 0 \
      --set EMBGIT_PATH ${embgit}/bin/embgit \
      --set HUGO_PATH ${hugo}/bin/hugo \
      --inherit-argv0

    # Install icons
    pushd packages/frontend/public
    for icon in icon.*; do
      dir=$out/share/icons/hicolor/"''${icon%.*}"/apps
      mkdir -p "$dir"
      cp "$icon" "$dir"/quiqr.png
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
