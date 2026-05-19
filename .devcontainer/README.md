# Codespaces Linux Desktop

This repository includes a GitHub Codespaces devcontainer for testing the Linux Flutter build and generated Debian package in an Ubuntu desktop session.

## Open The Desktop

1. Create a Codespace from this repository.
2. Wait for post-create setup to finish.
3. Open the forwarded `Ubuntu Desktop (noVNC)` port from the Codespaces `Ports` panel.
4. Click `Connect` in noVNC and use password `vscode` if prompted.

## Build Linux

```bash
flutter pub get
dart run script/prebuild_inject_version.dart
dart run script/prebuild_inject_font.dart
flutter build linux --release
```

## Package A Deb

The Codespace includes `fpm`, matching the release workflow's Debian packaging tool. The release workflow remains the source of truth for final artifacts, but the Codespace can run equivalent packaging commands for manual checks.

## Install And Run A Deb

```bash
sudo apt install ./artifacts/haka-comic-v1.2.5-amd64.deb
haka_comic
```

Replace the `.deb` path with the package you built or downloaded from GitHub Actions.
