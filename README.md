## Scripts description

These scripts are intended to simplify packing, launching and distributing
Windows games and programs using Wine. In other words, these scripts are for 
creating portable Wine applications. But they also can be used for other purposes. 
These scripts will work on all Linux distributions with GNU standard utilities and bash 
shell installed.

## start.sh script description

All script settings (variables) are in the settings_start file or in the
settings_SCRIPTNAME file.

To change prefix architecture to 32-bit change PREFIX_ARCH variable
to win32 in settings_SCRIPTNAME file.

Script can be launched with --debug parameter to enable more output. This
helps in finding problems when application not working.

Script automatically uses system Wine if there is no wine directory
near the script or if GLIBC version in the system is older than 2.23.

Script automatically creates new prefix during first run and it uses
files from game_info directory. Script is not inteded to work with
already created prefixes.

Script creates documents directory to store games settings and saves.
And so removing prefix will not affect game saves/settings most of the time.

Script automatically recreates prefix if username or Wine versions changes.

Settings file name and game_info.txt name depends on script name.
For example, if script is named start-addon.sh then it will use
settings_start-addon file and game_info-start-addon.txt file if it exists.
If there is not game_info-scriptname.txt file then script will use standard
game_info.txt file. So you can make copies of start.sh script with different
name and they will use different settings and can launch different exe
files.

## tools.sh script description

Tools.sh script can be launched with these arguments:

	--cfg - run winecfg
	--reg - run regedit
	--tricks - if used without additional arguments then run winetricks GUI.
		It can also be used with additional arguments, like:
		./tools.sh --tricks d3dx9 corefonts.
	--kill - kill all running processes of specific Wine prefix
	--fm - run Wine filemanager
	--clean - remove almost all unneeded files from directory
	--icons - create application icons on Desktop and in applications menu
	-- remove-icons - remove created icons
	--help - show available arguments


---

### game_info

## game_info directory

This directory is required for script to work properly. At least, never
remove game_info.txt file and data directory.

Other directories and fiels are not strictly necessary and can be optionally
removed or not created.

## Directories/files description:

* game_info.txt - information about the game
* data - directory containing game files
* dlls - libraries and other files intended to put into system32 directory
* tweaks - directory containing tweaks for help to run game
* additional - specific files (for example, settings for games or fonts)
* patch - same as additional but is for system / app files
* regs - tweaks for registry
* exe - executable files in .exe (mostly, installers of different programs)
* msi - executable files in .msi but is in silent mode (mostly, installers of different programs)
* sh - scripts that will be executed during prefix creation
* icon - game icon file, tools.sh use it for desktop file

## WINETRICKS:

* winetricks_list.txt - list of components to install using winetricks

During prefix creation winetricks will automatically install all components
and apply all tweaks from winetricks_list.txt file. Write names of components
and tweaks in first line, separated by a space.

For example: d3dx9 corefonts xact dxvk win8.

If winetricks is not installed then it will be automatically downloaded.

## Directories description:

### data directory

Put game files here.

## dlls directory

Put here ibraries and other files intended to put into system32 directory

Script will automatically copy them to windows/system32 directory. And also
it will automatically override them to "Native" and will register them
using regsvr32.

You cat put here not only dlls but also files with any other extensions.

## exe directory

Put executable .exe files here (for example, installers).

Script will automatically execute all files from this directory during
prefix creation.

## msi directory

Put executable .msi files here but is in silent mode (for example, installers).

Script will automatically execute all files from this directory during
prefix creation.

## regs directory


Put registry files here.

Script will automatically import all reg files from this directory during
prefix creation.

## sh directory

Put custom shell scripts here.

Script will automatically execute all scripts from this directory
during prefix creation.

## sh/everytime directory

Put custom shell scripts here.

Script will automatically execute all scripts from this directory
each time the game/application launches.

## additional directory

Put any custom files/directories there. The names of directories should
be the same as the name of directories you want to copy to. For example:


The content of game_info/additional/prefix/drive_c/Windows/Fonts directory
will be copied to prefix/drive_c/Windows/Fonts directory during prefix
creation.

The content of game_info/additional/documents/Domcuments_Multilocale/My Games/Fallout4
directory will be copied to documents/Domcuments_Multilocale/My Games/Fallout4
directory during prefix creation.

## patch directory

same as additional option but that is for system copy exemple that help for rewrite registry or install app exemple PhysX.

Etc.
