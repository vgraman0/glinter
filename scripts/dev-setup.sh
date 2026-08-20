#!/usr/bin/env bash
# Idempotent developer / Cloud Agent bootstrap.
set -euo pipefail

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y lua5.4 lua5.4-dev luarocks

if update-alternatives --query lua-interpreter >/dev/null 2>&1; then
  sudo update-alternatives --set lua-interpreter /usr/bin/lua5.4
fi
if update-alternatives --query lua-compiler >/dev/null 2>&1; then
  sudo update-alternatives --set lua-compiler /usr/bin/luac5.4
fi

sudo luarocks --lua-version=5.4 install busted
sudo luarocks --lua-version=5.4 install luacheck

lua -v
busted --version
luacheck --version
