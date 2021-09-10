# signal-desktop-pi4

A bash script to compile Signal Desktop for the Raspberry Pi 4.

This solution is based upon this [PKGBUILD](https://gitlab.com/ohfp/pinebookpro-things/-/blob/master/signal-desktop/PKGBUILD) provided by user ohfp on Gitlab. Running this PKGBUILD file using `makedeb` doesn't build Signal Desktop successfully, due to issues with `node-abi` being too outdated for `electron 13.1.8`.

This repository provides all the patches found in the original project, plus a new patch fixing `node-abi` version inside the `yarn.lock` file.

**Important note**: this script also installs `nvm` and `rustup`. If you already have those software installed, please skip installation of those commenting out lines 7 and 10 in the script.

Tested on Ubuntu 21.04.

## Credits

Huge thanks to [@lsfxz (@ohfp on Gitlab)](https://gitlab.com/ohfp/pinebookpro-things/-/blob/master/signal-desktop/PKGBUILD) for providing most of the source code than is available in this repo.