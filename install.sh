#!/bin/bash
clear
echo -e "\e[32m======================================\e[0m"
echo -e "\e[32m  Installing MasterDNS VPN Client... \e[0m"
echo -e "\e[32m======================================\e[0m"

cd ~

# 1. Clean up old installation files to prevent conflicts
rm -rf MasterDnsVPN* master client_config.toml client_resolvers.txt 2>/dev/null

# 2. Download the core files
echo -e "\e[33m[+] Downloading resources...\e[0m"
curl -L -o master.zip "https://github.com/Alexander-McQuen/MasterDnsTermux/releases/download/app/MasterDnsVPN_Client_Termux_ARM64.zip"

# 3. Extract the downloaded package
echo -e "\e[33m[+] Extracting files...\e[0m"
unzip -q master.zip
rm master.zip

# 4. Locate the executable, rename it, and grant execution permissions
find . -type f -name "MasterDnsVPN_Client_Termux_ARM64_*" -exec mv {} ./master \;
find . -type f -name "client_config.toml" -exec mv {} ./ \; 2>/dev/null
find . -type f -name "client_resolvers.txt" -exec mv {} ./ \; 2>/dev/null
chmod +x master

echo -e "\e[32m[+] Installation completed successfully!\e[0m"
echo -e "\e[36m[!] Opening configuration file in 3 seconds. Please enter your Domain and Key...\e[0m"
sleep 3

# 5. Open the configuration file for the user
nano client_config.toml

# 6. Execute the client
clear
echo -e "\e[32m[+] Connecting to server (Port 18000)...\e[0m"
./master
