# RetroArch 中文全是问号

**[English](README.md)** · **中文**

RetroArch 一切到中文，界面就完全没法看了 —— 菜单、播放列表里的中文游戏名，
**一个汉字变成一个 `?`**，而同一个菜单里的拉丁字母显示得好好的。

字体没问题。问题出在两个 Debian 包**对同一个文件名各叫各的**。

<table>
<tr>
<td width="50%"><img src="docs/shots/1-symptom-all-question-marks.png" width="100%" alt="每个汉字都变成问号的 RetroArch 菜单"></td>
<td width="50%"><img src="docs/shots/4-fixed-main-menu.png" width="100%" alt="修好之后，同一个菜单中文完全正常"></td>
</tr>
<tr>
<td align="center"><sub><b>修之前</b> —— 每个菜单项、每个中文游戏名都是 <code>?</code></sub></td>
<td align="center"><sub><b>修之后</b> —— 就是下面这两行命令</sub></td>
</tr>
</table>

## 修复

```bash
retroarch 这个程序      去找  assets/pkg/chinese-fallback-font.ttf
retroarch-assets 这个包 装了  assets/pkg/chinese-font.ttf
                                      ↑ 少了个 -fallback
```

程序在约定位置找不到文件，就不加载 CJK 回退字体；界面主字体是纯拉丁字体，
里面没有汉字，FreeType 只好拿 `?` 顶替。

**两行，什么都不用重装：**

```bash
sudo apt install fonts-droid-fallback
sudo ln -sf ../../../fonts/truetype/droid/DroidSansFallbackFull.ttf \
       /usr/share/libretro/assets/pkg/chinese-fallback-font.ttf
```

或者直接跑脚本 —— 它会**检查 → 修 → 再复验一次**：

```bash
sudo ./tools/fix-cjk-font.sh          # 加 --check 就只检查不改
```

改完重启 RetroArch。语言设置在 `~/.config/retroarch/retroarch.cfg`：
`user_language = "12"`（**12 = 简体，11 = 繁体，别写错**）。

## 为什么这个坑这么难查

两件事让它特别有欺骗性：

- **英文界面完全正常。** 你不切语言，就看不出任何异样 —— 界面看着好好的。
- **症状长得跟"字体缺字"一模一样。** 但它就是不是。

下面是那个代价很大的弯路 —— 换上一整套完整的 Noto Sans CJK（44,810 个字形），
**一点用都没有**：

<table>
<tr>
<td width="50%"><img src="docs/shots/2-noto-cjk-still-fails.png" width="100%" alt="装上完整的 Noto CJK 之后，依然全是问号"></td>
<td width="50%"><img src="docs/shots/3-clue-english-mode-ok.png" width="100%" alt="切回英文界面、字体不变，中文游戏名完全正常"></td>
</tr>
<tr>
<td align="center"><sub><b>弯路。</b>完整的 Noto Sans CJK 装上了，照样一个汉字一个 <code>?</code>。所以根本不是字体缺字。</sub></td>
<td align="center"><sub><b>真正的突破口。</b>切回英文，字体保持同一套不动 —— 中文游戏名显示得好好的。</sub></td>
</tr>
</table>

右边这张图才是把范围锁死的那一步。同一套字体、同一个菜单、同一批像素：
字体本身是好的、渲染链路是好的、文件路径也是好的。
**只剩"语言设置"这一个变量** —— 于是你就该去找「切语言时它去加载了什么」，
而不是继续在「文字需要什么才能显示」上打转。

## 仓库里有什么

| | |
|---|---|
| **[docs/tutorial-zh.html](docs/tutorial-zh.html)** | 中文图文教程 —— 完整排查过程。单文件，下载后双击就能看（字体和图都内嵌了）。 |
| [docs/bug-report.en.md](docs/bug-report.en.md) | 可直接提交给 Debian BTS / Launchpad 的英文错误报告 |
| [tools/fix-cjk-font.sh](tools/fix-cjk-font.sh) | 检查 + 修复 + 复验；`--check` 只检查不改 |
| [tools/launch-portable-retroarch.sh](tools/launch-portable-retroarch.sh) | 便携版启动器，内置字体自修复 |
| [docs/shots/](docs/shots/) | 全部截图 |

> ⚠️ GitHub 不对仓库里的 `.html` 做渲染 —— 点进去看到的是源码文本。
> 想看渲染后的网页，**把文件下载下来双击打开**就行（它是自包含的，不依赖网络）。

### 确实修好了的证据

<table>
<tr>
<td width="50%"><img src="docs/shots/5-fixed-game-list.png" width="100%" alt="游戏列表里的中文标题正常显示"></td>
<td width="50%"><img src="docs/shots/6-save-still-loads.png" width="100%" alt="绿宝石存档正常读取"></td>
</tr>
<tr>
<td align="center"><sub>播放列表里的中文游戏名</sub></td>
<td align="center"><sub>存档也照读不误 —— 图鉴 34、8 个徽章、游戏时间 36:28</sub></td>
</tr>
</table>

## 范围

这个仓库**不是**一个 RetroArch 发行版，只是「一个 bug + 排查 + 修法」。
不含任何二进制文件；字体内容只有教程页里内嵌的那个子集。

影响 `retroarch-assets` `1.7.6+git20230911+dfsg-1`（Ubuntu 24.04 noble，
Debian testing/unstable 大概也一样）配 `retroarch` `1.18.0+dfsg-1`。
同一个包里还有个 `korean-fallback-font.ttf` 指向**拉丁字体**（一个谚文字都没有），
泰文和埃塞俄比亚文的回退字体则**压根没提供**。

## 想帮忙的话

这个 bug 目前还没有被报上去。如果你在 Debian BTS 或 Launchpad 上提了，
欢迎开个 issue 说一声，我把链接贴上来。报告是现成的：
[docs/bug-report.en.md](docs/bug-report.en.md)。

## 许可证

脚本和文字：MIT（见 [LICENSE](LICENSE)）。

教程页内嵌了子集字体 —— Noto Sans CJK SC（SIL OFL 1.1）和 DejaVu Sans Mono
（Bitstream Vera）。许可证原文在 [licenses/](licenses/)。
