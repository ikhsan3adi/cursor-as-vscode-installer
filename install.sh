#!/bin/bash

DOWNLOAD_LINK=https://downloader.cursor.sh/linux/appImage/x64

echo "Do you already have an AppImage file in this directory? [y/n] (Default: n)"
read HAVE_APPIMAGE

if [[ ! "$HAVE_APPIMAGE" = y ]]; then
  echo "Fetching the latest cursor.sh x64 AppImage"
  {
    wget --content-disposition "$DOWNLOAD_LINK"
  } || {
    echo "Failed to download the latest cursor AppImage!"
    exit
  }
fi

{
  APP_IMAGE=$(basename -- $(find . -maxdepth 1 -name 'cursor*.AppImage' | head -n 1))
} || {
  echo "cursor*.AppImage not found!"
  exit
}

VER=$(cut -c 8-13 <<<${APP_IMAGE})

echo Found Cursor version ${VER}

CURSOR_DIR=cursor-${VER}

./${APP_IMAGE} --appimage-extract
mv squashfs-root ${CURSOR_DIR}
mkdir -p ${CURSOR_DIR}/usr/share/cursor ${CURSOR_DIR}/usr/bin ${CURSOR_DIR}/usr/share/applications
mv ${CURSOR_DIR}/{*,.*} ${CURSOR_DIR}/usr/share/cursor
mkdir ${CURSOR_DIR}/usr/share/cursor/bin

cp ./cursor ${CURSOR_DIR}/usr/share/cursor/bin
(cd ${CURSOR_DIR}/usr/bin && ln -s ../share/cursor/bin/cursor .)

# copy desktop file
cp cursor.desktop ${CURSOR_DIR}/usr/share/applications

mkdir ${CURSOR_DIR}/DEBIAN
cat >${CURSOR_DIR}/DEBIAN/control <<ENDL
Package: cursor
Version: ${VER}
Architecture: all
Maintainer: nobody@nobody.com
Installed-Size: 176294
Section: misc
Priority: optional
Description: Cursor is an AI-first coding environment.
ENDL

# build .deb
dpkg-deb --build ${CURSOR_DIR}

# install
echo "Do you want to install it now? [y/n] (Default: n)"
read INSTALL_NOW

if [[ "$INSTALL_NOW" = y ]]; then
  echo Installing .deb package
  sudo apt install ./${CURSOR_DIR}.deb
  # sudo dpkg -i ./${CURSOR_DIR}.deb
fi
