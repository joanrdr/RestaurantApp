#!/bin/bash
# RestaurantApp - Build Script for macOS
# No dependencies, no libraries, just native code

echo "========================================="
echo "  RestaurantApp v2.0 - Compilando..."
echo "========================================="

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="RestaurantApp"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Compile
echo "[1/4] Compilando codigo nativo..."
clang++ -std=c++17 \
    -framework Cocoa \
    -framework WebKit \
    -fobjc-arc \
    -O2 \
    -w \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    "$PROJECT_DIR/src/main.mm"

if [ $? -ne 0 ]; then
    echo "ERROR: Fallo la compilacion"
    exit 1
fi

echo "[2/4] Copiando recursos..."
cp "$PROJECT_DIR/resources/app.html" "$APP_BUNDLE/Contents/Resources/"

# Generate icon
echo "[3/4] Generando icono..."
ICON="$PROJECT_DIR/resources/icon.png"
if [ -f "$ICON" ]; then
    ICONSET="$APP_BUNDLE/Contents/Resources/AppIcon.iconset"
    mkdir -p "$ICONSET"
    sips -z 16 16 "$ICON" --out "$ICONSET/icon_16x16.png" > /dev/null 2>&1
    sips -z 32 32 "$ICON" --out "$ICONSET/icon_16x16@2x.png" > /dev/null 2>&1
    sips -z 32 32 "$ICON" --out "$ICONSET/icon_32x32.png" > /dev/null 2>&1
    sips -z 64 64 "$ICON" --out "$ICONSET/icon_32x32@2x.png" > /dev/null 2>&1
    sips -z 128 128 "$ICON" --out "$ICONSET/icon_128x128.png" > /dev/null 2>&1
    sips -z 256 256 "$ICON" --out "$ICONSET/icon_128x128@2x.png" > /dev/null 2>&1
    sips -z 256 256 "$ICON" --out "$ICONSET/icon_256x256.png" > /dev/null 2>&1
    sips -z 512 512 "$ICON" --out "$ICONSET/icon_256x256@2x.png" > /dev/null 2>&1
    sips -z 512 512 "$ICON" --out "$ICONSET/icon_512x512.png" > /dev/null 2>&1
    sips -z 1024 1024 "$ICON" --out "$ICONSET/icon_512x512@2x.png" > /dev/null 2>&1
    iconutil -c icns "$ICONSET" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    rm -rf "$ICONSET"
    echo "    Icono generado OK"
else
    echo "    Sin icono (resources/icon.png no encontrado)"
fi

# Info.plist
echo "[4/4] Creando Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>RestaurantApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.restaurantapp.app</string>
    <key>CFBundleName</key>
    <string>RestaurantApp</string>
    <key>CFBundleDisplayName</key>
    <string>RestaurantApp</string>
    <key>CFBundleVersion</key>
    <string>2.0</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
</dict>
</plist>
PLIST

echo ""
echo "========================================="
echo "  LISTO! RestaurantApp v2.0 compilada"
echo "========================================="
echo "  Ubicacion: $APP_BUNDLE"
echo "  open $APP_BUNDLE"
echo "========================================="
