#!/bin/bash
# ══ 便携版 RetroArch 启动器 ══
# 用法：
#   启动RetroArch.sh                 打开主菜单，自己挑游戏
#   启动RetroArch.sh 某个游戏.gba     直接开（核心按扩展名自动选）
#
# 为什么要有这个脚本：RetroArch 的配置里路径必须是【绝对路径】，
# 写死了就搬不动了。所以这里每次启动【现生成】配置文件 ——
# 路径永远是当前实际位置，整个文件夹拷到哪都照样能跑。
#
# 注意：脚本里的变量名一律用 ASCII。bash 不认中文变量名，
#      CORE=xxx 写成 核心=xxx 会被当成命令去执行。

RA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
D="$RA/数据"
export LD_LIBRARY_PATH="$RA/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

# ── 字体自检（别删！这个坑踩了很久）──────────────────────────
# RetroArch 的中文界面会固定去下面 4 个位置找字体。Debian 打的包里
# 它们是【指向系统字体的符号链接】，单独解包出来全是坏的 ——
# 少一个，中文就全变成「?」（连游戏名也变），英文界面却完全正常，
# 非常难查。所以每次启动先从 数据/fonts/中文.ttf 重新铺一遍。
FONT_SRC="$D/fonts/中文.ttf"
A="$RA/usr/share/libretro/assets"
if [ -f "$FONT_SRC" ]; then
  for f in "$A/ozone/regular.ttf" "$A/ozone/bold.ttf" \
           "$A/pkg/chinese-fallback-font.ttf" "$A/pkg/fallback-font.ttf"; do
    if [ ! -f "$f" ] || ! cmp -s "$FONT_SRC" "$f"; then
      cp -f "$FONT_SRC" "$f"
    fi
  done
fi

# ── 现生成配置（路径跟着文件夹走）────────────────────────────
# 「浏览文件」的起止目录：有 ~/游戏 就用它，没有就退回 home
BROWSER_DIR="$HOME/游戏"; [ -d "$BROWSER_DIR" ] || BROWSER_DIR="$HOME"

cat > "$D/retroarch.cfg" <<CFG
libretro_directory   = "$D/cores"
libretro_info_path   = "$D/info"
assets_directory     = "$RA/usr/share/libretro/assets"
joypad_autoconfig_dir = "$D/autoconfig"
video_shader_dir     = "$D/shaders"
cheat_database_path  = "$D/cheats"
content_database_path = "$D/database"
rgui_browser_directory = "$BROWSER_DIR"
content_favorites_directory = "$D/playlists"
savefile_directory   = "$D/saves"
savestate_directory  = "$D/states"
system_directory     = "$D/system"
screenshot_directory = "$D/screenshots"
playlist_directory   = "$D/playlists"
rgui_config_directory = "$D/config"

video_font_path = "$D/fonts/中文.ttf"
menu_driver = "ozone"
user_language = "12"              # 12 = 简体中文（11 是繁体，别写错）
video_fullscreen = "false"
video_scale = "5"                 # 240x160 的 5 倍 = 1200x800，看清每个像素
rewind_enable = "true"            # 【倒带】按 R 往回退，手滑死了能救
rewind_buffer_size = "20971520"
autosave_interval = "10"
savestate_autosave = "true"
savestate_auto_load = "false"
input_autodetect_enable = "true"
CFG

# ── 按扩展名选核心 ────────────────────────────────────────────
CORE=""
if [ -n "$1" ]; then
  case "${1##*.}" in
    [gG][bB][aA])          CORE="$D/cores/mgba_libretro.so"      ;;
    [gG][bB]|[gG][bB][cC]) CORE="$D/cores/gambatte_libretro.so"  ;;
    [nN][dD][sS])          CORE="$D/cores/desmume_libretro.so"   ;;
  esac
fi

if [ -n "$CORE" ] && [ -f "$CORE" ]; then
  exec "$RA/usr/bin/retroarch" --config "$D/retroarch.cfg" -L "$CORE" "$@"
else
  exec "$RA/usr/bin/retroarch" --config "$D/retroarch.cfg" "$@"
fi
