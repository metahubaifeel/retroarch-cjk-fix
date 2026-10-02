# RetroArch 中文全是问号 / RetroArch renders CJK as "?"

**English below ↓ · [中文](#中文)**

RetroArch's UI is completely unreadable in Chinese (and other non-Latin
languages): every CJK character becomes `?`, while Latin text in the same menu
renders fine. The fonts are fine. The problem is a **filename mismatch** between
two Debian/Ubuntu packages.

```
retroarch        looks for  assets/pkg/chinese-fallback-font.ttf
retroarch-assets installs   assets/pkg/chinese-font.ttf
                                        ↑ missing "-fallback"
```

No file at the expected path → no CJK fallback font is loaded → FreeType
substitutes `?` for every character the primary Latin UI font doesn't have.

## The fix (30 seconds)

```bash
sudo apt install fonts-droid-fallback
sudo ln -sf ../../../fonts/truetype/droid/DroidSansFallbackFull.ttf \
       /usr/share/libretro/assets/pkg/chinese-fallback-font.ttf
```

Or just run the script, which checks, repairs, and re-verifies:

```bash
sudo ./tools/fix-cjk-font.sh
```

Restart RetroArch afterwards. To switch the UI to Chinese, set
`user_language = "12"` in `~/.config/retroarch/retroarch.cfg`
(**12 = Simplified, 11 = Traditional**).

## Why it's hard to diagnose

- **English works perfectly.** The UI looks healthy until the moment you change
  the language, so nothing looks broken beforehand.
- **It looks exactly like a font-coverage problem.** It isn't. Replacing
  `ozone/regular.ttf` with a full Noto Sans CJK (44,810 glyphs) does *not* fix
  it — verified. Only the `pkg/*-fallback-font.ttf` filenames matter.

The clue that breaks it open: **switch the UI back to English but keep the same
fonts.** Chinese ROM filenames in the playlists render perfectly. Same font, same
menu, same pixels — so the font, the render path, and the file path are all
proven good, and the only remaining variable is the language setting itself.

## What's in here

| | |
|---|---|
| [`docs/tutorial-zh.html`](docs/tutorial-zh.html) | 中文图文教程，单文件，双击就看（字体和图都内嵌了） |
| [`docs/bug-report.en.md`](docs/bug-report.en.md) | Ready-to-submit bug report for Debian BTS / Launchpad |
| [`tools/fix-cjk-font.sh`](tools/fix-cjk-font.sh) | Checks, repairs, and re-verifies. `--check` is read-only. |
| [`tools/launch-portable-retroarch.sh`](tools/launch-portable-retroarch.sh) | Portable install launcher, with the font self-repair built in |
| [`docs/shots/`](docs/shots/) | Screenshots: symptom → the decisive clue → fixed |

## Scope

This repo is **not** a RetroArch distribution. It's one bug, its diagnosis, and
the fix. No binaries, no fonts beyond the subset embedded in the tutorial page.

Affects `retroarch-assets` `1.7.6+git20230911+dfsg-1` (Ubuntu 24.04 noble, and
presumably Debian testing/unstable) with `retroarch` `1.18.0+dfsg-1`. The same
package also ships a `korean-fallback-font.ttf` symlinked to a *Latin* font
(no Hangul at all), and omits the Thai and Ethiopic fallbacks entirely.

---

## 中文

RetroArch 一切到中文，**所有汉字变成一个汉字一个 `?`** —— 菜单、播放列表里的
中文游戏名全变，拉丁字母照常显示。**字体没问题**，问题出在两个 Debian 包
对同一个文件名各叫各的：

```
retroarch 这个程序      去找  assets/pkg/chinese-fallback-font.ttf
retroarch-assets 这个包 装了  assets/pkg/chinese-font.ttf
                                      ↑ 少了个 -fallback
```

程序在约定位置找不到文件，就不加载 CJK 回退字体；主界面的拉丁字体里没有汉字，
FreeType 只好拿 `?` 顶替。

### 修复（两行）

```bash
sudo apt install fonts-droid-fallback
sudo ln -sf ../../../fonts/truetype/droid/DroidSansFallbackFull.ttf \
       /usr/share/libretro/assets/pkg/chinese-fallback-font.ttf
```

或者直接跑脚本（会检查 → 修 → 复验）：

```bash
sudo ./tools/fix-cjk-font.sh
```

改完重启 RetroArch。语言设置在 `~/.config/retroarch/retroarch.cfg`：
`user_language = "12"`（**12 = 简体，11 = 繁体，别写错**）。

### 为什么这个坑难查

- **英文界面完全正常** —— 你不切语言就永远看不出任何异样。
- **症状长得跟"字体缺字"一模一样，但就是不是。** 换完整的 Noto Sans CJK
  （44,810 个字形）上去照样满屏 `?`，实测过。真正起作用的只有
  `pkg/*-fallback-font.ttf` 这几个文件名，别的都不相干。

真正的突破口是另一个测试：**把语言切回英文，字体保持同一套不动。**
这时播放列表里的中文游戏名显示得好好的 —— 同一套字体、同一个菜单、同一批像素，
于是字体本身、渲染链路、文件路径全部被证明是好的，只剩语言设置这一个变量。

### 目录说明

| | |
|---|---|
| `docs/tutorial-zh.html` | 完整排查过程的图文教程（就是本页顶部那个，单文件自包含） |
| `docs/bug-report.en.md` | 可直接提交给 Debian / Launchpad 的英文错误报告 |
| `tools/fix-cjk-font.sh` | 检查 + 修复 + 复验；`--check` 只检查不改 |
| `tools/launch-portable-retroarch.sh` | 便携版启动器，内置字体自修复 |
| `docs/shots/` | 截图：症状 → 决定性线索 → 修好之后 |

### 范围

这个仓库**不是**一个 RetroArch 发行版，只是「一个 bug + 排查 + 修法」。
不含任何二进制，字体只有教程页里内嵌的那个子集。

### 想帮忙的话

这个 bug 现在还没有被报上去。如果你在 Debian BTS 或 Launchpad 上提了，
欢迎开 issue 说一声，我把链接贴上来。报告是现成的：`docs/bug-report.en.md`。

---

## License

Scripts and text: MIT (see `LICENSE`).

The tutorial page embeds subset fonts — Noto Sans CJK SC (SIL OFL 1.1) and
DejaVu Sans Mono (Bitstream Vera). Full license texts in `licenses/`.
