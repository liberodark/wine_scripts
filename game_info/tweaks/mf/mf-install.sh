#!/bin/bash

## Wine executables
WINE="${DIR}/wine/bin/wine"
WINE64="${DIR}/wine/bin/wine64"

[ -z "$WINEPREFIX" ] && echo "WINEPREFIX not set" && exit 1

set -e

overrideDll() {
  "${WINE}" reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v $1 /d native /f
}

scriptdir=$(dirname "$0")
cd "$scriptdir"

cp -v syswow64/* "$WINEPREFIX/drive_c/windows/syswow64"
cp -v system32/* "$WINEPREFIX/drive_c/windows/system32"

overrideDll "mf"
overrideDll "mferror"
overrideDll "mfplat"
overrideDll "mfplay"
overrideDll "mfreadwrite"
overrideDll "msmpeg2adec"
overrideDll "msmpeg2vdec"
overrideDll "sqmapi"

export WINEDEBUG="-all"

"${WINE}" start regedit.exe mf.reg
"${WINE}" start regedit.exe wmf.reg
"${WINE64}" start regedit.exe mf.reg
"${WINE64}" start regedit.exe wmf.reg

"${WINE64}" regsvr32 msmpeg2vdec.dll
"${WINE64}" regsvr32 msmpeg2adec.dll
"${WINE64}" regsvr32 colorcnv.dll

"${WINE}" regsvr32 msmpeg2vdec.dll
"${WINE}" regsvr32 msmpeg2adec.dll
"${WINE}" regsvr32 colorcnv.dll
