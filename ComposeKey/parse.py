#!/usr/bin/env python

import sys
import re

ComposeToAHK = {
    "0":"0",
    "1":"1",
    "2":"2",
    "3":"3",
    "4":"4",
    "5":"5",
    "6":"6",
    "7":"7",
    "8":"8",
    "9":"9",
    "a":"a",
    "A":"A",
    "apostrophe":"'",
    "asciicircum":"^",
    "asciitilde":"~",
    "asterisk":"*",
    "backslash":"\\",
    "bar":"|",
    "b":"b",
    "B":"B",
    "braceleft":"{",
    "braceright":"}",
    "bracketleft":"[",
    "bracketright":"]",
    "c":"c",
    "C":"C",
    "colon":":",
    "comma":",",
    "d":"d",
    "D":"D",
    "e":"e",
    "E":"E",
    "equal":"=",
    "exclam":"!",
    "f":"f",
    "F":"F",
    "g":"g",
    "G":"G",
    "grave":"``",
    "greater":">",
    "h":"h",
    "H":"H",
    "i":"i",
    "I":"I",
    "j":"j",
    "J":"J",
    "k":"k",
    "K":"K",
    "KP_0":"Numpad0",
    "KP_1":"Numpad1",
    "KP_2":"Numpad2",
    "KP_3":"Numpad3",
    "KP_4":"Numpad4",
    "KP_5":"Numpad5",
    "KP_6":"Numpad6",
    "KP_7":"Numpad7",
    "KP_8":"Numpad8",
    "KP_9":"Numpad9",
    "KP_Add":"NumpadAdd",
    "KP_Divide":"NumpadDiv",
    "leftarrow":"Left",
    "less":"<",
    "l":"l",
    "L":"L",
    "minus":"-",
    "m":"m",
    "M":"M",
    "Multi_key":(),
    "n":"n",
    "N":"N",
    "numbersign":"#",
    "o":"o",
    "O":"O",
    "parenleft":"(",
    "parenright":")",
    "percent":"%",
    "period":".",
    "plus":"+",
    "p":"p",
    "P":"P",
    "q":"q",
    "Q":"Q",
    "question":"?",
    "quotedbl":'`"',
    "rightarrow":"Right",
    "r":"r",
    "R":"R",
    "semicolon":";",
    "slash":"/",
    "space":" ",
    "s":"s",
    "S":"S",
    "t":"t",
    "T":"T",
    "underscore":"_",
    "u":"u",
    "U":"U",
    "v":"v",
    "V":"V",
    "w":"w",
    "W":"W",
    "x":"x",
    "X":"X",
    "y":"y",
    "Y":"Y",
    "z":"z",
    "Z":"Z",
}

# Was used to help make the decoder table but not fully automatic
def printDecoder():
    print("ComposeToAHK = {")
    ind = "  "
    for code in ComposeToAHK:
        if ComposeToAHK[code] is not None:
            print(ind + "\"%s\":\"%s\","%(code,ComposeToAHK[code]))
        elif re.match("^(U[0-9a-fA-F]+|Cyrillic_.*|Greek_.*|hebrew_.*|kana_.*)$", code):
            # ignore some keys not relevant to me
            continue
        elif re.match("^[A-Za-z0-9]$", code):
            print(ind + "\"%s\":\"%s\","%(code,code))
        elif re.match("^KP_[0-9]$", code):
            print(ind + "\"%s\":\"Numpad%s\","%(code, code[3]))
        else:
            # these ones need manual fixing
            print(ind + "\"%s\":None,"%(code))
    print("}")

# We are interested in the sequence of key presses to get to a result.
# Thus, only leaf nodes have a result.
class Node:
    def __init__(self, key, result=None):
        self.key = key
        self.result = result
        self.children = {}

class Trie:
    def __init__(self, limit=0):
        self.root = Node(";-)")
        self.count = 1
        self.limit = limit
    def insert(self, sequence, result):
        node = self.root
        if self.limit and self.count > self.limit:
            return
        for k in sequence:
            if k in node.children:
                node = node.children[k]
            else:
                self.count += 1
                new_node = Node(k)
                node.children[k] = new_node
                node = new_node
        node.result = result

'''
Lines are like:
<Multi_key> <apostrophe> <apostrophe>	: "´"	acute # ACUTE ACCENT
                                           ^
                unicode utf8 char here ---/

A naughty line is:
<Multi_key> <apostrophe><dead_diaeresis> <Greek_upsilon>: "ΰ"	U03B0 # GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND TONOS
                        ^                               ^
      keys touching ---/         no space before colon /

Another naughty line is:
<Multi_key> <space> <space>		: " "	nobreakspace # NO-BREAK SPACE
                                   ^
    whitespace we want to keep ---/

Yet another naughty line is:
<dead_diaeresis> <space>		: "\""	quotedbl # QUOTATION MARK
                                   ^
  backslash escape double quote---/

Yet another another naughty line is:
<Multi_key> <slash> <slash>		: "\\"	backslash # REVERSE SOLIDUS
                                   ^
              backslash escape ---/

'''
def parseComposeFile(istream=sys.stdin, generateDecoder=False, debug=False):
    myTrie = Trie()
    for line in sys.stdin.readlines():
        # only interested in lines with keys
        if not line.startswith("<"):
            continue

        seq = []
        alias = ""
        desc = ""
        key = None

        if debug:
            print(line.strip())

        # Oops, need to handle "QUOTATION MARK" and "REVERSE SOLIDUS" with
        # backslash-escaped keys! Can't split on double quotes. Group 1 match
        # up to colon (ignoring spaces around), ignore optional backslash
        # escape, group 2 unicode character (anything up to the next double
        # quote), ignore closing double quote, rest is group 3 for description.
        lineMatch = re.match(r'^(.*)\s*:\s*"\\?(.+)"\s(.*)[\r\n]?', line)

        # split apart key names, stripping off the angle brackets (note: do not try
        # to keep the angle brackets because there are some lines like this:
        # "<a> <key><anotherkey>"
        seq = re.sub("[><]"," ", lineMatch[1]).split()

        # format unicode in "{U+####}{U+####}..." format
        key = re.sub(r'(....)', r'{U+\1}', lineMatch[2].encode('utf-16-be').hex().upper())

        # collect any aliases (before comment) and the description (comment)
        extra = lineMatch[3].split("#",maxsplit=1)
        if len(extra) > 1:
            alias = extra[0]
            desc = extra[1].strip()

        if debug:
            print(key, seq, alias, desc)

        # we are only interested in compose key sequences (the ones that begin
        # with "<Multi_key>")
        if seq[0] != "Multi_key":
            continue
        seq = seq[1:]

        for item in seq:
            if generateDecoder:
                # add entry to database if not already present
                ComposeToAHK[item] = ComposeToAHK.get(item)
                continue
            elif ComposeToAHK.get(item) is None:
                # ignore keys we dont know how to translate
                key = None
                break

        if key is None:
            continue

        myTrie.insert([ ComposeToAHK[s] for s in seq ], key)

    if generateDecoder:
        printDecoder()
    else:
        return myTrie

# Recurse through tree. Each group of children is a map consisting of a list of
# key-value pairs where the key is always a keypress and the value is either a
# unicode key (leaf node) or another map (more children).
def processNodes(nodes, level=0, pretty=False):
    if pretty:
        kvPairs = ("\n" if (level > 0) else "") + ("  "*level)
    else:
        kvPairs = ""
    for n in nodes:
        if n.result:
            kvPairs += "\"%s\", \"%s\", "%(n.key, n.result)
        else:
            kvPairs += "\"%s\", "%(n.key)
            kvPairs += processNodes(n.children.values(), level=level+1)

    # remove trailing comma
    kvPairs = kvPairs[:-2]

    beginMap = "Map("
    if pretty:
        endMap = ("), " if (level > 0) else "\n)")
    else:
        endMap = ")" + (", " if (level > 0) else "")

    return beginMap + kvPairs + endMap

def testProcessNodes():
    foo = Trie()
    foo.insert(["a", "a"], "|AA|")
    foo.insert(["a", "b"], "|AB|")
    foo.insert(["a", "d", "a" ], "|ADA|")
    foo.insert(["a", "d", "b" ], "|ADB|")
    foo.insert(["z", "a"], "|ZA|")
    foo.insert(["z", "b"], "|ZB|")
    foo.insert(["z", "d", "a" ], "|ZDA|")
    foo.insert(["z", "d", "b" ], "|ZDB|")
    print(processNodes(foo.root.children.values()))

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == "parse":
        print("ComposeKeys := " + processNodes(parseComposeFile().root.children.values()))
    elif len(sys.argv) > 1 and sys.argv[1] == "debug":
        myTrie = parseComposeFile(debug=True)
        print("ComposeKeys := " + processNodes(myTrie.root.children.values()))
    elif len(sys.argv) > 1 and sys.argv[1] == "test":
        testProcessNodes()
    elif len(sys.argv) > 1 and sys.argv[1] == "generateDecoder":
        parseComposeFile(generateDecoder=True)
    else:
        print("usage: %s <parse|test|generateDecoder>"%(sys.argv[0]))
        print("  " + sys.argv[0] + " parse < Compose.pre > ComposeKeyMaps.ahk")
        print("  " + sys.argv[0] + " test")
        print("  " + sys.argv[0] + " generateDecoder")
