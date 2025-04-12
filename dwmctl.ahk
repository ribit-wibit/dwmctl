; AutoHotkey v2 script
SetWorkingDir(A_ScriptDir)
TraySetIcon(".\icons\empty.ico")

; Elevate to admin if not admin
full_command_line := DllCall("GetCommandLine", "str")
if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
    try
    {
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
desktop_on_launch := DllCall(GetCurrentDesktopNumberProc, "Int") + 1
TraySetIcon(".\icons\" desktop_on_launch ".ico")

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
MoveOrGoToDesktop0(string) {
    MoveOrGotoDesktopNumber(0)
}
MoveOrGoToDesktop1(string) {
    MoveOrGotoDesktopNumber(1)
}
MoveOrGoToDesktop2(string) {
    MoveOrGotoDesktopNumber(2)
}
MoveOrGoToDesktop3(string) {
    MoveOrGotoDesktopNumber(3)
}
MoveOrGoToDesktop4(string) {
    MoveOrGotoDesktopNumber(4)
}
MoveOrGoToDesktop5(string) {
    MoveOrGotoDesktopNumber(5)
}
MoveOrGoToDesktop6(string) {
    MoveOrGotoDesktopNumber(6)
}
MoveOrGoToDesktop7(string) {
    MoveOrGotoDesktopNumber(7)
}
MoveOrGoToDesktop8(string) {
    MoveOrGotoDesktopNumber(8)
}
MoveOrGoToDesktop9(string) {
    MoveOrGotoDesktopNumber(9)
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
    OutputDebug("Desktop changed to " Name " from " OldDesktop " to " NewDesktop)
    TraySetIcon(".\icons\" NewDesktop ".ico")
}

ToggleMaximize(string) {
    minmax_state := WinGetMinMax(WinGetID("A"))
    if (minmax_state = 0) {
        WinMaximize("A")
    } else if (minmax_state = 1) {
        WinRestore("A")
    }
}

MonitorMouseIn() {
    Coordmode("Mouse", "Screen")  ; use Screen, so we can compare the coords with the sysget information`
    MouseGetPos(&mx, &my)
    return CoordInWhichMonitor(mx, my)
}
MonitorWindowIn(hwnd) {
    WinGetClientPos(&x, &y, &w, &h, "ahk_id " . hwnd)
    return CoordInWhichMonitor(x, y)
}
CoordInWhichMonitor(posX, posY) {
    ; MsgBox(posX . " " . posY)
    MonitorCount := SysGet(SM_CMONITORS := 80)
    ; print({MonitorCount:MonitorCount})
    snMonitor := 0
    while true {
        snMonitor++
        if (snMonitor > MonitorCount)
            break
        
        MonitorGet(snMonitor, &Left, &Top, &Right, &Bottom)
        if (posX >= left) && (posX < right) && (posY >= top) && (posY < bottom)
            return snMonitor
    }
}
ActiveMonitorNumber() {
    WinGetClientPos(&x, &y, &w, &h, "A")
    return CoordInWhichMonitor(x + w/2, y + h/2)
}

IsModifierClean(hotkey_string) {
    allMods := ["Control", "Alt", "Shift", "LWin", "RWin"]
    allowedMods := []

    if InStr(hotkey_string, "^")
        allowedMods.Push("Control")
    if InStr(hotkey_string, "!")
        allowedMods.Push("Alt")
    if InStr(hotkey_string, "+")
        allowedMods.Push("Shift")
    if InStr(hotkey_string, "#")
        allowedMods.Push("LWin"), allowedMods.Push("RWin")
 
    for mod in allMods {
        if (!allowedMods.Has(mod) && GetKeyState(mod, "P"))
            return false
    }
    return true
}

MoveActiveWindowLeftTop(string) {
    if (IsNumber(ActiveMonitorNumber()) && WinExist("A")) {
        MonitorGetWorkArea(ActiveMonitorNumber(), &l, &t, &r, &b)
        w := r - l
        h := b - t

        minmax_state := WinGetMinMax(WinGetID("A"))
        if (minmax_state = 1) {
            WinRestore("A")
        }
        WinMove(l, t, w/2, h/2, "A")
    }
}
MoveActiveWindowRightTop(string) {
    if (IsNumber(ActiveMonitorNumber()) && WinExist("A")) {
        MonitorGetWorkArea(ActiveMonitorNumber(), &l, &t, &r, &b)
        w := r - l
        h := b - t

        minmax_state := WinGetMinMax(WinGetID("A"))
        if (minmax_state = 1) {
            WinRestore("A")
        }
        WinMove(l + w/2, t, w/2, h/2, "A")
    }
}

MoveActiveWindowLeftBottom(string) {
    if (IsNumber(ActiveMonitorNumber()) && WinExist("A")) {
        MonitorGetWorkArea(ActiveMonitorNumber(), &l, &t, &r, &b)
        w := r - l
        h := b - t

        minmax_state := WinGetMinMax(WinGetID("A"))
        if (minmax_state = 1) {
            WinRestore("A")
        }
        WinMove(l, t + h/2, w/2, h/2, "A")
    }
}
MoveActiveWindowRightBottom(string) {
    if (IsNumber(ActiveMonitorNumber()) && WinExist("A")) {
        MonitorGetWorkArea(ActiveMonitorNumber(), &l, &t, &r, &b)
        w := r - l
        h := b - t

        minmax_state := WinGetMinMax(WinGetID("A"))
        if (minmax_state = 1) {
            WinRestore("A")
        }
        WinMove(l + w/2, t + h/2, w/2, h/2, "A")
    }
}

MoveActiveWindowTop(string) {
    if (IsNumber(ActiveMonitorNumber()) && WinExist("A")) {
        MonitorGetWorkArea(ActiveMonitorNumber(), &l, &t, &r, &b)
        w := r - l
        h := b - t

        minmax_state := WinGetMinMax(WinGetID("A"))
        if (minmax_state = 1) {
            WinRestore("A")
        }
        WinMove(l, t, w, h/2, "A")
    }
}
MoveActiveWindowRight(string) {
    if (IsNumber(ActiveMonitorNumber()) && WinExist("A")) {
        MonitorGetWorkArea(ActiveMonitorNumber(), &l, &t, &r, &b)
        w := r - l
        h := b - t

        minmax_state := WinGetMinMax(WinGetID("A"))
        if (minmax_state = 1) {
            WinRestore("A")
        }
        WinMove(l + w/2, t, w/2, h, "A")
    }
}
MoveActiveWindowBottom(string) {
    if (IsNumber(ActiveMonitorNumber()) && WinExist("A")) {
        MonitorGetWorkArea(ActiveMonitorNumber(), &l, &t, &r, &b)
        w := r - l
        h := b - t

        minmax_state := WinGetMinMax(WinGetID("A"))
        if (minmax_state = 1) {
            WinRestore("A")
        }
        WinMove(l, t + h/2, w, h/2, "A")
    }
}
MoveActiveWindowLeft(string) {
    if (IsNumber(ActiveMonitorNumber()) && WinExist("A")) {
        MonitorGetWorkArea(ActiveMonitorNumber(), &l, &t, &r, &b)
        w := r - l
        h := b - t

        minmax_state := WinGetMinMax(WinGetID("A"))
        if (minmax_state = 1) {
            WinRestore("A")
        }
        WinMove(l, t, w/2, h, "A")
    }
}

LaunchTerminal(string) {
    Run("wt")
}
LaunchCommandPalette(string) {
    Send "#!{Space}"
}

KillActiveWindow(string) {
    if WinExist("A") {
        WinKill("A")
    }
}
NukeActiveWindowProcess(string) {
    if WinExist("A") {
        ProcessClose(WinGetPID("A"))
    }
}


; This must be an actual modifier
modifier := "#"


; Virtual workspaces
Hotkey(modifier . "1", MoveOrGoToDesktop0)
Hotkey(modifier . "2", MoveOrGoToDesktop1)
Hotkey(modifier . "3", MoveOrGoToDesktop2)
Hotkey(modifier . "4", MoveOrGoToDesktop3)
Hotkey(modifier . "5", MoveOrGoToDesktop4)
Hotkey(modifier . "6", MoveOrGoToDesktop5)
Hotkey(modifier . "7", MoveOrGoToDesktop6)
Hotkey(modifier . "8", MoveOrGoToDesktop7)
Hotkey(modifier . "9", MoveOrGoToDesktop8)
Hotkey(modifier . "0", MoveOrGoToDesktop9)


; Window manipulation
Hotkey(modifier . "w", MoveActiveWindowTop)
Hotkey(modifier . "a", MoveActiveWindowLeft)
Hotkey(modifier . "s", MoveActiveWindowBottom)
Hotkey(modifier . "d", MoveActiveWindowRight)

; Hotkey(modifier . "q", MoveActiveWindowLeftTop)
; Hotkey(modifier . "e", MoveActiveWindowRightTop)
; Hotkey(modifier . "z", MoveActiveWindowLeftBottom)
; Hotkey(modifier . "c", MoveActiveWindowRightBottom)

Hotkey(modifier . "F", ToggleMaximize)


; Launch
Hotkey(modifier . "Enter", LaunchTerminal)
Hotkey(modifier . "Space", LaunchCommandPalette)

; Close
Hotkey(modifier . "+Q", KillActiveWindow)
Hotkey(modifier . "^+Q", NukeActiveWindowProcess)
