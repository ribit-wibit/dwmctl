# dwmctl
This is for Desktop Window Manager for Windows, not to be confused with Dynamic Window Manager for the X Window System developed by Suckless.

A lightweight AutoHotKey v2.0 script for Desktop Window Manager to map key combinations to actions such as moving windows, switching virtual desktops, launching programs, etc.. without invading on the basic functions of DWM.

Based on [AutoHotkey V2 example.ah2](https://github.com/Ciantic/VirtualDesktopAccessor/blob/rust/example.ah2) from [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor). Inspired by i3, sway and Hyprland.

## Notes
If you'd like to remap a certain key (e.g. CapsLock) to a modifier key (e.g. Win), using AutohotKey remapping may be unable to create the function you need (combo order issues, repeated presses not working without full release). The best way I've found to do this is through registery editing, either manually or through a tool such as [SharpKeys](https://github.com/randyrants/sharpkeys).

## Features
- Move between virtual desktops
- Move and resize windows across screen (using PowerToys FancyZones)
- Close window, kill active window process
- Launch app (Command Palette, Terminal, etc.)
- Active virtual desktop number as tray icon

## Future features
- ..?

## External Dependencies
- [AutoHotkey v2.0 (AHKv2)](https://www.autohotkey.com/)
- [PowerToys](https://github.com/microsoft/PowerToys)

## Internal Dependencies
- [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor)
