#!/usr/bin/env bash
# =============================================================================
#      FileName : buildts.sh
#        Author : marslo
#       Created : 2026-06-09 16:05:37
#    LastChange : 2026-08-07 20:59:26
#    Description : build tree-sitter groovy parser - vim/nvim
# =============================================================================

set -euo pipefail

# codesign --remove-signature ~/.local/share/nvim/site/parser/groovy.so
# codesign --force --sign -   ~/.local/share/nvim/site/parser/groovy.so

cd ./tree-sitter-groovy
git pull --rebase

tree-sitter generate
tree-sitter build -o groovy.so && codesign --force --sign - groovy.so
tree-sitter build -o ~/.cache/tree-sitter/lib/groovy.dylib

command cp -f groovy.so ~/.local/share/nvim/site/parser/groovy.so

# verify
command nvim --headless -u NONE -c "set rtp+=~/.local/share/nvim/site" -c "lua vim.treesitter.language.add('groovy'); print('ok')" -c "qa!"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
