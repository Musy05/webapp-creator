#!/bin/bash

set -e  # Stop the script on error

LIST_FILE="$HOME/.wb.list"

# Ensure the list file exists
touch "$LIST_FILE"

# Function to install a web app
install_app() {
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
    APP_DIR="$HOME/.local/share/$(echo "$APP_NAME" | tr ' ' '_')"
    EXEC_FILE="$APP_DIR/main.js"
    DESKTOP_FILE="$HOME/.local/share/applications/$(echo "$APP_NAME" | tr ' ' '_').desktop"
    ICON_FILE="$APP_DIR/icon.png"

    # Create the app directory
    mkdir -p "$APP_DIR"

    # Create package.json
    cat <<EOF > "$APP_DIR/package.json"
{
  "name": "$(echo "$APP_NAME" | tr ' ' '_')",
  "version": "1.0.0",
  "main": "main.js",
  "dependencies": { "electron": "^27.0.0" }
}
EOF

    # Create main.js
    cat <<EOF > "$EXEC_FILE"
const { app, BrowserWindow, Menu } = require('electron');

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
});
EOF

    # Install Electron
    cd "$APP_DIR" && npm install

    # Create the desktop file
    cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=npx electron "$APP_DIR"
Icon=$ICON_FILE
Terminal=false
Categories=Network;
EOF

    chmod +x "$DESKTOP_FILE"
    echo "$APP_NAME application created! You can find the shortcut in $DESKTOP_FILE"
    echo "Please add icon in $ICON_FILE"

    # Save app details to list
    echo "$APP_NAME|$APP_DIR|$DESKTOP_FILE" >> "$LIST_FILE"
}

# Function to remove a web app
remove_app() {
    echo "Installed web apps:"
    nl "$LIST_FILE"

    read -p "Enter the number of the app to remove: " APP_INDEX
    APP_LINE=$(sed -n "${APP_INDEX}p" "$LIST_FILE")

    if [ -z "$APP_LINE" ]; then
        echo "Invalid selection."
        exit 1
    fi

    APP_NAME=$(echo "$APP_LINE" | cut -d '|' -f1)
    APP_DIR=$(echo "$APP_LINE" | cut -d '|' -f2)
    DESKTOP_FILE=$(echo "$APP_LINE" | cut -d '|' -f3)

    # Remove app files
    rm -rf "$APP_DIR"
    rm -f "$DESKTOP_FILE"

    # Remove entry from the list
    # Remove entry from the list safely
    sed -i "${APP_INDEX}d" "$LIST_FILE"
    echo "$APP_NAME has been removed."
}

# Main menu
echo "1) Install a web app"
echo "2) Remove a web app"
read -p "Choose an option: " CHOICE

case $CHOICE in
    1) install_app ;;
    2) remove_app ;;
    *) echo "Invalid option" ;;
esac
