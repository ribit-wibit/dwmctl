
/*** dwmctl **************************************************************************
 * 
 *  Version   : 0.2
 *  AutoHotkey: v2.0
 *  Tested    : Windows 11 24H2
 * 
 *  Window manipulation depends on Powertoys
 *      FancyZones > Override Windows Snap > Move windows based on [Relative position]
 * 
 ************************************************************************************/

SetWorkingDir(A_ScriptDir)
TraySetIcon(".\icons\empty.ico")

; Elevate to admin if not admin, this only necessary to control admin windows and capture hotkeys when one is focused/active
full_command_line := DllCall("GetCommandLine", "str")
if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)")) {
    try {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
}

; Path to the DLL, relative to the script
VDA_PATH := A_ScriptDir . "\VirtualDesktopAccessor.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")

GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopCount", "Ptr")
GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")
GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetCurrentDesktopNumber", "Ptr")
IsWindowOnCurrentVirtualDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnCurrentVirtualDesktop", "Ptr")
IsWindowOnDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnDesktopNumber", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")
IsPinnedWindowProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsPinnedWindow", "Ptr")
GetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopName", "Ptr")
SetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "SetDesktopName", "Ptr")
CreateDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "CreateDesktop", "Ptr")
RemoveDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RemoveDesktop", "Ptr")

; On change listeners
RegisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RegisterPostMessageHook", "Ptr")
UnregisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "UnregisterPostMessageHook", "Ptr")

; Set tray icon on launch
TraySetIcon(".\icons\" DllCall(GetCurrentDesktopNumberProc, "Int") + 1 ".ico")

; Virtual desktop functions
GetDesktopCount() {
    global GetDesktopCountProc
    count := DllCall(GetDesktopCountProc, "Int")
    return count
}
MoveCurrentWindowToDesktop(number) {
    global MoveWindowToDesktopNumberProc, GoToDesktopNumberProc
    activeHwnd := WinGetID("A")
    DllCall(MoveWindowToDesktopNumberProc, "Ptr", activeHwnd, "Int", number, "Int")
    DllCall(GoToDesktopNumberProc, "Int", number, "Int")
}
GoToPrevDesktop() {
    global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
    current := DllCall(GetCurrentDesktopNumberProc, "Int")
    last_desktop := GetDesktopCount() - 1
    ; If current desktop is 0, go to last desktop
    if (current = 0) {
        MoveOrGotoDesktopNumber(last_desktop)
    } else {
        MoveOrGotoDesktopNumber(current - 1)
    }
    return
}
GoToNextDesktop() {
    global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
    current := DllCall(GetCurrentDesktopNumberProc, "Int")
    last_desktop := GetDesktopCount() - 1
    ; If current desktop is last, go to first desktop
    if (current = last_desktop) {
        MoveOrGotoDesktopNumber(0)
    } else {
        MoveOrGotoDesktopNumber(current + 1)
    }
    return
}
GoToDesktopNumber(num) {
    global GoToDesktopNumberProc
    DllCall(GoToDesktopNumberProc, "Int", num, "Int")
    return
}
MoveOrGoToDesktopFromHotkey(string) {
    if (string = 0) {
        num := 9
    } else {
        num := StrSplit(string, " ")[-1] - 1
    }
    ; If user is holding down Mouse left button, move the current window also
    if (GetKeyState("LButton")) {
        MoveCurrentWindowToDesktop(num)
    } else {
        GoToDesktopNumber(num)
    }
    return
}
MoveOrGotoDesktopNumber(num) {
    ; If user is holding down Mouse left button, move the current window also
    if (GetKeyState("LButton")) {
        MoveCurrentWindowToDesktop(num)
    } else {
        GoToDesktopNumber(num)
    }
    return
}
GetDesktopName(num) {
    global GetDesktopNameProc
    utf8_buffer := Buffer(1024, 0)
    ran := DllCall(GetDesktopNameProc, "Int", num, "Ptr", utf8_buffer, "Ptr", utf8_buffer.Size, "Int")
    name := StrGet(utf8_buffer, 1024, "UTF-8")
    return name
}
SetDesktopName(num, name) {
    global SetDesktopNameProc
    OutputDebug(name)
    name_utf8 := Buffer(1024, 0)
    StrPut(name, name_utf8, "UTF-8")
    ran := DllCall(SetDesktopNameProc, "Int", num, "Ptr", name_utf8, "Int")
    return ran
}
CreateDesktop() {
    global CreateDesktopProc
    ran := DllCall(CreateDesktopProc, "Int")
    return ran
}
RemoveDesktop(remove_desktop_number, fallback_desktop_number) {
    global RemoveDesktopProc
    ran := DllCall(RemoveDesktopProc, "Int", remove_desktop_number, "Int", fallback_desktop_number, "Int")
    return ran
}

; Listen to virtual desktop changes
DllCall(RegisterPostMessageHookProc, "Ptr", A_ScriptHwnd, "Int", 0x1400 + 30, "Int")
OnMessage(0x1400 + 30, OnChangeDesktop)
OnChangeDesktop(wParam, lParam, msg, hwnd) {
    Critical(1)
    OldDesktop := wParam + 1
    NewDesktop := lParam + 1
    Name := GetDesktopName(NewDesktop - 1)

    ; Use Dbgview.exe to checkout the output debug logs
    ; OutputDebug("Desktop changed to " Name " from " OldDesktop " to " NewDesktop)
    TraySetIcon(".\icons\" NewDesktop ".ico")
}

; Window functions
ToggleMaximize(string) {
    minmax_state := WinGetMinMax(WinGetID("A"))
    if (minmax_state = 0)
        WinMaximize("A")
    else if (minmax_state = 1)
        WinRestore("A")
}
CenterWindow(string) {
    minmax_state := WinGetMinMax(WinGetID("A"))
    Width := 3/4 * SysGet(16)
    Top := 0
    Bottom := 0
    MonitorGetWorkArea(1,, &Top,, &Bottom)
    Height := Bottom - Top
    if (minmax_state = 0)
        WinMove((A_ScreenWidth/2)-(Width/2), 0, Width, Height, "A")
    else if (minmax_state = 1)
        WinRestore("A")
        WinMove((A_ScreenWidth/2)-(Width/2), 0, Width, Height, "A")
}

KillActiveWindow(string) {
    if WinExist("A")
        WinKill("A")
}
NukeActiveWindowProcess(string) {
    if WinExist("A")
        ProcessClose(WinGetPID("A"))
}

; From https://github.com/AutoHotkey/AutoHotkeyUX/blob/main/inc/ShellRun.ahk
ShellRun(filePath, arguments?, directory?, operation?, show?) {
    static VT_UI4 := 0x13, SWC_DESKTOP := ComValue(VT_UI4, 0x8)
    ComObject("Shell.Application").Windows.Item(SWC_DESKTOP).Document.Application
        .ShellExecute(filePath, arguments?, directory?, operation?, show?)
}

/* Hotkey definition */
modifier := "#"
homeDir := EnvGet("USERPROFILE")

; Move desktop (takes click-held window with you)
Hotkey(modifier "1", (*) => MoveOrGotoDesktopNumber(0))
Hotkey(modifier "2", (*) => MoveOrGotoDesktopNumber(1))
Hotkey(modifier "3", (*) => MoveOrGotoDesktopNumber(2))
Hotkey(modifier "4", (*) => MoveOrGotoDesktopNumber(3))
Hotkey(modifier "5", (*) => MoveOrGotoDesktopNumber(4))
Hotkey(modifier "6", (*) => MoveOrGotoDesktopNumber(5))
Hotkey(modifier "7", (*) => MoveOrGotoDesktopNumber(6))
Hotkey(modifier "8", (*) => MoveOrGotoDesktopNumber(7))
Hotkey(modifier "9", (*) => MoveOrGotoDesktopNumber(8))
Hotkey(modifier "0", (*) => MoveOrGotoDesktopNumber(9))

; Move desktop (takes active window with you)
Hotkey(modifier "+1", (*) => MoveCurrentWindowToDesktop(0))
Hotkey(modifier "+2", (*) => MoveCurrentWindowToDesktop(1))
Hotkey(modifier "+3", (*) => MoveCurrentWindowToDesktop(2))
Hotkey(modifier "+4", (*) => MoveCurrentWindowToDesktop(3))
Hotkey(modifier "+5", (*) => MoveCurrentWindowToDesktop(4))
Hotkey(modifier "+6", (*) => MoveCurrentWindowToDesktop(5))
Hotkey(modifier "+7", (*) => MoveCurrentWindowToDesktop(6))
Hotkey(modifier "+8", (*) => MoveCurrentWindowToDesktop(7))
Hotkey(modifier "+9", (*) => MoveCurrentWindowToDesktop(8))
Hotkey(modifier "+0", (*) => MoveCurrentWindowToDesktop(9))

; Move active window between Zones
Hotkey(modifier "w", (*) => Send("#{Up}"))
Hotkey(modifier "a", (*) => Send("#{Left}"))
Hotkey(modifier "s", (*) => Send("#{Down}"))
Hotkey(modifier "d", (*) => Send("#{Right}"))
; Switch between windows in the active Zone
Hotkey(modifier "q", (*) => Send("#{PgUp}"))

; Hotkey move active window between monitors (needs Windows Snap active..)
Hotkey(modifier "+a", (*) => Send("#+{Left}"))
Hotkey(modifier "+d", (*) => Send("#+{Right}"))

; Toggle active window maximize
Hotkey(modifier "f", ToggleMaximize)

; Center active window
Hotkey(modifier "c", CenterWindow)

; Kill active window
Hotkey(modifier "+q", KillActiveWindow)
Hotkey(modifier "^+q", NukeActiveWindowProcess)

; Launch WSL Terminal
Hotkey(modifier "Enter", (*) => ShellRun("wsl", "--cd ~"))

PSString := "-NoExit -c cd " . "homeDir"
; Launch Powershell
Hotkey(modifier "\", (*) => ShellRun("pwsh", "-NoExit -c cd ~"))
; Launch Powershell admin
Hotkey(modifier "+\", (*) => Run("pwsh -NoExit -c cd ~"))

; Reload dwmctl
#+r::Reload