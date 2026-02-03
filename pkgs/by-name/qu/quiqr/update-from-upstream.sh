#!/usr/bin/env bash
CMDS=();DESC=();NARGS=$#;ARG1=$1;make_command(){ CMDS+=($1);DESC+=("$2");};usage(){ printf "\nUsage: %s [command]\n\nCommands:\n" $0;line="              ";for((i=0;i<=$(( ${#CMDS[*]} -1));i++));do printf "  %s %s ${DESC[$i]}\n" ${CMDS[$i]} "${line:${#CMDS[$i]}}";done;echo;};runme(){ if test $NARGS -eq 1;then eval "$ARG1"||usage;else usage;fi;}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_FILE="$SCRIPT_DIR/package.nix"

VERSION="0.22.0";
PKGS="quiqr"
GH_ORG="quiqr"
GH_REPO="quiqr-desktop"
#OVERRIDE_TAR="https://github.com/mipmip/quiqr-desktop/archive/refs/heads/fixnixnpm.tar.gz"

make_command "about" "About this update script."
about(){
  echo "${PKGS} upstream needs some fixing before it can be build in a pure sandbox"
  echo "environment. This script does the following:"
  echo "  - download ${PKGS} version ${VERSION} from github in a temp dir"
  echo "  - fix the lockfile by generating missing hash signatures"
  echo "  - create patches from changed json files"
}

make_command "update" "Get upstream and prepatch."
update(){

  echo "updating ${PKGS} for nixpkgs packaging"
  temptarfile=/tmp/${PKGS}-v${VERSION}.tar.gz
  tempdir=/tmp/${PKGS}-v${VERSION}

  if [ ! -f "$temptarfile" ]; then
    echo "Tarball does not exist; downloading from github.";
    if [ ! -f "$OVERRIDE_TAR" ]; then
      wget $OVERRIDE_TAR -O $temptarfile
    else
      wget https://github.com/${GH_ORG}/${GH_REPO}/archive/refs/tags/v${VERSION}.tar.gz -O $temptarfile
    fi
  fi

  rm -Rf $tempdir
  mkdir $tempdir

  tar -xzvf /tmp/${PKGS}-v${VERSION}.tar.gz -C $tempdir --strip-components=1

  cd $tempdir

  git init
  git add package-lock.json package.json
  git commit -m "commit4diff" package-lock.json package.json

  echo "FIX PACKAGE-LOCK.JSON HASHES"
  nix run nixpkgs#npm-lockfile-fix -- package-lock.json

  ## TEMP FULL COPY. ENABLE PATCHING
  cp package-lock.json $SCRIPT_DIR/package-lock.json

  #git diff package-lock.json > $SCRIPT_DIR/package-lock.json.patch
  #git diff package.json > $SCRIPT_DIR/package.json.patch

  echo "UPDATE NPM_HASH"
  NPM_HASH=$(nix run nixpkgs#prefetch-npm-deps -- package-lock.json)
  sed -i "s|npmDepsHash = \"[^\"]*\";|npmDepsHash = \"$NPM_HASH\";|" "$PACKAGE_FILE"
}

runme
