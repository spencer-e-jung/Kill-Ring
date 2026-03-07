#Requires AutoHotkey v2.1-alpha.9+
#SingleInstance Force
#Include <MouseHook\MouseHook>

global killRing := []
global killLock := false
global killFile := false
global yankIndex := 1

InstallKeybdHook()
global afterYankHook := InputHook()
afterYankHook.KeyOpt("{All}", "+NS")
afterYankHook.KeyOpt(
    "{LControl}{RControl}{LShift}{RShift}{LAlt}{RAlt}{LWin}{RWin}"
    , "-N"
)
afterYankHook.OnKeyDown := SetNextCommand
global nextCommand := ""

global afterYankMouseHook := MouseHook(
    "LButton Down RButton Down MButton Down"
    , MouseSetBreakCommand
)

OnClipboardChange(Kill)

Kill(dataType) {
    global killRing, killLock, killFile
    
    clipboard := ClipboardAll()
    
    ; XXX: files paste too slow to be undone in succession.
    static CF_HDROP := 15
    killFile := DllCall("IsClipboardFormatAvailable", "UInt", CF_HDROP) && 
        clipboard

    if (!killLock && !killFile)
        killRing.InsertAt(1, clipboard)
}

MouseSetBreakCommand(event, wParam, lParam) {
    global nextCommand, afterYankHook, afterYankMouseHook

    nextCommand := "Break"
    afterYankHook.Stop()
    afterYankMouseHook.Stop()
}

SetNextCommand(afterYankHook, virtualKey, scanKey) {
    global nextCommand, afterYankMouseHook

    alt := GetKeyState("Alt")
    shift := GetKeyState("Shift") 
    control := GetKeyState("Control") 
    v := virtualKey == 0x56

    afterYankHook.Stop()
    afterYankMouseHook.Stop()

    ; XXX: A hack to get around that we can't trigger the hotkey defined in the
    ; script we're working with via the InputHook "V" option.
    if (alt && shift && control && v)
        nextCommand := "Pop Down"
    else if (alt && control && v)
        nextCommand := "Pop Up"
    else if (shift && control && v)
        nextCommand := "Down"
    else if (control && v)
        nextCommand := "Up"
    else {
        nextCommand := "Break"
        Send(Format("{{}Blind{}}{{}VK{1:#X}SC{2:#X}{}}", virtualKey, scanKey))
    }
}

YankCommand() {
    global killRing, killFile, yankIndex, nextCommand

    if (!killFile || yankIndex != 1)
        A_Clipboard := killRing[yankIndex]
    
    Hotkey("^v", , "Off")
    Send("^v")
    Hotkey("^v", , "On")

    nextCommand := ""
    afterYankHook.Start()
    afterYankMouseHook.Start()

    ; XXX: Since we have two callbacks we're waiting on we use polling instead.
    while (!nextCommand) 
        Sleep(10)

    if (nextCommand != "Break") {    
        Send("^z")
        ; XXX: The following loop prevents errors when holding Ctrl-V.
        while (GetKeyState("v") && GetKeyState("Control"))
            Sleep(10)
        YankDispatch()
    } else if (killFile) {
        A_Clipboard := killFile
    }
}

NextYankIndex(command) {
    global killRing, yankIndex

    if (InStr(command, "Up")) {
        yankIndex++
        if (yankIndex > killRing.Length)
            yankIndex := 1
    } else if (InStr(command, "Down")) {
        yankIndex--
        if (yankIndex < 1)
            yankIndex := killRing.Length
    }
}

YankDispatch() {
    global killRing, killLock, yankIndex, nextCommand

    if (killRing.Length == 0)
        return

    killLock := true
    NextYankIndex(nextCommand)
    switch nextCommand {
        case "Up":
            YankCommand()
        case "Down":
            YankCommand()
        case "Pop Up": 
            killRing.RemoveAt(yankIndex)
            if (killRing.Length != 0)
                YankCommand()
        case "Pop Down":
            killRing.RemoveAt(yankIndex)
            if (killRing.Length != 0)
                YankCommand()
        default: MsgBox("Invalid Yank Command.")
    }
    killLock := false
}

^v::{
    global yankIndex, nextCommand
    yankIndex := 1
    nextCommand := "Up"
    YankDispatch()
}
+^v::{
    global killRing, yankIndex, nextCommand
    yankIndex := killRing.Length
    nextCommand := "Down"
    YankDispatch()
}
!^v::{
    global yankIndex, nextCommand
    yankIndex := 1
    nextCommand := "Pop Up"
    YankDispatch()
}
!+^v::{
    global killRing, yankIndex, nextCommand
    yankIndex := killRing.Length
    nextCommand := "Pop Down"
    YankDispatch()
}