#Requires AutoHotkey v2.0
#SingleInstance

; ./parse.py parse < Compose.pre > ComposeKeyMaps.ahk
; ComposeKey := Map(...)
#include "ComposeKeyMaps.ahk"

do_compose_key() {
  ; Max sequence is four key presses
  ih := InputHook("L4 I101 T4", "{Escape}{Enter}")
  ;msg("START")
  ih.OnChar := KeyDown
  KeyDown(ih)
  ih.Start()
  ih.Wait()
  if (ih.EndReason == "Max") {
    ; the last key does not get sent to callback, so pump it here
    KeyDown(ih, SubStr(ih.Input, 4))
  } else {
    ; reset callback parser
    KeyDown(ih)
  }
  ;msg("DONE")
}

KeyDown(ih, char:="") {
  static node := ComposeKeys
  if (char = "") {
    node := ComposeKeys
    return
  }
  ;msg(Format("got key {:s} (full input {:s})", char, ih.Input))
  if node.Has(char) {
    node := node[char]
    if (Type(node) == "String") {
      ;msg(Format("we are done {:s}",node))
      Send node
      node := ComposeKeys
      ih.Stop()
    }
  } else {
    ; give up because key not found
    Send ih.Input
    ih.Stop()
  }
}
