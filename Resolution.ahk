sizeof_DEVMODE := 156
off_dmSize := 36
off_dmFields := off_dmSize + 4
off_dmBitsPerPel := 104
off_dmPelsWidth := off_dmBitsPerPel + 4
off_dmPelsHeight := off_dmPelsWidth + 4
off_dmDisplayFrequency := off_dmPelsHeight + 8

ChangeResolution(width,height,refresh_hz:=60,colorDepth_bit:=32)
{
  DEVMODE := Buffer(sizeof_DEVMODE)
  NumPut "UShort", sizeof_DEVMODE, DEVMODE, off_dmSize
  ret:=DllCall("EnumDisplaySettingsA", "UInt", 0, "UInt", -1, "UInt", DEVMODE.ptr)

  ; dmFields = DM_BITSPERPEL | DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY
  NumPut("UInt",     0x005c0000, DEVMODE, off_dmFields)
  NumPut("UInt", colorDepth_bit, DEVMODE, off_dmBitsPerPel)
  NumPut("Uint",          width, DEVMODE, off_dmPelsWidth)
  NumPut("Uint",         height, DEVMODE, off_dmPelsHeight)
  NumPut("Uint",     refresh_hz, DEVMODE, off_dmDisplayFrequency)
  ret:=DllCall("ChangeDisplaySettingsA", "UInt", DEVMODE.ptr, "UInt", 0)

  Return ret
}

EnumResolutions() {
  i := 0
  while (1) {
    DEVMODE := Buffer(sizeof_DEVMODE)
    NumPut "UShort", sizeof_DEVMODE, DEVMODE, off_dmSize
    ret:=DllCall("EnumDisplaySettingsA", "UInt", 0, "UInt", i, "UInt", DEVMODE.ptr)
    if (ret <= 0)
      break
    colorDepth_bit := NumGet(DEVMODE, off_dmBitsPerPel,      "UInt")
    width          := NumGet(DEVMODE, off_dmPelsWidth,       "UInt")
    height         := NumGet(DEVMODE, off_dmPelsHeight,      "UInt")
    refresh_hz     := NumGet(DEVMODE, off_dmDisplayFrequency,"UInt")
    msg("Mode " i " = " width "x" height "@" refresh_hz "Hz " colorDepth_bit)
    i+=1
  }
}

MonitorSleep(goToSleep) {
  WM_SYSCOMMAND := 0x0112
  SC_MONITORPOWER := 0xF170
  HWND_BROADCAST := 0xFFFF
  PostMessage WM_SYSCOMMAND, SC_MONITORPOWER, goToSleep?2:-1, HWND_BROADCAST
}

