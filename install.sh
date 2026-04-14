#!/bin/bash
clear
echo -e "\e[32m======================================\e[0m"
echo -e "\e[32m  Installing MasterDNS VPN Client... \e[0m"
echo -e "\e[32m======================================\e[0m"

cd ~

# 1. Clean up old installation files
rm -rf MasterDnsVPN* master client_config.toml client_resolvers.txt temp_config.toml 2>/dev/null

# 2. Download and Extract
echo -e "\e[33m[+] Downloading resources...\e[0m"
curl -L -o master.zip "https://github.com/Alexander-McQuen/MasterDnsTermux/releases/download/app/MasterDnsVPN_Client_Termux_ARM64.zip"

echo -e "\e[33m[+] Extracting files...\e[0m"
unzip -q master.zip
rm master.zip

# Bring ALL necessary files to the root directory
find . -type f -name "MasterDnsVPN_Client_Termux_ARM64_*" -exec mv {} ./master \; 2>/dev/null
find . -type f -name "client_config.toml" -exec mv {} ./client_config.toml \; 2>/dev/null
find . -type f -name "client_resolvers.txt" -exec mv {} ./client_resolvers.txt \; 2>/dev/null
chmod +x master

# ==========================================
# 🛑 THE MAGIC FILTER: Fix Encoding Issues 🛑
# ==========================================
# This removes ANY non-ASCII/invalid bytes (like 0xd0) from the file
tr -cd '\11\12\15\40-\176' < client_config.toml > temp_config.toml 2>/dev/null
mv temp_config.toml client_config.toml
# Remove Windows line endings
sed -i 's/\r//g' client_config.toml 2>/dev/null
sed -i 's/\r//g' client_resolvers.txt 2>/dev/null

echo -e "\e[32m[+] Core files and detailed config extracted & cleaned.\e[0m"

# 3. Read current defaults from the extracted file
DEF_DOMAIN=$(grep "DOMAINS =" client_config.toml | cut -d'"' -f2)
DEF_KEY=$(grep "ENCRYPTION_KEY =" client_config.toml | cut -d'"' -f2)
DEF_PORT=$(grep "LISTEN_PORT =" client_config.toml | awk '{print $3}')
DEF_PROTO=$(grep "PROTOCOL_TYPE =" client_config.toml | cut -d'"' -f2)
DEF_ENC=$(grep "DATA_ENCRYPTION_METHOD =" client_config.toml | awk '{print $3}')

echo -e "\e[36m======================================\e[0m"
echo -e "\e[36m     Configuration Setup \e[0m"
echo -e "\e[36m  (Press ENTER to keep ZIP settings) \e[0m"
echo -e "\e[36m======================================\e[0m"

# Ask Basic Questions and Sanitize
read -r -p "$(echo -e "\e[33m[?] Domain \e[37m[$DEF_DOMAIN]: \e[0m")" USER_DOMAIN
USER_DOMAIN=${USER_DOMAIN:-$DEF_DOMAIN}
USER_DOMAIN="${USER_DOMAIN//$'\177'/}"

read -r -p "$(echo -e "\e[33m[?] Key \e[37m[$DEF_KEY]: \e[0m")" USER_KEY
USER_KEY=${USER_KEY:-$DEF_KEY}
USER_KEY="${USER_KEY//$'\177'/}"

read -r -p "$(echo -e "\e[33m[?] Listen Port \e[37m[$DEF_PORT]: \e[0m")" USER_PORT
USER_PORT=${USER_PORT:-$DEF_PORT}
USER_PORT="${USER_PORT//$'\177'/}"

read -r -p "$(echo -e "\e[33m[?] Protocol \e[37m[$DEF_PROTO]: \e[0m")" USER_PROTO
USER_PROTO=${USER_PROTO:-$DEF_PROTO}
USER_PROTO="${USER_PROTO//$'\177'/}"

read -r -p "$(echo -e "\e[33m[?] Encryption \e[37m[$DEF_ENC]: \e[0m")" USER_ENC
USER_ENC=${USER_ENC:-$DEF_ENC}
USER_ENC="${USER_ENC//$'\177'/}"

# 4. Update ONLY specific lines in the existing detailed config file
echo -e "\e[33m[+] Updating configuration with your inputs...\e[0m"
sed -i "s|DOMAINS = .*|DOMAINS = [\"$USER_DOMAIN\"]|g" client_config.toml
sed -i "s|ENCRYPTION_KEY = .*|ENCRYPTION_KEY = \"$USER_KEY\"|g" client_config.toml
sed -i "s|LISTEN_PORT = .*|LISTEN_PORT = $USER_PORT|g" client_config.toml
sed -i "s|PROTOCOL_TYPE = .*|PROTOCOL_TYPE = \"$USER_PROTO\"|g" client_config.toml
sed -i "s|DATA_ENCRYPTION_METHOD = .*|DATA_ENCRYPTION_METHOD = $USER_ENC|g" client_config.toml

# --- OPTIONAL ADVANCED SETTINGS ---
echo -e "\n\e[36m[?] Do you want to modify other advanced settings from ZIP? (y/N): \e[0m"
read -r WANT_ADVANCED
WANT_ADVANCED="${WANT_ADVANCED//$'\177'/}"

if [[ "$WANT_ADVANCED" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    read -r -p "$(echo -e "\e[33m[?] Max Upload MTU: \e[0m")" USER_MTU
    if [ ! -z "$USER_MTU" ]; then
        sed -i "s|MAX_UPLOAD_MTU = .*|MAX_UPLOAD_MTU = ${USER_MTU//$'\177'/}|g" client_config.toml
    fi
fi

# 5. Resolvers Setup (APPENDING to existing file)
echo -e "\e[36m======================================\e[0m"
echo -e "\e[36m           Resolvers Setup \e[0m"
echo -e "\e[36m======================================\e[0m"

if [ -f "client_resolvers.txt" ]; then
    EXISTING_COUNT=$(wc -l < client_resolvers.txt)
    echo -e "\e[32m[+] Found $EXISTING_COUNT resolvers in ZIP file.\e[0m"
else
    touch client_resolvers.txt
fi

while true; do
    read -r -p "$(echo -e "\e[33m[?] Add more resolver IP (or press ENTER to finish): \e[0m")" NEW_RESOLVER
    NEW_RESOLVER="${NEW_RESOLVER//$'\177'/}"
    if [ -z "$NEW_RESOLVER" ]; then
        break
    fi
    echo "$NEW_RESOLVER" >> client_resolvers.txt
    echo -e "\e[32m[+] Resolver $NEW_RESOLVER added to the list.\e[0m"
done

# 6. Create Smart Shortcut
echo -e "\e[33m[+] Creating smart shortcut...\e[0m"
echo -e '#!/bin/bash\npkill -f master 2>/dev/null\ncd ~\nclear\n./master' > $PREFIX/bin/vpn
chmod +x $PREFIX/bin/vpn

# Execute
clear
echo -e "\e[32m[+] All setups completed!\e[0m"
echo -e "\e[36m[!] Detailed ZIP settings preserved.\e[0m"
echo -e "\e[36m[!] Type 'vpn' anytime to reconnect.\e[0m"
echo -e "\e[32m[+] Starting MasterDNS Client...\e[0m"
./master
