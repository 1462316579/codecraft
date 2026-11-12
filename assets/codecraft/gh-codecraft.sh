#!/bin/sh
# 用 git 凭据里的令牌调用 GitHub CLI（gh）。
#
# 为什么需要它：Codespaces 的端口转发、重建容器等能力**没有 REST 端点**，只能走 gh；
# gh 认 GH_TOKEN 环境变量。令牌取自与 git 推送同一份凭据（~/.codecraft/git-credentials），
# 由本脚本在容器内解码后经环境变量交给 gh —— 令牌不进 argv、不进 shell 历史、不进日志。
#
# 用法：gh-codespaces.sh codespace ports -c NAME --json sourcePort,label,visibility,browseUrl
CODECRAFT="${CODECRAFT_DIR:-$HOME/.codecraft}"
CRED_FILE="$CODECRAFT/git-credentials"

if [ ! -f "$CRED_FILE" ]; then
    echo "未配置 GitHub 凭据：缺少 $CRED_FILE（请在「Git 凭据」里填写令牌）" >&2
    exit 3
fi

raw="$(cat "$CRED_FILE" 2>/dev/null)"
[ -n "$raw" ] || { echo "Git 凭据为空" >&2; exit 3; }

# 整体反转（纯 awk，兼容 busybox awk）后 base64 解码。
# 不能只看「base64 -d 有没有报错」：它对非法输入是宽容的，会把明文解成二进制垃圾。
# 与 git-credential-codecraft 同款做法——往返校验（重新编码后与原文一致）才认定是编码格式，
# 否则按明文处理（兼容旧版直接写明的凭据文件）。
rev="$(printf '%s' "$raw" | awk '{ for (i = length($0); i > 0; i--) printf "%s", substr($0, i, 1) }')"
reencoded="$(printf '%s' "$rev" | base64 -d 2>/dev/null | base64 2>/dev/null | tr -d '\n')"
if [ -n "$reencoded" ] && [ "$reencoded" = "$rev" ]; then
    plain="$(printf '%s' "$rev" | base64 -d 2>/dev/null)"
else
    plain="$raw"
fi

# 凭据是 git 的 store 格式：每行 `https://用户名:令牌@主机`（用户名与令牌都做过 URL 编码）。
# 取 github.com 那条；没有则退回「所有主机」（主机名为 *）那条 —— 与 App 侧 findForHost 同序。
# 密码里的 ':' 会被编码成 %3A，所以按第一个 ':' 切分用户名/令牌是安全的。
token="$(printf '%s\n' "$plain" | awk -F'@' '
    $0 ~ /^[[:space:]]*$/ { next }
    { host = $NF; sub(/^[[:space:]]+/, "", host); sub(/[[:space:]]+$/, "", host);
      rest = $0; sub(/@[^@]*$/, "", rest); sub(/^[a-zA-Z]+:\/\//, "", rest);
      if (host == "github.com") { exact = rest; next }
      if (host == "*" && any == "") { any = rest } }
    END { print (exact != "" ? exact : any) }
' | sed 's/^[^:]*://')"

[ -n "$token" ] || {
    echo "Git 凭据里没有 github.com 或「所有主机」的令牌（请在「Git 凭据」里填写）" >&2
    exit 3
}

command -v gh >/dev/null 2>&1 || {
    echo "容器里没有 gh（GitHub CLI）：请在终端执行命令 codecraft 安装「GitHub Codespaces」依赖" >&2
    exit 4
}

GH_TOKEN="$token"
export GH_TOKEN
exec gh "$@"