do_media_key(key:="", modif:="") {
  ;SetTitleMatchMode, RegEx
  if WinExist("ahk_exe mpc-hc64.exe") {
    if (key == "Media_Next" && modif == "") {
      ControlSend "{PgDn}"
    } else if (key == "Media_Prev" && modif == "") {
      ControlSend "{PgUp}"
    } else if (key == "Media_Stop" && modif == "") {
      ControlSend "{.}"
    } else if (key == "Media_Play_Pause" && modif == "") {
      ControlSend "{Space}"
    }
    return
  }
  if WinExist("ahk_exe vlc.exe") {
    if (key == "Media_Next" && modif == "") {
      ControlSend "{n}"
    } else if (key == "Media_Prev" && modif == "") {
      ControlSend "{p}"
    } else if (key == "Media_Stop" && modif == "") {
      ControlSend "{s}"
    } else if (key == "Media_Play_Pause" && modif == "") {
      ControlSend "{Space}"
    }
    return
  }
  ; if WinExist("ahk_class Winamp.v.*") {
  if WinExist("ahk_class Winamp v1.x") {
    title := WinGetTitle()
    if (key == "Media_Next" && modif == "") {
      ControlSend "{b}"
    } else if (key == "Media_Prev" && modif == "") {
      ControlSend "{z}"
    } else if (key == "Media_Stop" && modif == "") {
      ControlSend "{v}"
    } else if (key == "Media_Play_Pause" && modif == "") {
      if (InStr(title, "[Stopped]")) {
        ControlSend "{x}"
      } else if (InStr(title, "[Paused]")) {
        ControlSend "{c}"
      } else if (SubStr(title,1,6) == "Winamp") {
        ControlSend "{x}"
      } else {
        ControlSend "{c}"
      }
    }
    return
  }
  if ProcessExist("foobar2000.exe") {
    fbexe := "C:\Program Files (x86)\foobar2000\foobar2000.exe "
    if (key == "Media_Next" && modif == "") {
      Run fbexe "/next"
    } if (key == "Media_Next" && modif == "control") {
      Run fbexe "/rand"
    } else if (key == "Media_Prev" && modif == "") {
      Run fbexe "/prev"
    } else if (key == "Media_Stop" && modif == "") {
      Run fbexe "/stop"
    } else if (key == "Media_Play_Pause" && modif == "") {
      Run fbexe "/playpause"
    }
    return
  }
  if WinExist("ahk_exe Spotify.exe") {
    if (key == "Media_Next" && modif == "") {
      ControlSend "{ctrl}{right}"
    } else if (key == "Media_Prev" && modif == "") {
      ControlSend "{ctrl}{left}"
    } else if (key == "Media_Stop" && modif == "") {
      ;ControlSend "{s}"
    } else if (key == "Media_Play_Pause" && modif == "") {
      ControlSend "{Space}"
    }
    return
  }
}

run_terminal() {
  if WinExist("ahk_exe WindowsTerminal.exe") {
    WinActivate
  } else {
    Run "wt.exe"
  }
}
