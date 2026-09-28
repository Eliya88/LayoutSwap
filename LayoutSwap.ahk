#Requires AutoHotkey v2.0
#SingleInstance Force

; Latin key -> Hebrew char on the standard Windows Hebrew layout.
EN_HE := Map(
    "q","/", "w","'", "e","ק", "r","ר", "t","א", "y","ט", "u","ו", "i","ן", "o","ם", "p","פ",
    "a","ש", "s","ד", "d","ג", "f","כ", "g","ע", "h","י", "j","ח", "k","ל", "l","ך", ";","ף", "'",",",
    "z","ז", "x","ס", "c","ב", "v","ה", "b","נ", "n","מ", "m","צ", ",","ת", ".","ץ", "/",".", "``",";",
    ; the Hebrew layout mirrors brackets; all other shifted keys (" : ? ! ...) are identical and pass through
    "(",")", ")","(", "[","]", "]","[", "{","}", "}","{", "<",">", ">","<"
)
HE_EN := Map()
for k, v in EN_HE
    HE_EN[v] := k

; Direction by majority: the sets overlap on . , / ' ; so per-char lookup is ambiguous.
; Ties (incl. no letters at all, e.g. only punctuation) go Latin -> Hebrew.
Convert(s, &toHeb := 0) {
    heb := 0, lat := 0
    Loop Parse s {
        c := Ord(A_LoopField)
        if (c >= 0x5D0 && c <= 0x5EA)
            heb++
        else if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122))
            lat++
    }
    toHeb := lat >= heb
    out := ""
    Loop Parse s {
        ch := A_LoopField
        if (toHeb) {
            lc := StrLower(ch)
            out .= EN_HE.Has(lc) ? EN_HE[lc] : ch
        } else
            out .= HE_EN.Has(ch) ? HE_EN[ch] : ch
    }
    return out
}

; Switch the active window's keyboard to the first installed layout of this language (0x0D Hebrew, 0x09 English).
SwitchLayout(primaryLang) {
    n := DllCall("GetKeyboardLayoutList", "Int", 0, "Ptr", 0)
    buf := Buffer(n * A_PtrSize)
    DllCall("GetKeyboardLayoutList", "Int", n, "Ptr", buf)
    Loop n {
        hkl := NumGet(buf, (A_Index - 1) * A_PtrSize, "Ptr")
        if ((hkl & 0x3FF) = primaryLang) {
            try PostMessage 0x50, 0, hkl, , "A"  ; WM_INPUTLANGCHANGEREQUEST
            return
        }
    }
}

if (A_Args.Length && A_Args[1] = "--test") {
    cases := [["akuo", "שלום"], ["שלום", "akuo"], ["AKUO", "שלום"], ["t,", "את"], ["hk", "יל"],
              ["123 !?", "123 !?"], ["akuo ש", "שלום ש"], ["שלום a", "akuo a"], ["את.", "t,/"],
              ["akuo (a)", "שלום )ש("], ["שלום )ש(", "akuo (a)"], ["/", "."], ["a ש", "ש ש"]]
    fails := 0
    for c in cases
        if ((got := Convert(c[1])) !== c[2]) {  ; !== : plain != is case-insensitive in AHK
            FileAppend "FAIL " c[1] " -> " got " (want " c[2] ")`n", "*", "UTF-8"
            fails++
        }
    for c in [["akuo", 1], ["שלום", 0], ["/", 1]]
        if (Convert(c[1], &toHeb), toHeb != c[2]) {
            FileAppend "FAIL direction of " c[1] "`n", "*", "UTF-8"
            fails++
        }
    FileAppend (fails ? fails " failed" : "all passed") "`n", "*", "UTF-8"
    ExitApp fails ? 1 : 0
}

; In terminals Ctrl+C stops the running program, so Alt+Q is left alone there.
; ponytail: PyCharm/VS Code built-in terminals share the editor's window and can't be told apart.
GroupAdd "Terminals", "ahk_class ConsoleWindowClass"               ; cmd, PowerShell (classic console)
GroupAdd "Terminals", "ahk_class CASCADIA_HOSTING_WINDOW_CLASS"    ; Windows Terminal
GroupAdd "Terminals", "ahk_exe mintty.exe"                         ; Git Bash

; Alt+Q. vk codes so the hotkey and Ctrl+C/V work while the Hebrew layout is active.
#HotIf !WinActive("ahk_group Terminals")
; No waiting for Alt to be released: Send lifts held modifiers itself, so ^c doesn't become Ctrl+Alt+C.
!vk51:: {
    global saved
    if !saved           ; a restore from a quick previous press is still pending: keep that original
        saved := ClipboardAll()
    A_Clipboard := ""
    Send "^{vk43}"      ; Ctrl+C
    ClipWait 0.25       ; ponytail: raise if a slow app's real selection gets replaced by its whole line
    ; Nothing selected: IDEs copy the whole line (one line break, at the end), other apps copy nothing.
    ; Either way, select the current line ourselves (without its line break) and copy that.
    if (InStr(A_Clipboard, "`n") = StrLen(A_Clipboard)) {
        A_Clipboard := ""
        Send "{End}+{Home}^{vk43}"
        if !ClipWait(0.5) { ; empty line / not copyable: leave everything as it was
            SetTimer RestoreClipboard, 0
            RestoreClipboard()
            return
        }
    }
    A_Clipboard := Convert(A_Clipboard, &toHeb)
    Send "^{vk56}"      ; Ctrl+V
    SwitchLayout(toHeb ? 0x0D : 0x09)  ; keep typing in the language just converted into
    ; Restore in the background so the next Alt+Q isn't blocked. Re-arming restarts the 500 ms.
    SetTimer RestoreClipboard, -500  ; ponytail: no OS signal for "paste consumed"; raise if an app ever pastes the old clipboard
}
#HotIf

saved := 0
RestoreClipboard() {
    global saved
    A_Clipboard := saved
    saved := 0
}
