# dux-linux-arm64

Unofficial **arm64 (aarch64)** `.deb` builds of the [Dux Labs](https://duxlabs.dev) desktop suite
(formerly DankMaterialShell), built from source by GitHub Actions.

Upstream ships amd64 debs (OBS / PPA) and hand-built arm64 tarballs, but no arm64 `.deb`
packages and no apt repo for arm64. This repo fills that gap: every component is compiled
natively on `ubuntu-24.04-arm` runners and published as an installable package.

| package | binary | what it is |
| --- | --- | --- |
| `dux-shell` | `dms`, `dankinstall` | the shell + installer CLI |
| `dux-greeter` | `dms-greeter` | greetd login screen |
| `dux-search` | `dsearch` | filesystem search index |
| `dux-calendar` | `dcal` | calendar app |
| `dux-files` | `dfiles` | file manager |
| `dux-gop` | `dgop` | system/process monitor |

## Install

```bash
# grab the debs from the latest release
gh release download --repo stepinus/dux-linux-arm64 --pattern '*.deb' --dir dux-debs
sudo apt install ./dux-debs/*.deb      # quickshell must already be present
```

`quickshell` itself is **not** built here — take it from your distro, from
[duxlabs](https://duxlabs.dev/docs/packaging) or build it locally. It is a `Recommends:`
of `dux-shell`, so the packages install on a system without it, but the shell needs it at runtime.

After installing, run `dms-greeter enable` (or `dms-greeter install`) if you want the login screen,
and `dms setup` for compositor config.

## Builds

`.github/workflows/build.yml`:

1. `resolve` — asks GitHub for the latest release tag of each component.
2. `build` — matrix job per component on `ubuntu-24.04-arm`: clone upstream at that tag
   (with submodules), `make build`, `make install DESTDIR=<stage>`, then `dpkg-deb`.
3. `publish` — uploads the `.deb` files + `SHA256SUMS` to a release tagged with the suite version.

Triggers: weekly schedule, manual run (optional `ref` input to build a specific tag), and tags pushed here.

Locally: `bash scripts/build-deb.sh dux-gop path/to/dux-gop dist`.

## Заметки по-русски

- Репозиторий самостоятельный, не форк: собирает компоненты Dux из их исходников в arm64 `.deb`.
- Требуется `quickshell` в системе (в зависимостях он только `Recommends`).
- Никакой связи с Dux Labs; все исходники — их, лицензия MIT.

## License

Scripts and workflow here: MIT. The packaged software is MIT, © Dux Labs / upstream authors.
