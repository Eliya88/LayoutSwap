# LayoutSwap

Fixes text typed in the wrong keyboard layout (English ⇄ Hebrew). Select the text and press **Alt+Q**. `akuo` becomes `שלום`, and pressing it again changes it back.

If nothing is selected, it converts the **whole current line**, including any other text on it. On an empty line it just switches the keyboard to the other language.

Afterwards the keyboard switches to the language it converted into, so you can keep typing right away. Alt+Q does nothing in terminal windows (cmd, PowerShell, Windows Terminal and Git Bash), because Ctrl+C there would stop the running program.

Your clipboard is left as it was. The script saves it in every format first and restores it afterwards.

## Installation

### 1. Get the files
- **Easy way:** on the GitHub page, click the green **Code** button, then **Download ZIP**, then extract the ZIP to a folder.
- **With git:** run `git clone https://github.com/Eliya88/LayoutSwap`.

### 2. Install AutoHotkey v2
The script is a text file that the AutoHotkey program reads and runs, a bit like how a `.py` file needs Python. Install it from [autohotkey.com](https://www.autohotkey.com/) or by running:
```
winget install AutoHotkey.AutoHotkey
```

### 3. Run it
Double-click `LayoutSwap.ahk`. The green **H** icon appears in the tray, and Alt+Q works from then on. To stop it, right-click the icon and choose **Exit**.

### 4. Optional: start with Windows
Press Win+R, type `shell:startup`, and put a shortcut to `LayoutSwap.ahk` in the folder that opens.

The Hebrew keyboard layout must be added in Windows for the automatic keyboard switch to work.

## Test
```
& "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe" LayoutSwap.ahk --test | Write-Output
```
This prints `all passed` and exits with code 0.

## How it works
1. Saves the clipboard, then sends Ctrl+C and waits up to 0.25 seconds for the text.
   - If nothing was copied, or an editor copied the whole line because nothing was selected, the script presses End and then Shift+Home to select the line itself, then copies again.
   - If that is still empty (an empty line, or text that can't be copied), it restores the clipboard and just switches the keyboard to the other language.
2. Converts the text in whichever direction most of its letters point. Hebrew letters mean Hebrew→English; English letters or a tie mean English→Hebrew.
3. Sends Ctrl+V, then switches the keyboard layout to the language of the converted text.
4. Restores the original clipboard 500 ms later, in the background, so you can press Alt+Q again right away.

The mapping follows the standard Windows Hebrew layout, which I compared key by key against the layout installed on this machine. It includes the brackets that the Hebrew layout swaps: `()`, `[]`, `{}` and `<>`. Anything not in the table passes through unchanged, such as digits, spaces, emoji and shifted keys that are the same in both layouts.

## Known limitations
- **Line mode with word wrap:** with nothing selected, Home and End work on the line as you see it on screen. If a long line wraps, only the visible part is converted.
- **Selecting a single whole line with its line break:** this is treated the same as nothing selected. The line is still converted; only the line break is left as it is.
- **Terminals inside editors:** the terminal built into PyCharm or VS Code is part of the editor window, so the script can't tell it apart from the editor. Don't press Alt+Q there while a program is running.
- **Admin windows:** apps running as administrator don't respond unless the script also runs as administrator.
- **Slow apps:** if an app ever pastes your old clipboard instead of the converted text, raise the `-500` in the `SetTimer RestoreClipboard` line of the script.
- **Changing the hotkey:** edit the `!vk51::` line (`!` = Alt, `vk51` = Q).
