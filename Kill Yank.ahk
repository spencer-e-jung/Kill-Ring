#Requires AutoHotkey v2.1-alpha.9+
#SingleInstance Force
#Include "Kill Lock.ahk"
#Include <MouseHook\MouseHook>

global killRing := []
global killFile := false
global nextCommand := ""
global initialYank := false

InstallKeybdHook()
global afterYankHook := InputHook()
afterYankHook.KeyOpt("{All}", "+NS")
afterYankHook.KeyOpt(
    "{LControl}{RControl}{LShift}{RShift}{LAlt}{RAlt}{LWin}{RWin}"
    , "-N"
)
afterYankHook.OnKeyDown := SetNextCommand

global afterYankMouseHook := MouseHook(
    "LButton Down RButton Down MButton Down"
    , MouseSetBreakCommand
)

OnClipboardChange(Kill)

Kill(dataType) {
    global killRing, killLock, killFile
    
    clipboard := ClipboardAll()
    
    ; XXX: files paste too slow to be undone in succession.
    if (!killLock) {
        static CF_HDROP := 15
        killFile := DllCall("IsClipboardFormatAvailable", "UInt", CF_HDROP) && 
            clipboard

        if (!killFile) 
            killRing.InsertAt(1, clipboard)
    }
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

YankCommand(command, index, initialYank) {
    global killRing, killFile, nextCommand

    if (!(killFile && initialYank && InStr(command, "Up")))
        A_Clipboard := killRing[index]

    initialYank := false
    
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
        YankDispatch(nextCommand, index)
    } else if (killFile) {
        A_Clipboard := killFile
    }
}

NextYankIndex(command, index) {
    global killRing

    if (InStr(command, "Up")) {
        if (!InStr(command, "Pop"))
            index++
        if (index > killRing.Length)
            index := 1
    } else if (InStr(command, "Down")) {
        index--
        if (index < 1)
            index := killRing.Length
    }
    return index
}

YankDispatch(command, index, initialYank := false) {
    global killRing, killLock

    if (InStr(command, "Pop"))
        killRing.RemoveAt(index)
    
    if (killRing.Length == 0)
        return
    
    if (!initialYank)
        index := NextYankIndex(command, index)

    killLock := true    
    switch command {
        case "Up", "Down", "Pop Up", "Pop Down":
            YankCommand(command, index, initialYank)
        default: 
            MsgBox("Invalid Yank Command.")
    }
    killLock := false
}

^v::YankDispatch("Up", 1, true)
+^v::YankDispatch("Down", killRing.Length, true)