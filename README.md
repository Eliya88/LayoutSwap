# LayoutSwap

Fixes text typed in the wrong keyboard layout (English ⇄ Hebrew). Select the text and press **Alt+Q**. `akuo` becomes `שלום`, and pressing it again changes it back.

If nothing is selected, it converts the **whole current line**, including any other text on it.

Afterwards the keyboard switches to the language it converted into, so you can keep typing right away. Alt+Q does nothing in terminal windows (cmd, PowerShell, Windows Terminal and Git Bash), because Ctrl+C there would stop the running program.

Your clipboard is left as it was. The script saves it in every format first and restores it afterwards.

## Requirements
[AutoHotkey v2](https://www.autohotkey.com/):
```
winget install AutoHotkey.AutoHotkey
```

## Run
Double-click `LayoutSwap.ahk`. A green **H** icon appears in the system tray. To stop the script, right-click the icon and choose **Exit**.

**Start with Windows:** press Win+R, type `shell:startup`, and put a shortcut to `LayoutSwap.ahk` in the folder that opens.

## Test
```
& "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe" LayoutSwap.ahk --test | Write-Output
```
This prints `all passed` and exits with code 0.

## How it works
1. Waits until you release the hotkey keys (up to 1 second).
2. Saves the clipboard, then sends Ctrl+C.
   - If nothing was copied, or an editor copied the whole line because nothing was selected, the script presses End and then Shift+Home to select the line itself, then copies again.
   - If that is still empty (an empty line, or text that can't be copied), it restores the clipboard and does nothing.
3. Converts the text in whichever direction most of its letters point. Hebrew letters mean Hebrew→English; English letters or a tie mean English→Hebrew.
4. Sends Ctrl+V, then switches the keyboard layout to the language of the converted text.
5. Waits 500 ms and restores the original clipboard.

The mapping follows the standard Windows Hebrew layout, which I compared key by key against the layout installed on this machine. It includes the brackets that the Hebrew layout swaps: `()`, `[]`, `{}` and `<>`. Anything not in the table passes through unchanged, such as digits, spaces, emoji and shifted keys that are the same in both layouts.

## Known limitations
- **Line mode with word wrap:** with nothing selected, Home and End work on the line as you see it on screen. If a long line wraps, only the visible part is converted.
- **Selecting a single whole line with its line break:** this is treated the same as nothing selected. The line is still converted; only the line break is left as it is.
- **Terminals inside editors:** the terminal built into PyCharm or VS Code is part of the editor window, so the script can't tell it apart from the editor. Don't press Alt+Q there while a program is running.
- **Admin windows:** apps running as administrator don't respond unless the script also runs as administrator.
- **Slow apps:** if an app ever pastes your old clipboard instead of the converted text, raise the `Sleep 500` near the end of the script.
- **Changing the hotkey:** edit the `!vk51::` line and the `vk51` in the `KeyWait` line (`!` = Alt, `vk51` = Q).
