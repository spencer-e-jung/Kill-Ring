#Requires AutoHotkey v2.1-alpha.9+
#SingleInstance Force
#Include "Kill Ring.ahk"
#Include <Yunit\Yunit>
#Include <Yunit\Window>

Yunit.Use(YunitWindow).Test(TestKillRing)

ResetGlobals() {
    A_Clipboard := ""

    ; XXX: Wait for the Hook to set things so we can unset them.
    Sleep(128)
    global killRing := []
    global killLock := false
    global killFile := false
    global yankIndex := 1
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
            global yankIndex := 1
            global initialYank := true
            global nextCommand := "Up"

            BreakSoon()

            YankCommand()
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

            YankCommand()

            Destroy(g)

            Yunit.Assert(A_TickCount - start >= 150)
        }

        TestIfNotBreakUndos() {
            ResetGlobals()

            g := CreatePasteGui()

            global killRing := ["A","B"]
            global yankIndex := 1
            global nextCommand := "Up"

            BreakSoon(, "Up")

            YankCommand()

            txt := GetText(g)

            Destroy(g)

            Yunit.Assert(yankIndex == 2 && txt == "A")
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

            YankCommand()

            Destroy(g)

            Yunit.Assert(A_TickCount - start >= 200 && yankIndex == 2)
        }

        TestKillFileOnClipboardEndsOnClipboard() {
            ResetGlobals()

            g := CreatePasteGui()

            global killFile := "file"
            global killRing := ["from ring", "other"]
            global yankIndex := 2
            global initialYank := false
            global killLock := true

            BreakSoon()

            YankCommand()

            Destroy(g)

            Yunit.Assert(A_Clipboard == "file")
        }
    }

    class TestYankNextIndex {

        TestCommandsWrap() {
            ResetGlobals()

            global killRing := ["a","b","c"]
            global yankIndex := 3
            
            NextYankIndex("Up") 
            
            Yunit.Assert(yankIndex == 1)
        }

        TestDownWraps() {
            ResetGlobals()

            global killRing := ["a","b","c"]
            global yankIndex := 1
            
            NextYankIndex("Down")
            
            Yunit.Assert(yankIndex == 3)
        }
    }

    class TestYankDispatch {

        TestPopNeverUnderflows() {
            ResetGlobals()

            global killRing := ["a"]
            global yankIndex := 1

            Loop 2 {
                BreakSoon()

                global nextCommand := "Pop Up"
                YankDispatch()
            }

            Yunit.Assert(killRing.Length == 0)
        }

        TestPopDownNeverUnderflows() {
            ResetGlobals()

            global killRing := ["a"]
            global yankIndex := 1

            Loop 2 {
                BreakSoon()
            
                global nextCommand := "Pop Down"
                YankDispatch()
            }

            Yunit.Assert(killRing.Length == 0)
        }

        TestInvalidCommandShowsMsgBox() {
            ResetGlobals()

            global killRing := ["a"]
            global yankIndex := 1

            global nextCommand := "InvalidCommand"
            YankDispatch()

            Yunit.Assert(killRing.Length == 1)
        }

        TestEmptyKillRingReturnsEarly() {
            ResetGlobals()

            global killRing := []
            global yankIndex := 1

            global nextCommand := "Up"
            YankDispatch()

            Yunit.Assert(true)
        }
    }
}