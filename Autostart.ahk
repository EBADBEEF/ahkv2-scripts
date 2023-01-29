#Requires AutoHotkey v2.0
#SingleInstance

consoleMsg(str) {
  static DebugConsoleInitialized := 0
  if (DebugConsoleInitialized == 0) {
    DllCall("AllocConsole")
    DebugConsoleInitialized := 1
  }
  FileAppend str, "CONOUT$"
}

; NOTE: Use dbgview64.exe to view OutputDebug messages. Optionally uncomment
; consoleMsg to get a console window with debug prints or MsgBox to get message
; box popups for each message.
;
; Use like msg(Format("hello {:s}", "world")), see AutoHotKey "Format
; Specifiers" help.
msg(text) {
  OutputDebug("AHK|" . text)
  ;consoleMsg(text . "`n")
  ;MsgBox(text)
}

;Use absolute coordinates, required for AltWindowDrag.ahk
CoordMode "Mouse", "Screen"

#include AltWindowDrag.ahk
#include Binds.ahk
#include ComposeKey/ComposeKey.ahk
#include Resolution.ahk
#include ToggleMic.ahk

; ; = comment
; ^ = control
; # = windows key
; + = shift
; ! = alt

CapsLock::Ctrl
^!#Ralt::Capslock
^!+Left::ChangeResolution(3840,2160,120)
^!+Down::ChangeResolution(1920,1080,240)
^!+Right::ChangeResolution(1280,720,360)
^!+Up::MonitorSleep(1)
^!+PgDn::EnumResolutions()
#\::run_terminal()
Media_Next::do_media_key("Media_Next")
Media_Prev::do_media_key("Media_Prev")
Media_Stop::do_media_key("Media_Stop")
Media_Play_Pause::do_media_key("Media_Play_Pause")
^Media_Next::do_media_key("Media_Next", "control")
^Media_Prev::do_media_key("Media_Prev", "control")
^Media_Stop::do_media_key("Media_Stop", "control")
^Media_Play_Pause::do_media_key("Media_Play_Pause", "control")
^Volume_Mute::do_microphone_mute(1)
^Volume_Down::
^Volume_Up::do_microphone_mute(0)
#LButton::AWD_StartAction(0, "LButton") ; Move
#RButton::AWD_StartAction(1, "RButton") ; Resize
RAlt::do_compose_key()
