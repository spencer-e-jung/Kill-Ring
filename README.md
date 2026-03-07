# Kill Ring

<p align="center">
    <img src="./Images/Kill Ring.png" width="300px">
</p>

This program emulates the Emacs kill-ring in Microsoft Windows. It does this in the following manner:

1. Copying non-files adds the copyied content to the kill-ring.
2. Pressing Ctrl-v pastes the file or first item from the kill-ring Ctrl-Alt-v pops an item from the kill-ring.
3. Subsequent presses to these commands undos the previous paste and pastes or pops the next item in the kill-ring.
4. Ctrl-Shift-v and Ctrl-Alt-Shift-v reverse this operation pasting and poping in reverse order.

# Requirements

This program requires [AutoHotkey-2.1-alpha.9+](https://www.autohotkey.com/download/2.1/).

# Tip

Compile using ahk2exe.

To run automatically go to:

1. Task Scheduler -> Action -> Create Task
2. Input the Location and Name of the script
3. Trigger -> New... -> On Workstation Unlock
4. Settings -> Stop the task if runs for longer than. -> Off
5. Ok