#!/bin/bash
#
# About: Wine Portable start script
# Author: Kron, liberodark
# Thanks :
# License: GNU GPLv3
### Link to latest version:
# Mega: https://mega.nz/folder/ZZUV1K7J#kIenmTQoi0if-SAcMSuAHA
# Github: https://github.com/liberodark/wine_scripts

version="1.5.1"

echo "Welcome on Wine Portable Script $version"

## Exit if root

if [[ "$EUID" = 0 ]]
  then echo "Do not run this script as root!"
  exit
fi

# Uncompress Wine
if [ -e "wine.tar.xz" ]; then
tar -xvf wine.tar.xz && rm -f wine.tar.xz
fi

## Show help

if [ "$1" == "--help" ]; then
	clear
	echo -e "Available arguments:\n"
	echo -e "--debug\t\t\t\tenable Debug mode to see more information"
	echo -e "\t\t\t\tin output when the game starts."
	exit
fi

### Set variables

## Script directory

SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
export SCRIPT
DIR="$(dirname "$SCRIPT")"
export DIR

## Wine executables

WINE="${DIR}/wine/bin/wine"
WINE64="${DIR}/wine/bin/wine64"
WINESERVER="${DIR}/wine/bin/wineserver"
MSIEXEC="${DIR}/wine/bin/msiexec"

## Wine variables

export WINEPREFIX="${DIR}/prefix"
export WINEDEBUG="-all"
export WINEDLLOVERRIDES="winemenubuilder.exe="

# Enable WINEDEBUG if --debug argument is passed to script
if [ "$1" = "--debug" ]; then export WINEDEBUG="err+all,fixme-all"; fi

## Other variables

export XDG_CACHE_HOME="${DIR}/cache"
export DXVK_LOG_PATH="${DIR}/cache/dxvk"
export DXVK_STATE_CACHE_PATH="${DIR}/cache/dxvk"

GAMEMODE_RUN="$(command -v gamemoderun)"
USERNAME="$(id -un)"

## Script variables

# Get settings (variables) from settings file if exists
SCRIPT_NAME="$(basename "$SCRIPT" | cut -d. -f1)"
# shellcheck disable=SC1091
source "${DIR}/settings_run" &>/dev/null

# Generate settings file if it's not exists or incomplete
if [ -z "${CSMT_DISABLE}" ] || [ -z "${DXVK}" ] || [ -z "${USE_PULSEAUDIO}" ] || [ -z "${PBA}" ] || [ -z "${GLIBC_REQUIRED}" ]; then
cat << EOF > "${DIR}/settings_run"
CSMT_DISABLE=0
USE_PULSEAUDIO=1
USE_SYSTEM_WINE=0
RESTORE_RESOLUTION=1
VIRTUAL_DESKTOP=0
VIRTUAL_DESKTOP_SIZE=800x600

GAME_USER=liberodark
GAME_LANG=english

DXVK=1
DXVK_HUD=0
MANGOHUD=0
DXVK_HDR=0
DXVK_FRAME_RATE=0
ESYNC=1
FSYNC=1
PBA=0
FSR=0
NVAPI=0
GAMEMODE=0
MF=0
MSVC=0
GDIPLUS=0
COREFONT=0
NO_OPWR=0
LARGE_ADDRESS_AWARE=0
HIDE_NVIDIA_GPU=0
VKBASALT=0

WINDOWS_VERSION=win10
PREFIX_ARCH=win64

# Change these GLIBC variables only if you know what you're doing

CHECK_GLIBC=1
GLIBC_REQUIRED=2.23

# You can also put custom variables in this file
EOF
		# shellcheck disable=SC1091
	source "${DIR}/settings_run"
fi

export DXVK_HUD
export MANGOHUD
export DXVK_HDR
export DXVK_FRAME_RATE
export WINEESYNC=${ESYNC}
export WINEFSYNC=${FSYNC}
export WINE_DISABLE_VULKAN_OPWR=${NO_OPWR}
export PBA_ENABLE=${PBA}
export WINE_FULLSCREEN_FSR=${FSR}
#export WINE_FULLSCREEN_FSR_STRENGTH=2
#export WINE_FULLSCREEN_FSR_MODE=ultra
export WINEARCH=${PREFIX_ARCH}
export WINE_LARGE_ADDRESS_AWARE=${LARGE_ADDRESS_AWARE}
export WINE_HIDE_NVIDIA_GPU=${HIDE_NVIDIA_GPU}
export ENABLE_VKBASALT=${VKBASALT}
export GAME_USER=${GAME_USER}
export GAME_LANG=${GAME_LANG}

# Enable virtual desktop if VIRTUAL_DESKTOP env is set to 1
if [ "${VIRTUAL_DESKTOP}" = 1 ]; then
	VDESKTOP="explorer /desktop=Wine,$VIRTUAL_DESKTOP_SIZE"
fi

# Get current screen resolution
if [ "${RESTORE_RESOLUTION}" = 1 ]; then
	RESOLUTION="$(xrandr -q | sed -n -e 's/.* connected primary \([^ +]*\).*/\1/p')"
	OUTPUT="$(xrandr -q | sed -n -e 's/\([^ ]*\) connected primary.*/\1/p')"
fi

# Make Wine binaries executable
if [ -d "${DIR}/wine" ] && [ ! -x "${DIR}/wine/bin/wine" ]; then
	chmod -R 700 "${DIR}/wine"
fi

# Use system Wine if GLIBC checking is enabled and GLIBC is older than required
if [ "$USE_SYSTEM_WINE" = 0 ] && [ "$CHECK_GLIBC" = 1 ]; then
	GLIBC_VERSION="$(ldd --version | head -n1 | sed 's/\(.*\) //g' | sed 's/\.[^.]*//2g')"

	if [ "$(echo "${GLIBC_VERSION//./}")" -lt "$(echo "${GLIBC_REQUIRED//./}")" ]; then
		USE_SYSTEM_WINE=1
		OLD_GLIBC=1
	fi
fi

# Use system Wine if needed
if [ ! -f "$WINE" ] || [ $USE_SYSTEM_WINE = 1 ]; then
	if command -v wine-development &>/dev/null; then
		WINE=wine-development
		WINE64=wine64-development
		WINESERVER=wineserver-development
	else
		WINE=wine
		WINE64=wine64
		WINESERVER=wineserver
	fi

	USE_SYSTEM_WINE=1
fi

# Check WINEARCH variable and system architecture
if [ "$WINEARCH" = "win64" ] && ! "$WINE64" --version &>/dev/null; then
		echo "WINEARCH is set to win64."
		echo "But seems like your Wine or your system is 32-bit."
		echo "Use 64-bit Wine or set WINEARCH to win32."

		if [ "$(uname -m)" != "x86_64" ]; then
			echo -e "\nYour system is 32-bit!"
		fi

		exit
elif [ "$WINEARCH" = "win32" ] && [ $USE_SYSTEM_WINE = 0 ]; then
	if [ "$(basename "$(readlink -f "$WINE")")" = "wine64" ]; then
		echo "WINEARCH is set to win32."
		echo "But seems like your Wine is pure 64-bit without multilib support."
		echo "Use multilib (or 32-bit) Wine or set WINEARCH to win64."

		exit
	fi
fi

# Check if Wine has PBA or ESYNC features
mkdir -p "${DIR}/.temp_files"
if [ ! -f "${DIR}/.temp_files/pba_status" ]; then
	if grep PBA "${DIR}/wine/lib/wine/wined3d.dll.so" &>/dev/null || grep PBA "${DIR}/wine/lib64/wine/wined3d.dll.so" &>/dev/null; then
		echo "yes" > "${DIR}/.temp_files/pba_status"
	else
		echo "no" > "${DIR}/.temp_files/pba_status"
	fi
fi

if [ ! -f "${DIR}/.temp_files/esync_status" ]; then
	if grep ESYNC "${DIR}/wine/lib/wine/ntdll.dll.so" &>/dev/null || grep ESYNC "${DIR}/wine/lib64/wine/ntdll.dll.so" &>/dev/null; then
		echo "yes" > "${DIR}/.temp_files/esync_status"
	else
		echo "no" > "${DIR}/.temp_files/esync_status"
	fi
fi

if [ "$(cat "${DIR}/.temp_files/pba_status")" = "no" ] || [ $USE_SYSTEM_WINE = 1 ]; then
	NO_PBA_FOUND=1
else NO_PBA_FOUND=0; fi

if [ "$(cat "${DIR}/.temp_files/esync_status")" = "no" ] || [ $USE_SYSTEM_WINE = 1 ]; then
	NO_ESYNC_FOUND=1
else NO_ESYNC_FOUND=0; fi

# Disable ESYNC if ulimit fails
ESYNC_FORCE_OFF=0
if [ "$NO_ESYNC_FOUND" = 0 ] && [ "$WINEESYNC" = 1 ]; then
	if ! ulimit -n 500000 &>/dev/null; then
		export WINEESYNC=0
		ESYNC_FORCE_OFF=1
	fi
fi

## Game-specific variables

# Use game_info_SCRIPTNAME.txt file if exists
if [ -f "${DIR}/game_info/game_info_$SCRIPT_NAME.txt" ]; then
	GAME_INFO="$(cat "${DIR}/game_info/game_info_$SCRIPT_NAME.txt")"
else
	GAME_INFO="$(cat "${DIR}/game_info/game_info.txt")"
fi

GAME="$(echo "${GAME_INFO}" | sed -n 6p)"
VERSION="$(echo "${GAME_INFO}" | sed -n 2p)"
GAME_PATH="${WINEPREFIX}/drive_c/$(echo "${GAME_INFO}" | sed -n 1p)"
EXE="$(echo "${GAME_INFO}" | sed -n 3p)"
ARGS="$(echo "${GAME_INFO}" | sed -n 4p)"

for arg in "$@"; do
	if [ "$arg" != "--debug" ]; then
		ARGS="$ARGS $arg"
	fi
done

### Prepare for launching game

## Exit if there is no Wine

WINE_VERSION="$("$WINE" --version)"
if [ ! "$WINE_VERSION" ]; then
	clear
	echo "There is no Wine available in your system!"
	exit
fi

## Exit if there is no game_info.txt file

if [ ! "${GAME_INFO}" ]; then
	clear
	echo "There is no game_info.txt file!"
	exit
fi

## Exit if user have no write permission on directory

if ! touch "${DIR}/write_test"; then
	clear
	echo "You have no write permissions on this directory!"
	echo
	echo "You can make directory writable by everyone with this command:"
	echo
	echo "chmod 777 DIRNAME"
	exit
fi
rm -f "${DIR}/write_test"

## Change working directory

cd "${DIR}" || exit

## Setup prefix

if [ ! -d prefix ] || [ "$USERNAME" != "$(cat .temp_files/lastuser)" ] || [ "$WINE_VERSION" != "$(cat .temp_files/lastwine)" ]; then
	# Move old prefix just in case
	mv prefix "prefix_$(date '+%d.%m_%H:%M:%S')" &>/dev/null

	# Remove .temp_files directory
	rm -rf .temp_files

	# Create prefix
	echo "Creating prefix, please wait."
	echo

	export WINEDLLOVERRIDES="${WINEDLLOVERRIDES};mscoree,mshtml="
	"$WINE" wineboot &>/dev/null
	"$WINESERVER" -w
	export WINEDLLOVERRIDES="winemenubuilder.exe="

	# Create symlink to game directory
	mkdir -p "${GAME_PATH}"; rm -rf "${GAME_PATH}"
	ln -sfr game_info/data "${GAME_PATH}"

	# Execute files in game_info/msi directory
	if [ -d game_info/msi ]; then
		echo "Executing files"

		for file in game_info/msi/*.msi; do
			echo "Executing file $file"

			"$MSIEXEC" -i "$file" /quiet /qn /norestart &>/dev/null
			"$WINESERVER" -w
		done
	fi

	# Execute files in game_info/exe directory
	if [ -d game_info/exe ]; then
		echo "Executing files"

		for file in game_info/exe/*.exe; do
			echo "Executing file $file"

		case "$file" in

  		"game_info/exe/DXSETUP.exe" | "game_info/exe/dxsetup.exe")
			"$WINE" start "$file" /silent &>/dev/null
			"$WINESERVER" -w
			;;

		"game_info/exe/vcredist_x64_2005.exe" | "game_info/exe/vcredist_x86_2005.exe")
			"$WINE" start "$file" /q &>/dev/null
			"$WINESERVER" -w
			;;

  		"game_info/exe/vcredist_x64_2008.exe" | "game_info/exe/vcredist_x86_2008.exe")
			"$WINE" start "$file" /quiet /qn /norestart &>/dev/null
			"$WINESERVER" -w
			;;

  		"game_info/exe/vcredist_x64_2010.exe" | "game_info/exe/vcredist_x86_2010.exe")
			"$WINE" start "$file" /quiet /qn /norestart &>/dev/null
			"$WINESERVER" -w
			;;

		"game_info/exe/vcredist_x64_2012.exe" | "game_info/exe/vcredist_x86_2012.exe")
			"$WINE" start "$file" /quiet /qn /norestart &>/dev/null
			"$WINESERVER" -w
			;;

		"game_info/exe/vcredist_x64_2013.exe" | "game_info/exe/vcredist_x86_2013.exe")
			"$WINE" start "$file" /quiet /qn /norestart &>/dev/null
			"$WINESERVER" -w
			;;

		"game_info/exe/vcredist_x64_2015.exe" | "game_info/exe/vcredist_x86_2015.exe")
			"$WINE" start "$file" /quiet /qn /norestart &>/dev/null
			"$WINESERVER" -w
			;;

		"game_info/exe/vcredist_x64_2017.exe" | "game_info/exe/vcredist_x86_2017.exe")
			"$WINE" start "$file" /quiet /qn /norestart &>/dev/null
			"$WINESERVER" -w
			;;

		"game_info/exe/vcredist_x64_2019.exe" | "game_info/exe/vcredist_x86_2019.exe")
			"$WINE" start "$file" /quiet /qn /norestart &>/dev/null
			"$WINESERVER" -w
			;;

		"game_info/exe/vcredist_x64_2015_2019.exe" | "game_info/exe/vcredist_x86_2015_2019.exe")
			"$WINE" start "$file" /quiet /qn /norestart &>/dev/null
			"$WINESERVER" -w
			;;

		"game_info/exe/vcredist_x64_2015_2022.exe" | "game_info/exe/vcredist_x86_2015_2022.exe")
			"$WINE" start "$file" /quiet /qn /norestart &>/dev/null
			"$WINESERVER" -w
			;;

		"game_info/exe/oalinst.exe")
			"$WINE" start "$file" /s &>/dev/null
			"$WINESERVER" -w
			;;

  		*)
			"$WINE" start "$file" &>/dev/null
			"$WINESERVER" -w
			;;
		esac
		done
	fi

	# Apply reg files
	if [ -d game_info/regs ]; then
		echo "Importing registry files"

		for file in game_info/regs/*.reg; do
			echo "Importing $file"

			"$WINE" regedit "$file" &>/dev/null
			"$WINE64" regedit "$file" &>/dev/null
		done
	fi

	# Symlink requeired dlls, override and register them
	if [ -d game_info/dlls ]; then
		echo "Symlinking and registering dlls"

		echo -e "Windows Registry Editor Version 5.00\n" > dlloverrides.reg
		echo -e "[HKEY_CURRENT_USER\Software\Wine\DllOverrides]" >> dlloverrides.reg

		find game_info/dlls -type f -name "*.dll" | while read x; do
		dll_name=$(basename "$x")
		case "$dll_name" in
			d3d8.dll|d3d9.dll|d3d10core.dll|d3d11.dll|d3d12core.dll|d3d12.dll|dxgi.dll|nvapi.dll|nvapi64.dll|nvofapi64.dll)
				#echo "Skipping registration for $dll_name"
				# Create symlink and add DLL override to the registry without registration
				ln -sfr "$x" "${WINEPREFIX}/drive_c/windows/system32/$(basename $x)"
				echo -e '"'$(basename $x .dll)'"="native"' >> dlloverrides.reg
				continue
				;;
		esac

		echo "Creating symlink to $x"

		ln -sfr "$x" "${WINEPREFIX}/drive_c/windows/system32"

		# Do not override component if required
		echo -e '"'$(basename $x .dll)'"="native"' >> dlloverrides.reg

		# Register component with regsvr32
		echo "Registering $(basename $x)"

		"$WINE" regsvr32 "$(basename $x)" &>/dev/null
		"$WINE64" regsvr32 "$(basename $x)" &>/dev/null
	done

		echo "Overriding dlls"

		"$WINE" regedit dlloverrides.reg &>/dev/null
		"$WINE64" regedit dlloverrides.reg &>/dev/null

		rm -f dlloverrides.reg
	fi

	# Make documents directory
	echo "Sandboxing prefix"

	# Valve's Proton uses steamuser as username
	if [ -d "${WINEPREFIX}/drive_c/users/steamuser" ]; then
		USERNAME=steamuser
	fi

	if [ ! -d "${DIR}/documents" ]; then
		mv "${WINEPREFIX}/drive_c/users/$USERNAME" "${DIR}/documents" &>/dev/null
		mv "${WINEPREFIX}/drive_c/users/Public" "${DIR}/documents/Public"
	fi
	rm -rf "${WINEPREFIX}/drive_c/users/$USERNAME"
	rm -rf "${WINEPREFIX}/drive_c/users/Public"
	ln -sfr "${DIR}/documents" "${WINEPREFIX}/drive_c/users/$USERNAME"
	ln -sfr "${DIR}/documents/Public" "${WINEPREFIX}/drive_c/users/Public"
	ln -sfr "${DIR}/documents" "${WINEPREFIX}/drive_c/users/user"

	# Sandbox the prefix; Borrowed from winetricks scripts
	rm -f "${WINEPREFIX}/dosdevices/z:"
	ln -sfr "${DIR}" "${WINEPREFIX}/dosdevices/k:"

	if cd "${WINEPREFIX}/drive_c/users/$USERNAME"; then
		# Use one directory for all symlinks
		# This is necessary for multilocale compatibility
		mkdir -p Documents_Multilocale

		echo "Documents_Multilocale directory is for compatibility with different languages." > Documents_Multilocale/readme.txt
		echo "Put all files into Documents_Multilocale instead of specific directories like My Documents etc." >> Documents_Multilocale/readme.txt

		if [ "$USERNAME" != "steamuser" ]; then
			for x in *; do
				if test -h "$x" && test -d "$x"; then
					rm -f "$x"
					ln -sfr Documents_Multilocale "$x"
				fi
			done
		else
			[ -d "My Documents" ] && rm -rf "My Documents" && ln -sfr Documents_Multilocale "My Documents"
		fi

		cd "${DIR}" || exit
	fi

	"$WINE" regedit /D 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\Windows\CurrentVersion\Explorer\Desktop\Namespace\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' &>/dev/null
	echo disable > "${WINEPREFIX}/.update-timestamp"

	# Copy content from additional directories
	if [ -d game_info/additional ]; then
		for f in game_info/additional/*; do
			echo "Copying $f"

			cp -r "$f" "${DIR}"
		done
	fi

	# Execute scripts in game_info/sh directory
	if [ -d game_info/sh ]; then
		echo "Executing scripts"

		chmod -R 700 game_info/sh

		for file in game_info/sh/*; do
			echo "Executing $file"

			"$file"
		done
	fi

	# Install Fonts
	if [ -d game_info/fonts ]; then
		echo "Install fonts"
		cp game_info/fonts/* "${WINEPREFIX}/drive_c/windows/Fonts"
	fi

	# Execute custom winetricks actions
	if [ -f game_info/winetricks_list.txt ]; then
		if [ ! -f "${DIR}/winetricks" ]; then
			if ping -W 1 -c 1 8.8.8.8 &>/dev/null; then
				echo "Downloading winetricks"

				wget -O "${DIR}/winetricks" "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" &>/dev/null
			elif command -v winetricks &>/dev/null; then
				ln -sf "$(command -v winetricks)" "${DIR}/winetricks"
			fi
		fi

		if [ -f "${DIR}/winetricks" ]; then
			if [ ! -x "${DIR}/winetricks" ]; then
				chmod +x "${DIR}/winetricks"
			fi

			echo "winetricks $(cat game_info/winetricks_list.txt)"
			echo "Executing winetricks actions, please wait."

			"$WINESERVER" -w
			# shellcheck disable=SC2046
			"${DIR}/winetricks" $(cat game_info/winetricks_list.txt) &>/dev/null
			"$WINESERVER" -w
		else
			echo "Winetricks not found and can't be downloaded (no internet connection)."
		fi
	fi

	# Enable WINEDEBUG during first run
	export WINEDEBUG="err+all,fixme-all"

	# Save information about last user name and Wine version
	USERNAME="$(id -un)"

	mkdir -p .temp_files
	echo "$USERNAME" > .temp_files/lastuser
	echo "$WINE_VERSION" > .temp_files/lastwine
fi

## Set windows version

if [ ! -f .temp_files/lastwin ] || [ "$WINDOWS_VERSION" != "$(cat .temp_files/lastwin)" ]; then
	if [ "$WINDOWS_VERSION" = "winxp" ] || [ "$WINDOWS_VERSION" = "win10" ] || [ "$WINDOWS_VERSION" = "win11" ] || [ "$WINDOWS_VERSION" = "win7" ]; then
		echo "Changing Windows version to $WINDOWS_VERSION"

		if [ "$WINDOWS_VERSION" = "winxp" ]; then
			if [ "$WINEARCH" = "win32" ]; then
				csdversion="Service Pack 3"
				currentbuildnumber="2600"
				currentversion="5.1"
				csdversion_hex=dword:00000300
			else
				csdversion="Service Pack 2"
				currentbuildnumber="3790"
				currentversion="5.2"
				csdversion_hex=dword:00000200

				"$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f &>/dev/null
			 fi
		elif [ "$WINDOWS_VERSION" = "win7" ]; then
			csdversion="Service Pack 1"
			currentbuildnumber="7601"
			currentversion="6.1"
			csdversion_hex=dword:00000100

			"$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f &>/dev/null
		elif [ "$WINDOWS_VERSION" = "win10" ]; then
			csdversion=""
			currentbuildnumber="19045"
			currentversion="10.0"
			csdversion_hex=dword:00000000

			"$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f &>/dev/null
		elif [ "$WINDOWS_VERSION" = "win11" ]; then
			csdversion=""
			currentbuildnumber="22631"
			currentversion="11.0"
			csdversion_hex=dword:00000000

			"$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f &>/dev/null
		fi

		echo -e "Windows Registry Editor Version 5.00\n" > "${WINEPREFIX}/drive_c/setwinver.reg"
		echo -e "[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion]" >> "${WINEPREFIX}/drive_c/setwinver.reg"
		echo -e '"CSDVersion"="'$csdversion'"' >> "${WINEPREFIX}/drive_c/setwinver.reg"
		echo -e '"CurrentBuildNumber"="'$currentbuildnumber'"' >> "${WINEPREFIX}/drive_c/setwinver.reg"
		echo -e '"CurrentVersion"="'$currentversion'"' >> "${WINEPREFIX}/drive_c/setwinver.reg"

		echo -e "\n[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Windows]" >> "${WINEPREFIX}/drive_c/setwinver.reg"
		echo -e '"CSDVersion"='$csdversion_hex'\n' >> "${WINEPREFIX}/drive_c/setwinver.reg"

		"$WINE" regedit C:\setwinver.reg &>/dev/null
		"$WINE64" regedit C:\setwinver.reg &>/dev/null

		rm -f "${WINEPREFIX}/drive_c/setwinver.reg"
		echo "$WINDOWS_VERSION" > .temp_files/lastwin
	else
		echo "Incorrect Windows version."
		echo "Please, use one of the available versions: winxp, win2k or win7."
	fi
fi

## Set sound driver to PulseAudio

if [ "${USE_PULSEAUDIO}" = 1 ] && [ ! -f "${WINEPREFIX}/drive_c/usepulse.reg" ]; then
	echo "Set audio driver to PulseAudio"

	echo -e "Windows Registry Editor Version 5.00\n" > "${WINEPREFIX}/drive_c/usepulse.reg"
	echo -e "[HKEY_CURRENT_USER\\Software\\Wine\\Drivers]\n" >> "${WINEPREFIX}/drive_c/usepulse.reg"
	echo -e '"Audio"="pulse"' >> "${WINEPREFIX}/drive_c/usepulse.reg"

	"$WINE" regedit C:\usepulse.reg &>/dev/null
	"$WINE64" regedit C:\usepulse.reg &>/dev/null

	rm -f "${WINEPREFIX}/drive_c/usealsa.reg"
elif [ "${USE_PULSEAUDIO}" = 0 ] && [ ! -f "${WINEPREFIX}/drive_c/usealsa.reg" ]; then
	echo "Set audio driver to ALSA"

	echo -e "Windows Registry Editor Version 5.00\n" > "${WINEPREFIX}/drive_c/usealsa.reg"
	echo -e "[HKEY_CURRENT_USER\\Software\\Wine\\Drivers]\n" >> "${WINEPREFIX}/drive_c/usealsa.reg"
	echo -e '"Audio"="alsa"' >> "${WINEPREFIX}/drive_c/usealsa.reg"

	"$WINE" regedit C:\usealsa.reg &>/dev/null
	"$WINE64" regedit C:\usealsa.reg &>/dev/null

	rm -f "${WINEPREFIX}/drive_c/usepulse.reg"
fi

## Disable CSMT if required

if [ "${CSMT_DISABLE}" = 1 ] && [ ! -f "${WINEPREFIX}/drive_c/csmt.reg" ]; then
	echo "Disabling CSMT"

	echo -e "Windows Registry Editor Version 5.00\n" > "${WINEPREFIX}/drive_c/csmt.reg"
	echo -e "[HKEY_CURRENT_USER\Software\Wine\Direct3D]\n" >> "${WINEPREFIX}/drive_c/csmt.reg"
	echo -e '"csmt"=dword:0\n' >> "${WINEPREFIX}/drive_c/csmt.reg"

	"$WINE" regedit C:\csmt.reg &>/dev/null
	"$WINE64" regedit C:\csmt.reg &>/dev/null
elif [ "${CSMT_DISABLE}" = 0 ] && [ -f "${WINEPREFIX}/drive_c/csmt.reg" ]; then
	echo "Enabling CSMT"

	echo -e "Windows Registry Editor Version 5.00\n" > "${WINEPREFIX}/drive_c/csmt.reg"
	echo -e "[HKEY_CURRENT_USER\Software\Wine\Direct3D]\n" >> "${WINEPREFIX}/drive_c/csmt.reg"
	echo -e '"csmt"=-' >> "${WINEPREFIX}/drive_c/csmt.reg"

	"$WINE" regedit C:\csmt.reg &>/dev/null
	"$WINE64" regedit C:\csmt.reg &>/dev/null

	rm -f "${WINEPREFIX}/drive_c/csmt.reg"
fi

## Disable DXVK if required
## Also disable nvapi library if DXVK is enabled

if [ "${DXVK}" = 1 ]; then
			mkdir -p "${WINEPREFIX}/drive_c/windows/system32" "${WINEPREFIX}/drive_c/windows/syswow64"
			ln -sf "${DIR}/game_info/dlls/x64/"{d3d12.dll,d3d12core.dll,d3d11.dll,d3d10core.dll,d3d9.dll,d3d8.dll,dxgi.dll} "${WINEPREFIX}/drive_c/windows/system32" || exit
			ln -sf "${DIR}/game_info/dlls/x32/"{d3d12.dll,d3d12core.dll,d3d11.dll,d3d10core.dll,d3d9.dll,d3d8.dll,dxgi.dll} "${WINEPREFIX}/drive_c/windows/syswow64" || exit
	else
			ln -sf "${DIR}/wine/lib/wine/x86_64-windows/"{d3d12.dll,d3d12core.dll,d3d11.dll,d3d10core.dll,d3d9.dll,d3d8.dll,dxgi.dll} "${WINEPREFIX}/drive_c/windows/system32" || exit
			ln -sf "${DIR}/wine/lib/wine/i386-windows/"{d3d12.dll,d3d12core.dll,d3d11.dll,d3d10core.dll,d3d9.dll,d3d8.dll,dxgi.dll} "${WINEPREFIX}/drive_c/windows/syswow64" || exit
fi

if [ "${NVAPI}" = 1 ]; then
			mkdir -p "${WINEPREFIX}/drive_c/windows/system32" "${WINEPREFIX}/drive_c/windows/syswow64"
			ln -sf "${DIR}/game_info/dlls/x64/nvapi64.dll" "${WINEPREFIX}/drive_c/windows/system32" || exit
			ln -sf "${DIR}/game_info/dlls/x64/nvofapi64.dll" "${WINEPREFIX}/drive_c/windows/system32" || exit
			ln -sf "${DIR}/game_info/dlls/x32/nvapi.dll" "${WINEPREFIX}/drive_c/windows/syswow64" || exit
fi

if [ "${DXVK}" = 0 ]; then
	export DXVK_ASYNC=0
	export WINEDLLOVERRIDES="${WINEDLLOVERRIDES};dxgi,d3d8,d3d9,d3d10core,d3d11,d3d12,d3d12core=b"
elif [ "${DXVK}" = 1 ] && [ -f "${DIR}/game_info/dlls/x64/dxgi.dll" ]; then
	export DXVK_ASYNC=1
	export WINEDLLOVERRIDES="${WINEDLLOVERRIDES};dxgi,d3d8,d3d9,d3d10core,d3d11,d3d12,d3d12core=n"

	if [ ! -d "${DIR}/cache/dxvk" ]; then
		mkdir -p "${DIR}/cache/dxvk"
	fi

	if [ ! -d "${WINEPREFIX}/dosdevices/j:" ]; then
		ln -sfr "${DIR}/cache/dxvk" "${WINEPREFIX}/dosdevices/j:"
	fi
fi

if [ "${NVAPI}" = 0 ]; then
	export DXVK_ENABLE_NVAPI=0
	export WINEDLLOVERRIDES="${WINEDLLOVERRIDES};nvapi64,nvapi="
elif [ "${NVAPI}" = 1 ] && [ -f "${DIR}/game_info/dlls/x64/nvapi64.dll" ]; then
	export DXVK_ENABLE_NVAPI=1
	export WINEDLLOVERRIDES="${WINEDLLOVERRIDES};nvapi,nvapi64=n"
fi

## Execute custom scripts
if [ -d game_info/sh/everytime ]; then
	echo "Executing scripts"

	for file in game_info/sh/everytime/*; do
		echo "Executing $file"

		"$file"
	done
fi

# Copy content from patch directories
if [ -d game_info/patch ]; then
	for f in game_info/patch/*; do
		echo "Copying $f"

		cp -r "$f" "${DIR}/prefix/"
	done
fi

# Set Default Username & Language
if [ -d documents/AppData ]; then
	SETTINGS_FOLDER="${DIR}/documents/AppData/Roaming/Goldberg SteamEmu Saves/settings"
	mkdir -p "${SETTINGS_FOLDER}"
	echo "${GAME_USER}" > "${SETTINGS_FOLDER}/account_name.txt"
	echo "${GAME_LANG}" > "${SETTINGS_FOLDER}/language.txt"
fi

## Run the game

# Output game, vars and Wine information
clear
echo "======================================================="
echo -e "\nGame: $GAME\nVersion: $VERSION"
echo -ne "\nWine: $WINE_VERSION"

if [ $USE_SYSTEM_WINE = 1 ]; then
	echo -ne " (using system Wine)"

	if [ -n "$OLD_GLIBC" ]; then echo -ne " (old GLIBC)"; fi
fi

echo -ne "\nArch: x$(echo $WINEARCH | tail -c 3)"

if [ ! -f "${DIR}/game_info/dlls/x64/dxgi.dll" ] || [ "${DXVK}" = 0 ]; then
	if [ "${CSMT_DISABLE}" = 1 ]; then echo -ne "\nCSMT: disabled"
	else echo -ne "\nCSMT: enabled"; fi

	if [ "$NO_PBA_FOUND" = 0 ]; then
		if [ "${PBA_ENABLE}" = 0 ]; then echo -ne "\nPBA: disabled"
		else echo -ne "\nPBA: enabled"; fi
	fi

	if [ -f "${DIR}/game_info/dlls/x64/dxgi.dll" ]; then
		echo -ne "\nDXVK: disabled"
	fi
elif [ -f "${DIR}/game_info/dlls/x64/dxgi.dll" ]; then echo -ne "\nDXVK: enabled"; fi

if [ $NO_ESYNC_FOUND = 0 ]; then
	if [ $WINEESYNC = 1 ]; then echo -ne "\nESYNC: enabled"
	else echo -ne "\nESYNC: disabled"; fi

	if [ ${ESYNC_FORCE_OFF} = 1 ]; then echo -ne " (disabled; ulimit failed)"; fi
fi

if [ "${ESYNC}" = 1 ]; then
	echo -ne "\nESYNC: enabled"
fi

if [ "${FSYNC}" = 1 ]; then
	echo -ne "\nFSYNC: enabled"
fi

if [ "${FSR}" = 1 ]; then
	echo -ne "\nFSR: enabled"
fi

if [ "${NVAPI}" = 1 ]; then
	echo -ne "\nNVAPI: enabled"
fi

if [ "${VKBASALT}" = 1 ]; then
	echo -ne "\nVKBASALT: enabled"
fi

if [ "${GAMEMODE}" = 1 ]; then
	if [ ! "${GAMEMODE_RUN}" ] > /dev/null 2>&1; then echo -ne "\nError GameMode is not installed\n"
	exit
	else echo -ne "\nGAMEMODE: enabled"; fi
	else
	if [ "${GAMEMODE}" = 0 ]; then echo -ne "\nGAMEMODE: disabled"; fi
fi

echo -ne "\n\n======================================================="

if [ $NO_ESYNC_FOUND = 0 ] && [ ${ESYNC_FORCE_OFF} = 1 ]; then
	echo -ne "\n\nIf you want to enable ESYNC to improve game performance then"
	echo -ne "\nconfigure open file limit in /etc/security/limits.conf, add line:"
	echo -ne "\n\nUSERNAME hard nofile 500000"
	echo -ne "\n\nAnd then reboot your system."
	echo -ne "\n\n======================================================="
fi

if [ "$WINEDEBUG" = "-all" ]; then
	echo -ne "\n\nIf game doesn't work run the script with --debug parameter"
	echo -ne "\nto see more output: ./start.sh --debug"
else
	echo -ne "\n\nDebug mode enabled!"
fi

echo -e "\n\n======================================================="
echo

# Install MF
if [ "$MF" = 1 ]; then
	echo "Install MF"
	MF_INSTALL="${DIR}/game_info/tweaks/mf/mf-install.sh"
	chmod +x "${MF_INSTALL}" || exit
	WINEPREFIX="${WINEPREFIX}" "${MF_INSTALL}" || exit
	sed -i "s@MF=1@MF=0@g" "${DIR}/settings_$SCRIPT_NAME"
	echo "MF is Installed"
fi

# Install MSVC
if [ "$MSVC" = 1 ]; then
	echo "Install MSVC"
	MSVC_INSTALL="${DIR}/game_info/tweaks/msvc/2015/install.sh"
	chmod +x "${MSVC_INSTALL}" || exit
	WINEPREFIX="${WINEPREFIX}" "${MSVC_INSTALL}" || exit
	sed -i "s@MSVC=1@MSVC=0@g" "${DIR}/settings_$SCRIPT_NAME"
	echo "MSVC is Installed"
fi

# Install GDIPLUS
if [ "$GDIPLUS" = 1 ]; then
	echo "Install GDIPLUS"
	GDIPLUS_INSTALL="${DIR}/game_info/tweaks/gdiplus"
	cp -vf --remove-destination "${GDIPLUS_INSTALL}/syswow64/gdiplus.dll" "${WINEPREFIX}/drive_c/windows/syswow64" || exit
	cp -vf --remove-destination "${GDIPLUS_INSTALL}/system32/gdiplus.dll" "${WINEPREFIX}/drive_c/windows/system32" || exit
	export WINEDLLOVERRIDES="${WINEDLLOVERRIDES};gdiplus=n"
	sed -i "s@GDIPLUS=1@GDIPLUS=0@g" "${DIR}/settings_$SCRIPT_NAME"
	echo "GDIPLUS is Installed"
fi

# Install COREFONT
if [ "$COREFONT" = 1 ]; then
	echo "Install COREFONT"
	for file in game_info/tweaks/corefont/*.exe; do
			echo "Executing file $file"

			"$WINE" start "$file" /Q &>/dev/null
		done
	sed -i "s@COREFONT=1@COREFONT=0@g" "${DIR}/settings_$SCRIPT_NAME"
	echo "COREFONT is Installed"
fi

# Set Username & Language
if [ "${GAME_USER}" != liberodark ] || [ "${GAME_LANG}" != english ]; then
	SETTINGS_FOLDER="${DIR}/documents/AppData/Roaming/Goldberg SteamEmu Saves/settings"
	mkdir -p "${SETTINGS_FOLDER}"
	echo "${GAME_USER}" > "${SETTINGS_FOLDER}/account_name.txt"
	echo "${GAME_LANG}" > "${SETTINGS_FOLDER}/language.txt"
	echo "Username : ${GAME_USER}"
	echo "Language : ${GAME_LANG}"
fi

# Launch the game
cd "${GAME_PATH}/$(echo "${GAME_INFO}" | sed -n 5p)" || exit
"$WINESERVER" -w
if [ "${GAMEMODE}" = 1 ]; then
	# shellcheck disable=SC2086
	"${GAMEMODE_RUN}" "$WINE" $VDESKTOP "$EXE" $ARGS
	"$WINESERVER" -w

elif [ "${GAMEMODE}" = 0 ]; then
	# shellcheck disable=SC2086
	"$WINE" $VDESKTOP "$EXE" $ARGS
	"$WINESERVER" -w
fi

# Restore screen resolution
if [ "${RESTORE_RESOLUTION}" = 1 ]; then
	xrandr --output "$OUTPUT" --mode "$RESOLUTION" &>/dev/null
	xgamma -gamma 1.0 &>/dev/null
fi
