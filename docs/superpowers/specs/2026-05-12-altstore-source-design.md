# AltStore Source Optimization Design

## Goal

Make the AltStore source follow AltStore's official source/update behavior more closely, while keeping the release workflow simple and reliable.

## Scope

This change covers:

- `alt_store.json`
- `script/update_alt_store_json.dart`
- `.github/workflows/update_altstore_source.yml`
- `.github/workflows/build.yml`

It does not change Flutter app code, signing, release asset naming, or the app's bundle identifier.

## Official AltStore Requirements Applied

AltStore treats the first item in an app's `versions` array as the latest compatible version. It does not use `date` to determine whether an update is newer.

Each version entry must use `version` for `CFBundleShortVersionString` and `buildVersion` for `CFBundleVersion`. These values must match the IPA's `Info.plist`.

The source must list app privacy permissions and entitlements used by the app. Privacy permissions will stay aligned with `ios/Runner/Info.plist`; entitlements remain empty unless the built IPA adds custom entitlements.

## Architecture

The build workflow will only build artifacts and create the draft GitHub release. It will not update `alt_store.json`, because draft-release-time URLs may not match the final published release assets.

The release-published workflow will be the single source update path. It will read the actual published release asset metadata, select the IPA asset, derive version/build metadata, and call the Dart updater with the real download URL, size, and publication date.

The Dart updater will remain a small command-line script. It will normalize source/app metadata, insert the new release at `versions[0]`, remove duplicates by version/build or URL, retain a bounded history, and reject invalid required inputs.

## Data Model

`alt_store.json` will keep one app entry:

- Source keys: `name`, `subtitle`, `description`, `website`, `iconURL`, `tintColor`, `featuredApps`, `apps`, `news`
- App keys: `name`, `bundleIdentifier`, `developerName`, `subtitle`, `localizedDescription`, `iconURL`, `tintColor`, `category`, `versions`, `appPermissions`
- Version keys: `version`, `buildVersion`, `date`, `downloadURL`, `size`, `minOSVersion`

`buildVersion` handling will support both plain versions and Flutter-style versions:

- `1.2.4` becomes `version=1.2.4`, `buildVersion=1.2.4` unless an explicit build value is provided.
- `1.2.4+123` becomes `version=1.2.4`, `buildVersion=123`.

## Error Handling

The updater will fail with a non-zero exit code when required inputs are missing or invalid, including missing version, missing download URL, invalid size, or invalid source JSON shape.

The release-published workflow will skip source updates when the release has no IPA asset, matching the current behavior. When an IPA exists, invalid metadata fails the workflow instead of silently publishing a bad source.

## Testing

Add focused Dart tests for the updater by running it against temporary JSON files. Tests will cover:

- inserting a new version at index 0
- parsing `version+build` into separate AltStore fields
- removing duplicate existing entries
- preserving static source/app metadata

Existing Flutter tests do not need to be expanded because this is release tooling, not runtime app behavior.
