{
  lib,
  stdenv,
  buildNpmPackage,
  electron_39,
  fetchFromGitHub,
  jq,
  git,
  hugo,
  makeDesktopItem,
  buildGoModule,
}:

let
  electron = electron_39;
  description = "A local first flat-file CMS";
  icon = "quiqr";

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
buildNpmPackage (finalAttrs: {
  pname = "quiqr";
  version = "0.21.4";

  src = fetchFromGitHub {
    owner = "quiqr";
    repo = "quiqr-desktop";
    tag = "v${finalAttrs.version}";
    hash = "sha256-FgL+DNnZgHR+WJeu5mTfGX4tAy1Uon8PoPuJGGN5WNI=";
  };

  npmDepsHash = "sha256-4/b817FDL05ang78Sb8O93l4/9XTJVNF9NQ1i9ElAbE=";

  nativeBuildInputs = [
    jq
    git
  ];

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  makeCacheWritable = true;

  #preBuild = ''
  #  if [[ $(jq --raw-output '.devDependencies.electron' < package.json | grep -E --only-matching '^[0-9]+') != ${lib.escapeShellArg (lib.versions.major electron.version)} ]]; then
  #    echo 'ERROR: electron version mismatch'
  #    exit 1
  #  fi
  #'';

  # Do not run the default build script, it tries to do way too much that
  # wouldn't work on NixOS and require patching.
  dontNpmBuild = true;

  postBuild = ''
    #npm run _build_info # TODO with nix methods
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
    cp -r locales resources{,.pak} $out/opt/quiqr
    popd

    makeWrapper '${lib.getExe electron}' "$out/bin/quiqr-desktop" \
      --add-flags $out/opt/quiqr/resources/app.asar \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --set-default ELECTRON_IS_DEV 0 \
      --set EMBGIT_PATH ${embgit}/bin/embgit \
      --set HUGO_PATH ${hugo}/bin/hugo \
      --inherit-argv0

    makeWrapper '${lib.getExe electron}' "$out/bin/quiqr-server" \
      --add-flags $out/opt/quiqr/resources/app.asar \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --set-default ELECTRON_IS_DEV 0 \
      --set EMBGIT_PATH ${embgit}/bin/embgit \
      --set HUGO_PATH ${hugo}/bin/hugo \
      --inherit-argv0

    pushd frontend/public
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
