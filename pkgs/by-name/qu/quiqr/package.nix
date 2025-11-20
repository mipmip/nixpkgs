{
  lib,
  stdenv,
  buildNpmPackage,
  electron_39,
  fetchFromGitHub,
  jq,
  makeDesktopItem,
}:

let
  electron = electron_39;
  description = "A local first flat-file CMS";
  icon = "quiqr";

in
buildNpmPackage (finalAttrs: {
  pname = "quiqr";
  version = "0.21.2";

  src = fetchFromGitHub {
    owner = "quiqr";
    repo = "quiqr-desktop";
    tag = "v${finalAttrs.version}";
    hash = "sha256-x1WR0Ur58tTMUqXpiVqvaZZU4ZLW/77RPiPbfQcpCiM=";
  };

  npmDepsHash = "sha256-nG1w3ovWaX8WZhU7Fl3NzAnN863Tf9Yw0yai+bE/tCA=";

  nativeBuildInputs = [ jq ];

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  makeCacheWritable = true;

  preBuild = ''
    if [[ $(jq --raw-output '.devDependencies.electron' < package.json | grep -E --only-matching '^[0-9]+') != ${lib.escapeShellArg (lib.versions.major electron.version)} ]]; then
      echo 'ERROR: electron version mismatch'
      exit 1
    fi
  '';

  # Do not run the default build script, it tries to do way too much that
  # wouldn't work on NixOS and require patching.
  dontNpmBuild = true;

  postBuild = ''
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
    cp -r locales resources{,.pak} $out/opt/quiqr
    popd

    makeWrapper '${lib.getExe electron}' "$out/bin/quiqr" \
      --add-flags $out/opt/quiqr/resources/app.asar \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --set-default ELECTRON_IS_DEV 0 \
      --inherit-argv0

      #pushd source
      #for icon in icon.*; do
      #  dir=$out/share/icons/hicolor/"''${icon%.*}"/apps
      #  mkdir -p "$dir"
      #  cp "$icon" "$dir"/${icon}.png
      #done
      #popd

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

  meta = {
    changelog = "https://github.com/quiqr/quiqr-desktop/releases/tag/v${finalAttrs.version}";
    inherit description;
    homepage = "https://quiqr.org";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ flokli ];
    mainProgram = "quiqr";
    platforms = electron.meta.platforms;
      #badPlatforms = [
      #  # Fails on darwin
      #  lib.systems.inspect.patterns.isDarwin
      #];
  };
})
