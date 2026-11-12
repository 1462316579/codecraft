#!/bin/sh
# 场景：GitHub Codespaces（基础工具 + gh CLI）
# gh 是连接 Codespace 的必需项（gh codespace ssh 的隧道客户端），基础工具沿用 BASE_PKGS。
scenario_name_codespaces() { echo "GitHub Codespaces（基础工具 + gh CLI）"; }
install_scenario_codespaces() { install_light_runtimes "gh"; }