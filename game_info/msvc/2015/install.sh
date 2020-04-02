#!/bin/sh

[ -z "$WINEPREFIX" ] && echo "WINEPREFIX not set" && exit 1

set -e

overrideDll() {
  wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v $1 /d native /f
}

scriptdir=$(dirname "$0")
cd "$scriptdir"

cp -v syswow64/* "$WINEPREFIX/drive_c/windows/syswow64"
cp -v system32/* "$WINEPREFIX/drive_c/windows/system32"

overrideDll "mfc140"
overrideDll "mfc140chs"
overrideDll "mfc140cht"
overrideDll "mfc140deu"
overrideDll "mfc140enu"
overrideDll "mfc140esn"
overrideDll "mfc140fra"
overrideDll "mfc140ita"
overrideDll "mfc140jpn"
overrideDll "mfc140kor"
overrideDll "mfc140u"
overrideDll "mfcm140"
overrideDll "mfcm140u"

export WINEDEBUG="-all"
