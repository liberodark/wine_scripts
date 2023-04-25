# October 2021 Notice
For many games this script is not needed anymore, and may soon not be needed at all.

I would reccommend trying games with latest Proton Experimental, Proton-GE, or Proton-tkg first, and only using this as a backup. mf-install may not work with newer Proton versions that implement Valve's ongoing attempt to remotely transcode videos to free formats on their servers.

# mf-install
Easily add Media Foundation support to a Wine prefix. Just set WINEPREFIX to a valid Wine prefix and run.

Example usage:

`WINEPREFIX="/home/user/wine prefixes can be anywhere/folder" ./mf-install.sh`

Steam stores Proton Wine prefixes as `<STEAM FOLDER>/steamapps/compatdata/<GAME ID>/pfx`

# Optional: Using Proton instead of system's Wine
Set the PROTON env variable a Proton folder, and pass -proton to the script. Example:

`WINEPREFIX="/steam folder/steamapps/compatdata/111111/pfx" PROTON="/steam folder/steamapps/common/Proton 5.0" ./mf-install.sh -proton`

# Known issues
For CPUs with more than 8 physical cores, see: https://github.com/z0z0z/mf-install/issues/44
