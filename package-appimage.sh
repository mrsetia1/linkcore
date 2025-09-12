#!/bin/bash

# Exit on error
set -e

# Configuration for Debian 7 compatibility
APP_NAME="linkcoin-qt"
VERSION="0.8.7.2"
BUILD_DIR="$(pwd)/appimage-build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.AppDir"
APP_RUN="${APP_DIR}/AppRun"
APP_DESKTOP="${APP_DIR}/${APP_NAME}.desktop"
APP_ICON="${APP_DIR}/${APP_NAME}.png"

# Check if running on Debian 7
if [ -f /etc/debian_version ] && grep -q '^7\..*' /etc/debian_version; then
    echo "Detected Debian 7, using compatibility settings..."
    export DEBIAN_FRONTEND=noninteractive
    
    # Install required build dependencies
    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y build-essential \
                         libssl1.0.0 libssl-dev \
                         libdb++-dev \
                         libboost-all-dev \
                         libqt4-dev \
                         libminiupnpc-dev \
                         imagemagick \
                         wget \
                         file

# Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${APP_DIR}"

# Build the application if not already built
if [ ! -f "linkcoin-qt" ]; then
    echo "Building LinkCoin..."
    make clean
    qmake-qt4
    make -j$(nproc)
fi

# Copy the main executable
cp linkcoin-qt "${APP_DIR}/"

# Create AppRun
cat > "${APP_RUN}" << 'EOL'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
exec "${HERE}"/linkcoin-qt "$@"
EOL
chmod +x "${APP_RUN}"

# Create .desktop file
cat > "${APP_DESKTOP}" << EOL
[Desktop Entry]
Type=Application
Name=LinkCoin
GenericName=LinkCoin
Comment=LinkCoin - Peer-to-Peer Cryptocurrency
Exec=linkcoin-qt
Icon=linkcoin
Categories=Office;Finance;
Terminal=false
EOL

# Copy icon (assuming you have an icon in the source)
if [ -f "src/qt/res/icons/bitcoin.png" ]; then
    cp "src/qt/res/icons/bitcoin.png" "${APP_ICON}"
else
    # Create a placeholder icon if none exists
    convert -size 256x256 xc:white -fill black -pointsize 50 -gravity center -draw "text 0,0 'LC'" "${APP_ICON}"
fi

# Install linuxdeploy (older version for Debian 7 compatibility)
if [ ! -f "linuxdeploy-x86_64.AppImage" ]; then
    echo "Downloading linuxdeploy for Debian 7 compatibility..."
    wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20201023/linuxdeploy-x86_64.AppImage
    chmod +x linuxdeploy-x86_64.AppImage
    
    # Download older AppImageTool if needed
    if [ ! -f "appimagetool-x86_64.AppImage" ]; then
        wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
        chmod +x appimagetool-x86_64.AppImage
    fi
fi

# Create AppImage with Debian 7 compatibility settings
export VERSION=${VERSION}
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/local/lib:${LD_LIBRARY_PATH}

# Use older appimagetool for better compatibility
if [ -f "appimagetool-x86_64.AppImage" ]; then
    export LINUXDEPLOY_PLUGIN_QT_TOOL=1
    export QMAKE=qmake-qt4
    
    # Create AppDir structure
    ./linuxdeploy-x86_64.AppImage \
        --appdir "${APP_DIR}" \
        -d "${APP_DESKTOP}" \
        -i "${APP_ICON}" \
        --plugin qt \
        --output appimage
        
    # Use older appimagetool
    ./appimagetool-x86_64.AppImage --no-appstream "${APP_DIR}" "${APP_NAME}-${VERSION}-debian7-x86_64.AppImage"
else
    # Fallback to standard linuxdeploy
    ./linuxdeploy-x86_64.AppImage \
        --appdir "${APP_DIR}" \
        -d "${APP_DESKTOP}" \
        -i "${APP_ICON}" \
        --output appimage
fi

# Cleanup
rm -f linuxdeploy-x86_64.AppImage
rm -f appimagetool-x86_64.AppImage

# List created AppImage
if [ -f "${APP_NAME}-${VERSION}-debian7-x86_64.AppImage" ]; then
    echo "AppImage created: ${APP_NAME}-${VERSION}-debian7-x86_64.AppImage"
    echo "This AppImage should be compatible with Debian 7 and newer distributions."
else
    echo "AppImage created: $(ls -1 LinkCoin-*.AppImage)"
fi
