# Releasing

A release is one tag, `vMAJOR.MINOR.PATCH`, on `main`. The tag drives
everything: lazy.nvim resolves `version = "*"` from it, `vim.pack` pins to
it, and the `release` workflow builds the GitHub Release from it.

## Version numbers

While glinter is on 0.x, a minor bump may change the Lua API or a rule id.
After 1.0:

- **Patch**: a fix that keeps the same rule ids and the same Lua API.
- **Minor**: a new rule, a new option, or a new flag.
- **Major**: a removed or renamed rule id, option, or function.

A new rule makes clean commit messages fail, so ship one in a minor
release, never a patch.

## Cut a release

1. Edit `lua/glinter/version.lua` to the new version.
2. Move the `Unreleased` notes in `CHANGELOG.md` under a
   `## [X.Y.Z] - YYYY-MM-DD` heading, and update the link at the bottom.
3. Commit both, and merge to `main`.
4. From `main`, with a clean tree:

   ```sh
   make release VERSION=X.Y.Z
   git push origin vX.Y.Z
   ```

`make release` checks the version, the changelog entry, and the tests
before it writes the tag. It does not push.

## LuaRocks, once

The `luarocks` workflow uploads a rock for every `v*` tag. Only the upload
needs an API key. Until the key is there, a tag skips the upload with a
notice, while pull requests still build and install the rock:

1. Register at [luarocks.org](https://luarocks.org), and confirm that the
   name `glinter` is free.
2. Make a key at <https://luarocks.org/settings/api-keys>.
3. Add it to the repository as the `LUAROCKS_API_KEY` secret, under
   Settings, Secrets and variables, Actions.

`rockspec.template` holds the rockspec. The action fills in the tag, the
description, and the labels. `tests/rockspec_spec.lua` renders the same
template and checks it, so `make test` catches a typo before a tag does.

To change what the rock ships, edit `rockspec.template` for the layout and
`.github/workflows/luarocks.yml` for the metadata.

## What the workflow does

`.github/workflows/release.yml` runs on any `v*` tag. It fails the release
if the tag and `lua/glinter/version.lua` disagree, or if `CHANGELOG.md` has
no entry for the version. Otherwise it runs the tests and publishes the
GitHub Release with that entry as the notes.

`.github/workflows/luarocks.yml` runs on the same tag and uploads the rock.
A pull request, or a manual run, builds and installs the rock instead of
uploading it, so the rockspec is checked before a tag depends on it.

## Fixing a bad tag

Delete the tag and the release, then tag again:

```sh
git push --delete origin vX.Y.Z
git tag -d vX.Y.Z
```

Do that only within minutes of the push. Once someone installs the
release, ship a patch instead.
