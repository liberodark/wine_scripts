#!/bin/bash

## Wine executables
WINE="${DIR}/wine/bin/wine"
WINE64="${DIR}/wine/bin/wine64"

check_env() {
    [ -z "$1" ] && echo "$2 is not set" && exit 1
}

check_sanity() {
    [ ! -d "$1/$2" ] && echo "$1 isn't a valid path" && exit 1
}

override_dll() {
    "${WINE}" reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v $1 /d native /f
}

check_env "$WINEPREFIX" WINEPREFIX
check_sanity "$WINEPREFIX" drive_c

set -e
export WINEDEBUG="-all"

scriptdir="$(dirname "$(realpath "$0")")"
cd "$scriptdir"

cp -vf --remove-destination syswow64/* "$WINEPREFIX/drive_c/windows/syswow64"
cp -vf --remove-destination system32/* "$WINEPREFIX/drive_c/windows/system32"

override_dll "colorcnv"
override_dll "mf"
override_dll "mferror"
override_dll "mfplat"
override_dll "mfplay"
override_dll "mfreadwrite"
override_dll "msmpeg2adec"
override_dll "msmpeg2vdec"
override_dll "sqmapi"

"${WINE}" regedit.exe mf.reg
"${WINE}" regedit.exe wmf.reg

"${WINE64}" regedit.exe mf.reg
"${WINE64}" regedit.exe wmf.reg

"${WINE}" regsvr32 colorcnv.dll
"${WINE}" regsvr32 msmpeg2adec.dll
"${WINE}" regsvr32 msmpeg2vdec.dll

"${WINE64}" regsvr32 colorcnv.dll
"${WINE64}" regsvr32 msmpeg2adec.dll
"${WINE64}" regsvr32 msmpeg2vdec.dll

