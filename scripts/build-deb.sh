#!/usr/bin/env bash
# Build one Dux Labs component from source for arm64 and package it as a .deb.
# usage: build-deb.sh <pkg> <srcdir> <outdir>
set -euo pipefail

pkg=${1:?pkg}
src=$(readlink -f "${2:?srcdir}")
out=${3:?outdir}
mkdir -p "$out"

ver=$(git -C "$src" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)
ver=${ver:-0.0.0}
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

d="Depends: libc6"
r=""
case $pkg in
  dux-shell)
    make -C "$src" build
    make -C "$src/core" dankinstall
    make -C "$src" install-bin install-icon install-desktop PREFIX=/usr DESTDIR="$stage"
    make -C "$src" install-completions PREFIX=/usr DESTDIR="$stage"
    install -Dm755 "$src/core/bin/dankinstall" "$stage/usr/bin/dankinstall"
    install -Dm644 "$src/assets/systemd/dms.service" "$stage/usr/lib/systemd/user/dms.service"
    desc="Dux Shell - Wayland desktop shell (dms) and installer (dankinstall)"
    r="Recommends: quickshell | quickshell-git, dgop, danksearch, dcal, matugen, qt6ct"
    ;;
  dux-greeter)
    make -C "$src" build
    install -Dm755 "$src/core/bin/dms-greeter" "$stage/usr/bin/dms-greeter"
    install -Dm644 "$src/assets/systemd/sysusers-dms-greeter.conf" "$stage/usr/lib/sysusers.d/dms-greeter.conf"
    install -Dm644 "$src/assets/systemd/tmpfiles-dms-greeter.conf" "$stage/usr/lib/tmpfiles.d/dms-greeter.conf"
    printf '%s\n' '#!/bin/sh' 'systemd-sysusers /usr/lib/sysusers.d/dms-greeter.conf || true' \
      'systemd-tmpfiles --create /usr/lib/tmpfiles.d/dms-greeter.conf || true' > "$stage/postinst"
    chmod 755 "$stage/postinst"
    desc="Dux Greeter - greetd login screen for the Dux desktop"
    r="Recommends: greetd"
    ;;
  dux-search)
    make -C "$src" build
    install -Dm755 "$src/bin/dsearch" "$stage/usr/bin/dsearch"
    # upstream only ships the unit as an install-service target that hardcodes
    # /usr/local/bin; package it properly instead of leaving the user to do it
    mkdir -p "$stage/usr/lib/systemd/user"
    sed 's|^ExecStart=.*|ExecStart=/usr/bin/dsearch serve|' "$src/assets/dsearch.service" \
      > "$stage/usr/lib/systemd/user/dsearch.service"
    desc="Dux Search - indexed filesystem search (dsearch)"
    ;;
  dux-calendar)
    make -C "$src" build
    make -C "$src" install-bin install-icon install-desktop install-metainfo PREFIX=/usr DESTDIR="$stage"
    desc="Dux Calendar - calendar app for the Dux desktop (dcal)"
    ;;
  dux-files)
    make -C "$src" build
    make -C "$src" install-bin install-icon install-desktop install-metainfo install-polkit install-dbus install-portal \
      PREFIX=/usr DESTDIR="$stage" POLKIT_ACTIONS_DIR=/usr/share/polkit-1/actions
    desc="Dux Files - file manager for the Dux desktop (dfiles)"
    ;;
  dux-gop)
    make -C "$src" build
    install -Dm755 "$src/bin/dgop" "$stage/usr/bin/dgop"
    desc="Dux GOP - stateless system/process monitor (dgop)"
    ;;
  *)
    echo "unknown package: $pkg" >&2
    exit 2
    ;;
esac

mkdir -p "$stage/DEBIAN"
{
  echo "Package: $pkg"
  echo "Version: $ver-1"
  echo "Architecture: arm64"
  echo "Maintainer: dux-arm64 <noreply@localhost>"
  echo "Installed-Size: $(du -ks "$stage/usr" | cut -f1)"
  echo "$d"
  [ -n "$r" ] && echo "$r"
  echo "Section: x11"
  echo "Priority: optional"
  echo "Homepage: https://github.com/duxlabs-dev/$pkg"
  echo "Description: $desc"
  echo " Unofficial arm64 build of the Dux Labs component, built from source in"
  echo " GitHub Actions. Not affiliated with Dux Labs."
} > "$stage/DEBIAN/control"
[ -f "$stage/postinst" ] && mv "$stage/postinst" "$stage/DEBIAN/postinst"

dpkg-deb --root-owner-group -Zxz --build "$stage" "$out/${pkg}_${ver}-1_arm64.deb" >/dev/null
echo "built $out/${pkg}_${ver}-1_arm64.deb"
