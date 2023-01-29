; Needs absolute coordinates (CoordMode "Mouse", "Screen")

AWD_StartAction(resize, button) {
  global
  MouseGetPos &AWD_MX0, &AWD_MY0, &AWD_Window
  AWD_Maximized := WinGetMinMax(AWD_Window)
  if (AWD_Maximized = 0)
  {
    AWD_InResize := resize
    AWD_Button := button

    ; save original dimensions of window
    WinGetPos &AWD_X0, &AWD_Y0, &AWD_W0, &AWD_H0, AWD_Window

    ; TODO: check to make sure we are not moving/resizing the explorer desktop
    ; or start menu

    if (AWD_InResize) {
      if (AWD_MX0 >= (AWD_X0+(ceil(AWD_W0/2)))) {
        ; width grows to the right, x is fixed
        AWD_ResizeW := 1
        AWD_ResizeX := 0
      } else {
        ; width fixed, x grows to the left
        AWD_ResizeW := -1
        AWD_ResizeX := 1
      }
      if (AWD_MY0 >= (AWD_Y0+(ceil(AWD_H0/2)))) {
        ; height grows down, y is fixed
        AWD_ResizeH := 1
        AWD_ResizeY := 0
      } else {
        ; height fixed, y grows up
        AWD_ResizeH := -1
        AWD_ResizeY := 1
      }
    }
    ; Run watch subroutine once (as a timer thread)
    SetTimer AWD_WatchMouse, -1
  }
  return
}

; Timer subroutine. Keep checking mouse position at monitor refresh rate (by
; using DwmFlush). First, check to see if we are done. Using a normal timer we
; can't go fast enough to match high refresh rate monitors.  cleanup. Otherwise,
; update the window based on mouse location.
AWD_WatchMouse() {
  global
  SetWinDelay 0
  while(1) {
    if (!GetKeyState(AWD_Button, "P")) {
      return
    }
    MouseGetPos &AWD_MX, &AWD_MY
    local delta_x := (AWD_MX - AWD_MX0)
    local delta_y := (AWD_MY - AWD_MY0)
    if (AWD_InResize = 1) {
      local x := (AWD_ResizeX*delta_x) + AWD_X0
      local y := (AWD_ResizeY*delta_y) + AWD_Y0
      local w := (AWD_ResizeW*delta_x) + AWD_W0
      local h := (AWD_ResizeH*delta_y) + AWD_H0
      WinMove x, y, w, h, "ahk_id" AWD_Window
    } else {
      local x := delta_x + AWD_X0
      local y := delta_y + AWD_Y0
      WinMove x,y,,,"ahk_id" AWD_Window
    }
    if (DllCall("dwmapi.dll\DwmFlush")) {
      Sleep(0)
    }
  }
}
