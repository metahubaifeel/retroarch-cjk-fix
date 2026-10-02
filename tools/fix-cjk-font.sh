#!/usr/bin/env bash
#
# 修 RetroArch 中文界面全是「?」
#
# 症状：英文界面一切正常，一切到中文，所有汉字（含游戏名）全变成一个汉字一个「?」。
# 根因：Debian/Ubuntu 的 retroarch-assets 把中文回退字体装成了 chinese-font.ttf，
#       而 retroarch 1.18 的二进制找的是 chinese-fallback-font.ttf —— 少了个 -fallback。
#       找不到就不加载 CJK 回退字体，FreeType 只好拿 ? 顶替每个汉字。
#
# 用法：  sudo ./fix-cjk-font.sh
# 只检查不改：  ./fix-cjk-font.sh --check
#
set -euo pipefail

# 路径可覆盖：便携安装、多架构、或者想先拿别的目录试跑时用得上
A=${ASSETS_DIR:-/usr/share/libretro/assets}
PKG="$A/pkg"
BIN=${RETROARCH_BIN:-/usr/bin/retroarch}
CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

# 只有动系统目录才要 root。便携安装（自己指定 ASSETS_DIR）在自己家目录里，
# 不需要也没有 root 可用。
if [ "$CHECK_ONLY" -eq 0 ] && [ "$A" = /usr/share/libretro/assets ] && [ "$(id -u)" -ne 0 ]; then
  echo "要改系统目录，需要 root：sudo $0" >&2
  echo "（便携安装请先 export ASSETS_DIR=... 指到自己的 assets 目录）" >&2
  exit 1
fi
if [ ! -w "$(dirname "$A")" ] && [ ! -w "$A" ] && [ "$CHECK_ONLY" -eq 0 ]; then
  echo "对 $A 没有写权限。" >&2
  exit 1
fi
if [ ! -d "$A" ]; then
  echo "找不到 $A —— 先装 retroarch-assets 吧：" >&2
  echo "  sudo apt install retroarch retroarch-assets" >&2
  exit 1
fi

# ── 一、二进制到底在找哪些文件名 ────────────────────────────────
# 这一步是关键。别猜，直接问二进制。将来上游再改名，这里能第一时间发现。
echo "== retroarch 二进制要找的字体 =="
WANTED=()
if [ -r "$BIN" ]; then
  while read -r n; do
    [ -n "$n" ] && WANTED+=("$n")
  done < <(strings -a "$BIN" 2>/dev/null \
           | grep -aoE '(chinese|korean|thai|ethiopic|fallback|osd)[a-z-]*\.ttf' \
           | sort -u)
  if [ ${#WANTED[@]} -eq 0 ]; then
    echo "  (读不出名字，可能被 strip 过；改用已知的 1.18 名字继续)"
  else
    for n in "${WANTED[@]}"; do echo "  $n"; done
    echo "  —— 上面这些名字是二进制自己说的，别照着包的目录猜。"
  fi
fi

# 1.18 已知会找的四个位置 + 三种语言的回退字体
NEED=(ozone/regular.ttf ozone/bold.ttf pkg/fallback-font.ttf
      pkg/chinese-fallback-font.ttf pkg/korean-fallback-font.ttf
      pkg/thai-fallback-font.ttf pkg/ethiopic-fallback-font.ttf)

echo
echo "== 当前状态 =="
BROKEN=()
for rel in "${NEED[@]}"; do
  f="$A/$rel"
  if [ -e "$f" ] && [ -s "$f" ]; then
    printf '  ✓ %-38s %s 字节\n' "$rel" "$(stat -c%s "$f")"
  else
    printf '  ✗ %-38s 缺失或断链\n' "$rel"
    BROKEN+=("$rel")
  fi
done

# 附带说一句：包里那个名字写错的兄弟
if [ -e "$PKG/chinese-font.ttf" ]; then
  echo
  echo "  注意：$PKG/chinese-font.ttf 存在，但这个名字没人读 —— 就是它顶替了正确的那个。"
fi

if [ ${#BROKEN[@]} -eq 0 ]; then
  echo
  echo "四个关键位置都齐了。如果界面还是「?」，检查一下语言设置："
  echo "  ~/.config/retroarch/retroarch.cfg 里 user_language = \"12\"  (12=简体, 11=繁体)"
  exit 0
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo
  echo "以上是缺的。跑 sudo $0 来修。"
  exit 1
fi

# ── 二、补中文回退字体 ──────────────────────────────────────────
if [ ! -e "$PKG/chinese-fallback-font.ttf" ]; then
  DROID=/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf
  if [ ! -f "$DROID" ]; then
    echo
    echo "== 装中文字体包 =="
    apt-get install -y fonts-droid-fallback
  fi
  if [ -f "$DROID" ]; then
    if [ "$A" = /usr/share/libretro/assets ]; then
      # 系统安装：用相对符号链接，跟 Debian 自己的打包风格一致
      ln -sf ../../../fonts/truetype/droid/DroidSansFallbackFull.ttf \
             "$PKG/chinese-fallback-font.ttf"
    else
      # 便携安装：直接复制。指到 /usr/share 的符号链接一换机器/一拷 U 盘就断，
      # 便携版要的是整个文件夹自包含。
      cp -f "$DROID" "$PKG/chinese-fallback-font.ttf"
    fi
    echo "  ✓ 已补上 pkg/chinese-fallback-font.ttf"
  else
    echo "  ✗ 装了 fonts-droid-fallback 还是找不到 $DROID" >&2
    echo "    可以自己随便找一款中文字体顶上：" >&2
    echo "      ln -sf /path/to/你的中文字体.ttf $PKG/chinese-fallback-font.ttf" >&2
  fi
fi

# 补完必须回头验一次 —— 符号链接的目标不存在时，ln 照样成功返回 0，
# 你要是不回头看，就会以为修好了，结果重启还是满屏「?」。
if [ -e "$PKG/chinese-fallback-font.ttf" ]; then
  echo "  ✓ 复验通过：$(stat -Lc%s "$PKG/chinese-fallback-font.ttf") 字节"
else
  echo "  ✗ 复验不通过：$PKG/chinese-fallback-font.ttf 仍然是断链或不存在" >&2
  exit 1
fi

# ── 三、韩文/泰文/埃塞俄比亚文：包里根本没提供，只能提示 ────────
LEFT=()
for rel in "${BROKEN[@]}"; do
  [ -e "$A/$rel" ] || LEFT+=("$rel")
done
if [ ${#LEFT[@]} -gt 0 ]; then
  echo
  echo "== 仍然缺的 =="
  for rel in "${LEFT[@]}"; do echo "  $rel"; done
  cat <<'EOF'

  中文已经好了；上面这些是韩文 / 泰文 / 埃塞俄比亚文界面用的，
  Debian 包里压根没提供 —— 中文用户用不上，可以不管。

  要一起修的话，去上游完整资源包拿：
    https://buildbot.libretro.com/assets/frontend/assets.zip
  里面 pkg/ 下有全套 *-fallback-font.ttf。
  （注意 Debian 的 korean-fallback-font.ttf 指向 NotoSans-Black.ttf，
    那是拉丁字体，一个谚文字都没有 —— 就算文件在也是白搭。）
EOF
fi

echo
echo "修完了。重启 RetroArch 看看："
echo "  pkill -x retroarch    # 先杀干净，它会退出时覆写配置"
echo "  retroarch"
