#Requires AutoHotkey v2.0.0+
#SingleInstance Force
#Include "Kill Lock.ahk"
#Include <MouseHook\MouseHook>

global registers := Map()
global prefixHook := InputHook()
; TODO: Is it sufficient to add these X1 and X2 Buttons?
global unprefixHook := MouseHook(
    "LButton Down RButton Down MButton Down X1Button Down X2Button Down"
    , UnsetPrefix
)
global registerKey := ""

InstallKeybdHook()
prefixHook.KeyOpt("{All}", "+NS")
prefixHook.KeyOpt(
    "{LControl}{RControl}{LShift}{RShift}{LAlt}{RAlt}{LWin}{RWin}"
    , "-N"
)
prefixHook.OnKeyDown := SetPrefix

SetPrefix(prefixHook, virtualKey, scanKey) {
    global registerKey, unprefixHook

    prefixHook.Stop()
    unprefixHook.Stop()
    registerKey := GetKeyName(Format("vk{1:#x}sc{2:#x}", virtualKey, scanKey))
}

UnsetPrefix(event, wParam, lParam) {
    global registerKey, prefixHook

    prefixHook.Stop()
    unprefixHook.Stop()
    registerKey := "Break"
}

CopyToRegister() {
    global prefixHook, unprefixHook, registerKey, registers

    prefixHook.Start()
    unprefixHook.Start()

    while(!registerKey)
        Sleep(10)

    if (registerKey != "Break") {
        killLock := true
        tempClipboard := ClipboardAll()
        A_Clipboard := ""
        Send("^{Insert}")
        ClipWait(1)
        registers[registerKey] := ClipboardAll()
        A_Clipboard := tempClipboard
        killLock := false
    }
    registerKey := ""
}

PasteFromRegister() {
    global prefixHook, unprefixHook, registerKey, registers
    
    prefixHook.Start()
    unprefixHook.Start()
    
    while(!registerKey)
        Sleep(10)

    if (registerKey != "Break") {
        if (registers.Has(registerKey)) {
            killLock := true
            tempClipboard := ClipboardAll()
            A_Clipboard := registers[registerKey]
            Send("+{Insert}")
            ; XXX: Wait for the Shift-Insert to be processed.
            Sleep(32)
            A_Clipboard := tempClipboard
            killLock := false
        }
    }
    registerKey := ""
}

#!c::CopyToRegister()
#!v::PasteFromRegister()