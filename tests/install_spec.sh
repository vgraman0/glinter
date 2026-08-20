#!/bin/sh
# First-time Neovim installer: packpath link, load, uninstall.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
root=$(CDPATH= cd -- "$here/.." && pwd -P)
installer=$root/install-nvim

failed=0
fail() {
  failed=$((failed + 1))
  printf 'FAIL  install: %s\n' "$1" >&2
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

export HOME=$tmp/home
export XDG_DATA_HOME=$tmp/share
export XDG_CONFIG_HOME=$tmp/config
export XDG_STATE_HOME=$tmp/state
export XDG_CACHE_HOME=$tmp/cache
export GIT_CONFIG_GLOBAL=$tmp/gitconfig
export GIT_CONFIG_SYSTEM=/dev/null
unset GIT_EDITOR EDITOR VISUAL || true
mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
touch "$GIT_CONFIG_GLOBAL"

DEST=$XDG_DATA_HOME/nvim/site/pack/glinter/start/glinter
out=$tmp/out
err=$tmp/err

sh -n "$installer" || fail "install-nvim parses as POSIX sh"

if "$installer" --help >"$out" 2>"$err"; then
  grep -q "No plugin manager" "$out" || fail "--help describes no plugin manager"
else
  fail "--help exits 0"
fi

empty_path=$tmp/empty-path
mkdir -p "$empty_path"
if PATH=$empty_path "$installer" >"$out" 2>"$err"; then
  fail "missing nvim must fail"
else
  grep -q "Neovim not found" "$err" || fail "missing nvim explains Neovim"
fi

git config --global core.editor nano

if "$installer" >"$out" 2>"$err"; then
  :
else
  fail "install exits 0"
  cat "$err" >&2
fi

if [ -L "$DEST" ]; then
  target=$(CDPATH= cd -P -- "$DEST" && pwd)
  [ "$target" = "$root" ] || fail "link target is this clone"
else
  fail "install creates packpath symlink"
fi

grep -q "git is not using Neovim" "$out" || fail "hint when git editor is not nvim"
grep -q "core.editor nvim" "$out" || fail "hint shows git config command"
grep -q "No plugin manager" "$out" || fail "install says no plugin manager"

if "$installer" >"$out" 2>"$err"; then
  grep -q "already installed" "$out" || fail "second install is idempotent"
else
  fail "second install exits 0"
fi

if "$installer" --check >"$out" 2>"$err"; then
  grep -q "^glinter: ok" "$out" || fail "--check prints ok"
else
  fail "--check loads plugin"
  cat "$err" >&2
fi

git config --global core.editor nvim
if "$installer" >"$out" 2>"$err"; then
  grep -q "git is not using Neovim" "$out" && fail "no editor hint when editor is nvim"
else
  fail "install with nvim editor exits 0"
fi

rm "$DEST"
mkdir -p "$DEST"
echo other >"$DEST/not-glinter"
if "$installer" >"$out" 2>"$err"; then
  fail "refuse to overwrite a foreign directory"
else
  grep -q "already exists" "$err" || fail "foreign directory error names the path"
fi
rm -rf "$DEST"
ln -s "$root" "$DEST"

if "$installer" --try >"$out" 2>"$err"; then
  fail "--try without a TTY must fail"
else
  grep -q "needs a terminal" "$err" || fail "--try explains it needs a terminal"
fi

if "$installer" --uninstall >"$out" 2>"$err"; then
  [ ! -e "$DEST" ] && [ ! -L "$DEST" ] || fail "uninstall removes the link"
else
  fail "--uninstall exits 0"
fi

if "$installer" --check >"$out" 2>"$err"; then
  fail "--check after uninstall must fail"
else
  grep -q "not installed" "$err" || fail "--check after uninstall says not installed"
fi

# Clone lives in packpath already: running that tree's installer is a no-op.
in_place=$XDG_DATA_HOME/nvim/site/pack/glinter/start/glinter
mkdir -p "$in_place/plugin"
cp "$installer" "$in_place/install-nvim"
cp "$root/plugin/glinter.lua" "$in_place/plugin/glinter.lua"
ln -s "$root/lua" "$in_place/lua"
chmod +x "$in_place/install-nvim"
if "$in_place/install-nvim" >"$out" 2>"$err"; then
  grep -q "already installed" "$out" || fail "in-place packpath clone is already installed"
else
  fail "in-place packpath clone exits 0"
  cat "$err" >&2
fi

printf 'install checks done, %d failed\n' "$failed"
if [ "$failed" -gt 0 ]; then
  exit 1
fi
