#!/bin/bash

set -e  # Stop the script on error

# Check if npm and curl are installed
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed. Try 'sudo apt install npm'"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Try 'sudo apt install curl'"
    exit 1
fi

# Ask the user for web app details
read -p "Web app name: " APP_NAME
read -p "Web app URL: " APP_URL
APP_DIR="$HOME/.local/share/$APP_NAME"
EXEC_FILE="$APP_DIR/main.js"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"
ICON_FILE="$APP_DIR/icon.png"

# Create the app directory
mkdir -p "$APP_DIR"

# Create package.json
echo "{
  \"name\": \"$APP_NAME\",
  \"version\": \"1.0.0\",
  \"main\": \"main.js\",
  \"dependencies\": { \"electron\": \"^27.0.0\" }
}" > "$APP_DIR/package.json"

# Create main.js
echo "const { app, BrowserWindow, Menu } = require('electron');

function createWindow() {
    const mainWindow = new BrowserWindow({
        width: 1000,
        height: 700,
        frame: true,
        titleBarStyle: 'default',
        webPreferences: {
            nodeIntegration: true
        }
    });

    mainWindow.webContents.setUserAgent(
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36'
    );
    mainWindow.loadURL('$APP_URL');
    Menu.setApplicationMenu(null);
}

app.whenReady().then(createWindow);

app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow();
    }
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});" > "$EXEC_FILE"

# Install Electron
cd "$APP_DIR" && npm install

# Create the desktop file
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=npx electron "$APP_DIR"
Icon="$ICON_FILE"
Terminal=false
Categories=Network;
EOF

chmod +x "$DESKTOP_FILE"
echo "$APP_NAME application created! You can find the shortcut in $DESKTOP_FILE"
echo "Please add icon in $ICON_FILE"
