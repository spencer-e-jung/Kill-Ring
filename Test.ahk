#Requires AutoHotkey v2.1-alpha.9+
#SingleInstance Force
#Include "Kill Ring.ahk"
#Include <Yunit\Yunit>
#Include <Yunit\Window>

; Yunit.Use(YunitWindow).Test(TestKillRing)
Yunit.Use(YunitWindow).Test(TestRegisters)

ResetGlobals() {
    A_Clipboard := ""

    ; XXX: Wait for the Hook to set things so we can unset them.
    Sleep(128)
    global killRing := []
    global killLock := false
    global killFile := false
    global initialYank := true
    global nextCommand := ""
}

BreakSoon(delay := 50, direction := "Break") {
    global nextCommand
    SetTimer(SetBreak, -delay)
    
    SetBreak() {
        global nextCommand
        nextCommand := direction
    }
}

CreatePasteGui() {
    g := Gui("+AlwaysOnTop")
    g.AddEdit("w300 h100 vEditBox")
    g.Show()
    ControlFocus("Edit1", g)
    Sleep(64)
    return g
}

Destroy(g) {
    tempHwnd := g.Hwnd
    g.Destroy()
    WinWaitClose("ahk_id " tempHwnd)
}

GetText(g) {
    return ControlGetText("Edit1", g)
}

SetText(g, txt) {
    ControlSetText(txt, "Edit1", g)
    ControlFocus("Edit1", g)
}

SelectAll() {
    Send("^a")
    Sleep(32)
}

CopySelection() {
    Send("^c")
    ClipWait(1)
}

class TestKillRing {

    class TestKill {

        TestKillText() {
            ResetGlobals()

            g := CreatePasteGui()

            SetText(g, "hello world")
            SelectAll()
            CopySelection()

            Destroy(g)
            Yunit.Assert(killRing.Length == 1)
            
            ; XXX: Pull out the value from ClipboardAll() so we can check its string value.
            A_Clipboard := killRing[1]
            
            Yunit.Assert(A_Clipboard == "hello world")
        }

        TestKillLock() {
            ResetGlobals()

            g := CreatePasteGui()

            global killLock := true

            SetText(g, "locked")
            SelectAll()
            CopySelection()

            Destroy(g)

            Yunit.Assert(killRing.Length == 0)
        }

        ; XXX: Kill files are not tested.
        ; TestKillFile() {
        ; }
    }

    class TestMouseSetBreakCommmand {

        TestMouseClickCausesBreak() {
            ResetGlobals()

            afterYankHook.Start()
            afterYankMouseHook.Start()
            MouseSetBreakCommand("", "", "")

            Yunit.Assert(nextCommand == "Break")
        }
    }

    class TestSetNextCommand {

        TestPopDownNextCommand() {
            global afterYankHook, afterYankMouseHook
            
            ResetGlobals()
            
            g := CreatePasteGui()

            afterYankHook.Start()
            afterYankMouseHook.Start()
            Send("{Alt down}{Shift down}{Ctrl down}")
            SetNextCommand(afterYankHook, 0x56, 0)
            Send("{Alt up}{Shift up}{Ctrl down}")

            Destroy(g)
            
            Yunit.Assert(nextCommand == "Pop Down")
        }

        TestPopUpNextCommand() {
            global afterYankHook, afterYankMouseHook
            
            ResetGlobals()
            
            g := CreatePasteGui()

            afterYankHook.Start()
            afterYankMouseHook.Start()
            Send("{Alt down}{Ctrl down}")
            SetNextCommand(afterYankHook, 0x56, 0)
            Send("{Alt up}{Ctrl up}")
            
            Destroy(g)
            
            Yunit.Assert(nextCommand == "Pop Up")
        }

        TestDownNextCommand() {
            global afterYankHook, afterYankMouseHook
            
            ResetGlobals()
            
            g := CreatePasteGui()

            afterYankHook.Start()
            afterYankMouseHook.Start()
            Send("{Shift down}{Ctrl down}")
            SetNextCommand(afterYankHook, 0x56, 0)
            Send("{Shift up}{Ctrl up}")
            
            Destroy(g)
            
            Yunit.Assert(nextCommand == "Down")
        }

        TestUpNextCommand() {
            global afterYankHook, afterYankMouseHook
            
            ResetGlobals()
            
            g := CreatePasteGui()

            afterYankHook.Start()
            afterYankMouseHook.Start()
            Send("{Ctrl down}")
            SetNextCommand(afterYankHook, 0x56, 0)
            Send("{Ctrl up}")
            
            Destroy(g)
            
            Yunit.Assert(nextCommand == "Up")
        }

        ; TODO: Doesn't check that the key actually went through.
        TestBreakNextCommandVKey() {
            global afterYankHook, afterYankMouseHook
            
            ResetGlobals()
            
            g := CreatePasteGui()

            afterYankHook.Start()
            afterYankMouseHook.Start()
            SetNextCommand(afterYankHook, 0x56, 0)
            
            Destroy(g)
            
            Yunit.Assert(nextCommand == "Break")
        }
        
        ; TODO: Doesn't check that the key actually went through.
        TestBreakNextCommandNormalKey() {
            global afterYankHook, afterYankMouseHook
            
            ResetGlobals()
            
            g := CreatePasteGui()

            afterYankHook.Start()
            afterYankMouseHook.Start()
            SetNextCommand(afterYankHook, 0x46, 0)
            
            Destroy(g)
            
            Yunit.Assert(nextCommand == "Break")
        }
        
        ; TODO: Doesn't check that the key actually went through.
        TestBreakNextCommandHotKey() {
            global afterYankHook, afterYankMouseHook

            ResetGlobals()

            g := CreatePasteGui()

            afterYankHook.Start()
            afterYankMouseHook.Start()
            Send("{Ctrl down}{Alt down}")
            SetNextCommand(afterYankHook, 0x46, 0)
            Send("{Ctrl up}{Alt up}")

            Destroy(g)

            Yunit.Assert(nextCommand == "Break")
        }
    }

    class TestYankCommand {

        TestKillFileAtInitialYankPastes() {
            ResetGlobals()

            g := CreatePasteGui()

            global killRing := ["hello"]
            global killFile := "file"
            global initialYank := true
            global nextCommand := "Up"
            killLock := true
            A_Clipboard := killFile
            killLock := false

            BreakSoon()

            YankCommand("Up", 1, true)
            txt := GetText(g)

            Destroy(g)

            Yunit.Assert(txt == "file")
        }

        ; XXX: This is not a very good test.
        TestWaitsForNextCommand() {
            ResetGlobals()

            g := CreatePasteGui()

            global killRing := ["A"]

            start := A_TickCount

            BreakSoon(, "Up")

            YankCommand("Up", 1, false)

            Destroy(g)

            Yunit.Assert(A_TickCount - start >= 150)
        }

        TestIfNotBreakUndos() {
            ResetGlobals()

            g := CreatePasteGui()

            global killRing := ["A","B"]
            global nextCommand := "Up"

            BreakSoon(, "Up")

            YankCommand("Up", 1, false)

            txt := GetText(g)

            Destroy(g)

            Yunit.Assert(txt == "A")
        }

        ; XXX: This is not a very good test.
        TestIfNotBreakWaitsForRelease() {
            ResetGlobals()

            g := CreatePasteGui()

            global killRing := ["A", "B"]
            global nextCommand := "Up"

            start := A_TickCount

            BreakSoon(, "Up")

            Send("{Ctrl down}{v down}")
            SetTimer(() => Send("{v up}"), 200)

            YankCommand("Up", 1, false)

            Destroy(g)

            Yunit.Assert(A_TickCount - start >= 200)
        }

        TestKillFileOnClipboardEndsOnClipboard() {
            ResetGlobals()

            g := CreatePasteGui()

            global killFile := "file"
            global killRing := ["from ring", "other"]
            global initialYank := false
            global killLock := true

            BreakSoon()

            YankCommand("Up", 2, false)

            Destroy(g)

            Yunit.Assert(A_Clipboard == "file")
        }
    }

    class TestYankNextIndex {

        TestCommandsWrap() {
            ResetGlobals()

            global killRing := ["a","b","c"]
            
            index := NextYankIndex("Up", 3) 
            
            Yunit.Assert(index == 1)
        }

        TestDownWraps() {
            ResetGlobals()

            global killRing := ["a","b","c"]
            
            index := NextYankIndex("Down", 1)
            
            Yunit.Assert(index == 3)
        }
    }

    class TestYankDispatch {

        TestPopUpRemovesItem() {
            ResetGlobals()

            global killRing := ["a", "b"]

            g := CreatePasteGui()

            BreakSoon()
            YankDispatch("Pop Up", 1, false)

            Destroy(g)

            Yunit.Assert(killRing.Length == 1 && killRing[1] == "b")
        }

        TestPopDownRemovesItem() {
            ResetGlobals()

            global killRing := ["a", "b"]

            g := CreatePasteGui()

            BreakSoon()
            YankDispatch("Pop Down", 2, false)

            Destroy(g)

            Yunit.Assert(killRing.Length == 1 && killRing[1] == "a")
        }

        TestPopNeverOverflows() {
            global nextCommand

            ResetGlobals()

            global killRing := ["a"]

            g := CreatePasteGui()
            
            SetTimer(() => nextCommand := "Pop Up", 200)
            YankDispatch("Pop Up", 1, true)

            Destroy(g)

            Yunit.Assert(killRing.Length == 0)
        }

        TestPopDownNeverOverflows() {
            global nextCommand

            ResetGlobals()

            global killRing := ["a"]

            g := CreatePasteGui()
            
            SetTimer(() => nextCommand := "Pop Down", 200)
            YankDispatch("Pop Down", 1, true)

            Destroy(g)

            Yunit.Assert(killRing.Length == 0)
        }

        TestInvalidCommandShowsMsgBox() {
            ResetGlobals()

            global killRing := ["a"]

            global nextCommand := "InvalidCommand"
            YankDispatch("InvalidCommand", 1, true)

            Yunit.Assert(killRing.Length == 1)
        }

        TestEmptyKillRingReturnsEarly() {
            ResetGlobals()

            global killRing := []

            global nextCommand := "Up"
            YankDispatch("Up", 1, true)

            Yunit.Assert(true)
        }
    }
}

ResetGlobalsForRegisters() {
    A_Clipboard := ""
    Sleep(128)
    global registers := Map()
    global registerKey := ""
    global killLock := false
}

class TestRegisters {

    class TestSetPrefix {

        TestSetPrefixSetsRegisterKey() {
            global registerKey, prefixHook, unprefixHook
            
            ResetGlobalsForRegisters()
            
            prefixHook.Start()
            unprefixHook.Start()
            SetPrefix(prefixHook, 0x1B, 1)

            Yunit.Assert(registerKey == "Escape")
        }
    }

    class TestUnsetPrefix {

        TestUnsetPrefixSetsRegisterKey() {
            global registerKey, prefixHook, unprefixHook
            
            ResetGlobalsForRegisters()
            
            prefixHook.Start()
            unprefixHook.Start()
            UnsetPrefix("", 0, 0)

            Yunit.Assert(registerKey == "Break")
        }
    }

    class TestCopyToRegister {

        TestRegisterKeyBreakDoesNothing() {
            global registers, registerKey
            
            ResetGlobalsForRegisters()

            registerKey := "Break"

            CopyToRegister()

            Yunit.Assert(registers.Count == 0)
        }

        TestClipboardIsResetAfterCopy() {
            global registers
            
            ResetGlobalsForRegisters()

            g := CreatePasteGui()
            SetText(g, "test content")
            SelectAll()
            CopySelection()

            tempClipboard := A_Clipboard

            SetTimer(() => Send("a"), -200)
            SetText(g, "test not content")
            SelectAll()

            CopyToRegister()

            Destroy(g)

            Yunit.Assert(A_Clipboard == tempClipboard)
        }

        TestRegisterIsSetOnCopy() {
            global registers
            
            ResetGlobalsForRegisters()

            g := CreatePasteGui()
            SetText(g, "register content")
            SelectAll()

            SetTimer(() => Send("z"), -200)

            CopyToRegister()

            Sleep(128)
            Destroy(g)

            A_Clipboard := registers["z"]
            Yunit.Assert(A_Clipboard == "register content")
        }

        TestCutOptionCuts() {
            global registers
            
            ResetGlobalsForRegisters()

            g := CreatePasteGui()
            SetText(g, "cut me")
            SelectAll()

            SetTimer(() => Send("x"), -200)

            CopyToRegister(true)

            Destroy(g)

            A_Clipboard := registers["x"]
            Yunit.Assert(A_Clipboard == "cut me")
        }

        TestCopyOptionCopies() {
            global registers
            
            ResetGlobalsForRegisters()

            g := CreatePasteGui()
            SetText(g, "copy me")
            SelectAll()

            SetTimer(() => Send("c"), -200)

            CopyToRegister(false)

            Destroy(g)

            A_Clipboard := registers["c"]
            Yunit.Assert(A_Clipboard == "copy me")
        }
    }

    class TestPasteFromRegister {

        TestRegisterKeyBreakDoesNothing() {
            global registers, registerKey
            
            ResetGlobalsForRegisters()

            registers["a"] := "something"
            registerKey := "Break"
            tempClipboard := A_Clipboard

            PasteFromRegister()

            Yunit.Assert(A_Clipboard == tempClipboard)
        }

        TestClipboardIsResetAfterPaste() {
            global registers, killLock
            
            ResetGlobalsForRegisters()

            registers["r"] := "pasted content"
            tempClipboard := "original"
            killLock := true
            A_Clipboard := tempClipboard
            killLock := false

            g := CreatePasteGui()
            SetTimer(() => Send("r"), -200)

            PasteFromRegister()

            Destroy(g)

            Yunit.Assert(A_Clipboard == tempClipboard)
        }

        TestPasteFromRegisterPastes() {
            global registers
            
            ResetGlobalsForRegisters()

            registers["p"] := "paste value"

            g := CreatePasteGui()
            SetTimer(() => Send("p"), -200)

            PasteFromRegister()

            txt := GetText(g)
            
            Destroy(g)

            Yunit.Assert(txt == "paste value")
        }
    }
}