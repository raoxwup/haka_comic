#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_dir="/usr/local/flutter"
pubspec_file="$repo_dir/pubspec.yaml"

flutter_version="$(
  awk '
    $1 == "environment:" { in_environment = 1; next }
    in_environment && /^[^[:space:]]/ { in_environment = 0 }
    in_environment && $1 == "flutter:" {
      gsub(/"/, "", $2)
      gsub(/\047/, "", $2)
      print $2
      exit
    }
  ' "$pubspec_file"
)"

if [ -z "$flutter_version" ]; then
  echo "Unable to find environment.flutter in pubspec.yaml" >&2
  exit 1
fi

if [ -x "$flutter_dir/bin/flutter" ] &&
  "$flutter_dir/bin/flutter" --version | grep -q "Flutter $flutter_version"; then
  echo "Flutter $flutter_version is already installed."
else
  sudo rm -rf "$flutter_dir"

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  archive="flutter_linux_${flutter_version}-stable.tar.xz"
  url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${archive}"

  curl -fsSL "$url" -o "$tmp_dir/$archive"
  sudo tar -xf "$tmp_dir/$archive" -C /usr/local
  sudo chown -R "$(id -u):$(id -g)" "$flutter_dir"
fi

sudo chown -R "$(id -u):$(id -g)" "$flutter_dir"
git config --global --add safe.directory "$flutter_dir" || true
sudo ln -sf "$flutter_dir/bin/flutter" /usr/local/bin/flutter
sudo ln -sf "$flutter_dir/bin/dart" /usr/local/bin/dart

profile_file="/etc/profile.d/flutter.sh"
echo "export PATH=\"$flutter_dir/bin:\$PATH\"" | sudo tee "$profile_file" >/dev/null

flutter --version
flutter config --enable-linux-desktop
