# Music Folder & Custom Track Metadata Guide

## 1. Adding or Removing MP3 Files (No Recompilation Needed)

1. Drop any `.mp3` files into this `music/` directory (or delete existing ones).
2. On startup, the player automatically scans `music\*.mp3` (up to **32 tracks**, max **127 characters** per filename).
3. If a filename does not match any built-in demoscene metadata keyword, the player automatically falls back to displaying the filename in both the top bar (`[1/N] FILENAME.MP3`) and the bottom scroller.

> **Supported Bitmap Font Characters:**  
> The embedded 5×7 GLSL shader font supports `A–Z`, `0–9`, space, and the following symbols: `& ' ( ) , - . / : [ ]`. Lowercase letters are converted to uppercase automatically; any other special characters (such as accented letters or `_`) will render as blank spaces.

---

## 2. Adding, Editing, or Removing Custom Scroller Metadata in `torus_gpu.asm`

To display full demoscene credits (Demo, Hardware, Author, Group, Year) for your own tracks in the bottom scroller and a clean title in the top bar, edit `torus_gpu.asm` and recompile.

### A. Editing Existing Track Credits
1. Open `torus_gpu.asm` and locate the metadata strings in `section .data` (around lines 65–95).
2. Edit the `info_*` (bottom scroller) or `tag_*` (top bar) string literals.
3. Keep `info_*` under **188 characters** (`MAX_SCROLL = 192` minus 4 padding spaces) and `tag_*` under **22 characters**.

### B. Adding a New Track Entry
**Step 1 — Define the strings in `section .data`:**
```nasm
    meta_mytrack    db "mytrack", 0
    info_mytrack    db "TRACK: MY TRACK // DEMO: MY DEMO // HW: AMIGA // AUTHOR: COMPOSER // SCENE: GROUP // YEAR: 1995", 0
    tag_mytrack     db "MY TRACK", 0
```

#### Important: 
meta_* must contain only lowercase letters (a–z) and digits (0–9)—no spaces, dashes, or underscores. 
The matcher (match_alnum_key) strips all non-alphanumeric characters and lowercases the MP3 filename before comparing (e.g., 01 - My_Track (1995).mp3 matches "mytrack").

**Step 2 — Hook the check into build_scroller_text (section .text):**
Find the last check before .generic_info: (currently .chk_sota:), update its jz target to .chk_mytrack, and add your block:

```nasm
.chk_sota:
    mov rcx, rbx
    lea rdx, [meta_sota]
    call match_alnum_key
    test eax, eax
    jz .chk_mytrack            ; <-- point to your new label
    lea rcx, [scroller_txt]
    lea rdx, [info_sota]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_sota]
    call lstrcpyA
    jmp .to_uniform_arr

.chk_mytrack:
    mov rcx, rbx
    lea rdx, [meta_mytrack]
    call match_alnum_key
    test eax, eax
    jz .generic_info           ; <-- fallback if not matched
    lea rcx, [scroller_txt]
    lea rdx, [info_mytrack]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_mytrack]
    call lstrcpyA
    jmp .to_uniform_arr
```

### C. Removing a Track Entry
In build_scroller_text, delete the .chk_<name> block and point the preceding check's jz instruction to the next .chk_* label (or .generic_info).

Remove the corresponding meta_*, info_*, and tag_* lines from section .data.

**Step 3 - Recompiling After Code Changes**
Run from the root directory (one level above music/):

```DOS
nasm -f win64 torus_gpu.asm -o torus_gpu.obj
ld torus_gpu.obj -o torus_gpu.exe --subsystem windows -e WinMain -lkernel32 -luser32
```
