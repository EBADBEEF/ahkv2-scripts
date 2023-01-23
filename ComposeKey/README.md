AutoHotKey v2.0 script to handle compose key sequences. Also contains a script
to parse the Xorg Compose Key database and generate a data structure used by
the ComposeKey.ahk script to handle compose key sequences (nested maps).

Use an autohotkey bind like:
```
#include ComposeKey.ahk
RAlt::do_compose_key()
```

And assuming right alt is your compose key, here are some example sequences:
```
<RAlt> <?> <?> = ¿
<RAlt> <e> <'> = é
<RAlt> <'> <e> = é
<RAlt> <,> <c> = ç
<RAlt> <"> <u> = ü
```

License for the Compose.pre file is Xorg MIT style license. Taken from
[here](https://github.com/freedesktop/xorg-libX11/blob/d6d6cba90215d323567fef13d6565756c9956f60/nls/en_US.UTF-8/Compose.pre).
