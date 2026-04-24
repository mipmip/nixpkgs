{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:

buildGoModule rec {
  pname = "embgit";
  version = "0.6.4";

  src = fetchFromGitHub {
    owner = "quiqr";
    repo = "embgit";
    tag = "${version}";
    hash = "sha256-0eEBKhJIcKGoW8Nd1/L4849Ew99GAKoRh3otuVw4P3o=";
  };

  vendorHash = "sha256-e0CXBakEXyWOPOmw1ORHUmWfHCcWkNGR0dwtdNXG9Xo=";

  postInstall = ''
    cp "$out/bin/src" "$out/bin/embgit"
  '';

  meta = {
    description = "Embedded Git for electron apps";
    homepage = "https://github.com/quiqr/embgit";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mipmip ];
    mainProgram = "embgit";
  };
}
