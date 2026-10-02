# Bug report: CJK text renders as "?" with retroarch 1.18.0 + retroarch-assets 1.7.6 (font filename mismatch)

**Ready to submit.** English text below is written to be pasted directly into
the Debian BTS or Ubuntu Launchpad. Nothing needs editing.

| | |
|---|---|
| **Package** | `retroarch-assets` |
| **Version** | `1.7.6+git20230911+dfsg-1` |
| **Also affects** | `retroarch` `1.18.0+dfsg-1` (the consumer of these files) |
| **Distro** | Ubuntu 24.04 LTS (noble) — presumably Debian unstable/testing too |
| **Severity** | normal (UI unreadable in ~10 languages, no crash, no data loss) |
| **Tags** | l10n, i18n |

---

## Summary

With the distribution packages installed, RetroArch's UI is completely unusable
in Chinese (and several other non-Latin languages): **every CJK character is
rendered as `?`**, while Latin text in the very same menu renders correctly.

This is not a font-coverage problem. The fonts shipped by the distribution are
fine. The problem is that `retroarch-assets` installs the CJK fallback fonts
under names that `retroarch` 1.18.0 no longer looks for.

## Reproduction

```bash
# Ubuntu 24.04
sudo apt install retroarch retroarch-assets

# switch the UI to Simplified Chinese
sed -i 's/^user_language = .*/user_language = "12"/' ~/.config/retroarch/retroarch.cfg
#   ("11" = Traditional Chinese, "12" = Simplified Chinese)

retroarch
```

**Observed:** the entire menu — every label, every menu entry, and every
Chinese ROM filename in the playlists — renders as `?`, one `?` per character.
Latin strings in the same menu ("Game Boy Advance", "Restart RetroArch
application.") render perfectly.

**Expected:** Chinese text renders normally.

## Root cause

The two packages disagree on the filename of the Chinese fallback font.

`retroarch` 1.18.0 looks for these paths (verified against the shipped binary):

```
$ strings -a /usr/bin/retroarch | grep -E '^(chinese|korean|fallback|osd)'
chinese-fallback-font.ttf
fallback-font.ttf
korean-fallback-font.ttf
osd-font.ttf
```

`retroarch-assets` 1.7.6+git20230911 installs these:

```
$ dpkg -c retroarch-assets_1.7.6+git20230911+dfsg-1_all.deb | grep -i '\.ttf'
.../assets/pkg/chinese-font.ttf          -> ../../../fonts/truetype/droid/DroidSansFallbackFull.ttf
.../assets/pkg/fallback-font.ttf         -> ../../../fonts/truetype/dejavu/DejaVuSans.ttf
.../assets/pkg/korean-fallback-font.ttf  -> ../../../fonts/truetype/noto/NotoSans-Black.ttf
.../assets/pkg/osd-font.ttf              -> ../../../fonts/truetype/dejavu/DejaVuSansMono.ttf
```

`chinese-font.ttf` ≠ `chinese-fallback-font.ttf`. The lookup fails, no CJK
fallback font is loaded, and FreeType substitutes `?` for every codepoint the
primary (Latin-only) UI font lacks.

The upstream asset bundle at
<https://buildbot.libretro.com/assets/frontend/assets.zip> ships the **correct**
names. It contains:

```
pkg/chinese-fallback-font.ttf
pkg/ethiopic-fallback-font.ttf
pkg/fallback-font.ttf
pkg/korean-fallback-font.ttf
pkg/osd-font.ttf
pkg/thai-fallback-font.ttf
```

So `retroarch-assets` is missing `chinese-fallback-font.ttf` and carries a
stale `chinese-font.ttf` instead. Upstream renamed the file at some point
after the 2023-09-11 snapshot that this package is built from.

## Additional problems found in the same directory

Both directions verified against the upstream `assets.zip` above:

1. **`pkg/thai-fallback-font.ttf` is absent** from the package. Thai text will
   render as `?` in the same way.

2. **`pkg/ethiopic-fallback-font.ttf` is absent** from the package. Ethiopic
   text (Amharic etc.) will render as `?` in the same way.

3. **`pkg/korean-fallback-font.ttf` points at the wrong kind of font.**
   It is symlinked to `fonts/truetype/noto/NotoSans-Black.ttf`, which is the
   Latin/Greek/Cyrillic "Noto Sans" family in Black weight — it contains no
   Hangul glyphs at all, so it cannot serve as a Korean fallback font.
   (Upstream ships a dedicated Korean font at this path.)

## Suggested fix

In `debian/` of the `retroarch-assets` source package, rename the Chinese
symlink and add the two missing ones:

```
usr/share/libretro/assets/pkg/chinese-fallback-font.ttf  -> ../../../fonts/truetype/droid/DroidSansFallbackFull.ttf
usr/share/libretro/assets/pkg/thai-fallback-font.ttf     -> (a Thai font, see upstream assets.zip)
usr/share/libretro/assets/pkg/ethiopic-fallback-font.ttf -> (an Ethiopic font, see upstream assets.zip)
```

and repoint `korean-fallback-font.ttf` at a font that actually has Hangul.

Alternatively — and probably more robustly — stop hand-maintaining these
symlinks and ship the upstream `assets.zip` content directly, so the filenames
cannot drift out of sync with the `retroarch` binary again.

## Note for anyone debugging this locally

The failure mode is extremely misleading: **English works perfectly**, so the
UI looks healthy until you change the language; and the symptom (`?` for every
CJK character) looks exactly like a font that lacks glyphs. Replacing
`ozone/regular.ttf` with a full CJK font does *not* fix it — confirmed with
Noto Sans CJK (44,810 glyphs), the menu still renders `?`. The only thing that
matters is the `pkg/*-fallback-font.ttf` filenames.
