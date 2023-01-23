#Requires AutoHotkey v2.0
;#NoTrayIcon
#SingleInstance force
#Persistent
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Recommended for catching common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

/* adapted from:
  http://www.autohotkey.com/community/viewtopic.php?t=18711 (TomB: MIDI Output from AHK)
  http://www.autohotkey.com/community/viewtopic.php?t=30715 (orbik: MIDI input library)
  http://www.autohotkey.com/community/viewtopic.php?t=59336 (genmce: Midi Input/Output combined - with System Exclusive!)
  http://oneleaf.heliohost.org/wp/ (genmce's page containing "Generic Midi App 0.6")

  Useful API reference http://home.roadrunner.com/~jgglatt/tech/lowmidi.htm

  mmsystem.h

  ;/*
  ; * UINT midiInOpen(
  ; *   LPHMIDIIN lphMidiIn,
  ; *   UINT uDeviceID,
  ; *   DWORD_PTR dwCallback,
  ; *   DWORD_PTR dwCallbackInstance,
  ; *   DWORD fdwOpen)
  ; */
  ;typedef struct midihdr_tag {
  ;    LPSTR       lpData;
  ;    DWORD       dwBufferLength;
  ;    DWORD       dwBytesRecorded;
  ;    DWORD_PTR   dwUser;
  ;    DWORD       dwFlags;
  ;    struct midihdr_tag *lpNext;
  ;    DWORD_PTR   reserved;
  ;    /* Win 32 extended the structure with these 2 fields */
  ;    DWORD       dwOffset;
  ;    DWORD_PTR   dwReserved[8];
  ;} MIDIHDR, *LPMIDIHDR;
  ;/* UINT midiInPrepareHeader(
  ; *   HMIDIIN hMidiIn,
  ; *   MIDIHDR* lpMidiInHdr,
  ; *   UINT uSize)
  ; */
  ;/* fdwOpen flags,
  ; *   CALLBACK_NULL     0x00000000l
  ; *   CALLBACK_WINDOW   0x00010000l
  ; *   CALLBACK_TASK     0x00020000l
  ; *   CALLBACK_THREAD   (CALLBACK_TASK)
  ; *   CALLBACK_FUNCTION 0x00030000l
  ; *   CALLBACK_EVENT    0x00050000l
  ; *   CALLBACK_TYPEMASK 0x00070000l
  ; */
*/

midi_initdll(LoadNotUnload = 1)
{
  static hModule := 0
  if (LoadNotUnload and hModule) {
    ; do nothing
  } else if (LoadNotUnload and not hModule) {
    hModule := DllCall("LoadLibrary", "Str", "winmm.dll")
    if (not hModule) {
      MsgBox midi_initdll: error, cannot load winmm.dll
      ExitApp 3
    }
  } else {
      DllCall("FreeLibrary", "UInt", hModule)
      hModule := 0
  }
}

midi_exit()
{
  global MidiHandle
  result := DllCall("winmm.dll\midiInReset", "UInt", MidiHandle)
  if (result)
    MsgBox midi_exit: error, midiInReset(%MidiHandle%) = %result%

  result := DllCall("winmm.dll\midiInClose", "UInt", MidiHandle)
  if (result)
    MsgBox midi_exit: error, midiInClose(%MidiHandle%) = %result%

  result := DllCall("winmm.dll\midiInUnprepareHeader", "UInt", MidiHandle, "UIntP", MidiHeader, "UInt", MidiHeaderSize, "UInt")
  if (result)
    MsgBox midi_exit: error, midiInUnprepareHeader(%MidiHandle%) = %result%

  midi_initdll(0)
}

midi_init()
{
  ; Constants
  CALLBACK_WINDOW:=0x10000
  CALLBACK_FUNCTION:=0x30000

  global MidiHandle:=0
  MidiHeader:=0
  MidiHeaderSize:=36
  VarSetCapacity(MidiHeader, MidiHeaderSize, 0)
  MidiBuffer:=0
  MidiBufferSize:=256
  VarSetCapacity(MidiBuffer, MidiBufferSize, 0)
  MidiDeviceID:=0

  ; MidiOpenMode, FUNCTION mode caused me problems :(
  MidiOpenMode:=CALLBACK_WINDOW

  midi_initdll(1)

  if (MidiOpenMode == CALLBACK_FUNCTION) {
    ; (dwCallback)(HMIDIIN handle, UINT uMsg, DWORD dwInstance, DWORD dwParam1, DWORD dwParam2)
    MidiCallback := RegisterCallback("midi_function_callback", "F", 5)
  } else if (MidiOpenMode == CALLBACK_WINDOW) {
    Gui, +LastFound
    MidiCallback := WinExist()
  }

  if (!MidiCallback) {
    MsgBox, failed to register callback (MidiOpenMode=%MidiOpenMode%) (ErrorLevel=%ErrorLevel%)
    ExitApp 1
  }

  result := DllCall("winmm.dll\midiInOpen", "UIntP", MidiHandle , "UInt", MidiDeviceID, "UInt", MidiCallback, "UInt", MidiDeviceID, "UInt", MidiOpenMode, "UInt")
  if (result) {
    MsgBox, midi_open: midiInOpen(%MidiDeviceID%) = %result%
    ExitApp 2
  }

  OnExit(midi_exit)

  NumPut(   &MidiBuffer, MidiHeader,  0, "UInt") ; lpData
  NumPut(MidiBufferSize, MidiHeader,  4, "UInt") ; dwBufferLength

  result := DllCall("winmm.dll\midiInPrepareHeader", "UInt", MidiHandle, "UInt", &MidiHeader, "UInt", MidiHeaderSize, "UInt")
  if (result) {
    MsgBox, midiInPrepareHeader(%MidiDeviceID%) = %result%
    ExitApp 2
  }

  result := DllCall("winmm.dll\midiInAddBuffer", "UInt", MidiHandle, "UInt", &MidiHeader, "UInt", MidiHeaderSize, "UInt")
  if (result) {
    MsgBox, midiInAddBuffer(%MidiDeviceID%) = %result%
    ExitApp 2
  }

  result := DllCall("winmm.dll\midiInStart", "UInt", MidiHandle)
  if (result) {
    MsgBox, midiInStart(%MidiHandle%) = %result%
    ExitApp 2
  }

  if (MidiOpenMode == CALLBACK_WINDOW) {
    ; 0x3C3 == MM_MIM_DATA
    OnMessage(0x3C3, "midi_window_callback")
    ; 0x3C4 == MM_MIM_LONGDATA
    OnMessage(0x3C4, "midi_window_callback_unhandled")
  }
}

piano_to_midi(Note, SemiToneOffset, OctaveNr)
{
  ; A0 == 21, C8 == 108
  ; SemiToneOffset  > 0 => sharp
  ; SemiToneOffset  < 0 => flat
  ; SemiToneOffset == 0 => no modification

  MidiNote = 21 + SemiToneOffset
  if (Note=="A") {
    MidiNote += 0
  } else if (Note=="B") {
    MidiNote += 2
  } else if (Note=="C") {
    MidiNote += 3
  } else if (Note=="D") {
    MidiNote += 5
  } else if (Note=="E") {
    MidiNote += 7
  } else if (Note=="F") {
    MidiNote += 8
  } else if (Note=="G") {
    MidiNote += 10
  }
  if(OctaveNr > 1)
    MidiNote += 12*(OctaveNr-1)

  return MidiNote
}

midi_window_callback_unhandled(wParam, lParam, msg, hwnd)
{
  MsgBox unhandled midi window callback
  return 0
}

my_pdf_control(action, count)
{
  IfWinNotExist, ahk_class SUMATRA_PDF_FRAME
    return

  WinActivate

  if (action == "pageturn") {
    if(count > 0)
      Send {Right}
    else
      Send {Left}
  }
}

midi_window_callback(wParam, lParam, msg, hwnd)
{
  static CommandKey := piano_to_midi("A", 0, 0)
  static in_command := 0

  status := (lParam >>  0) & 0xff
  data1  := (lParam >>  8) & 0xff
  data2  := (lParam >> 16) & 0xff

  ; we are only interesting in note_on and note_off
  if (!(status & 0x80))
    return 0

  is_note_on := ((status & 0x90) == 0x90)

  if (data1 == CommandKey) {
    in_command:=is_note_on
  } else if (in_command && is_note_on) {
    if (data1 == 108)
      my_pdf_control("pageturn", 1)
    else if (data1 == 107)
      my_pdf_control("pageturn", -1)
  }
  return 0
}

; (dwCallback)(HMIDIIN handle, UINT uMsg, DWORD dwInstance, DWORD dwParam1, DWORD dwParam2)
midi_function_callback(handle, Msg, Instance, Param1, Param2)
{
  static LastNoteOn := 0
  ; handle note_on only
  if ((Msg == 0x3C3) && (Param1 & 0x80) && (Param1 & 0x10)) {
    note := (Param1 >> 8) & 0xff
    if(LastNoteOn == 108 && note == 21) {
      my_pdf_control(-1)
    } else if (LastNoteOn == 21 && note == 108) {
      my_pdf_control(1)
    } else {
      ; allow repeated commands, do not save LastNoteOn when in command
      LastNoteOn := note
    }
  }
}
