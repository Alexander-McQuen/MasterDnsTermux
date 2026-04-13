#!/bin/bash
clear
echo -e "\e[32m======================================\e[0m"
echo -e "\e[32m  Installing MasterDNS VPN Client... \e[0m"
echo -e "\e[32m======================================\e[0m"

cd ~

# 1. Clean up old installation files
rm -rf MasterDnsVPN* master client_config.toml client_resolvers.txt 2>/dev/null

# 2. Download and Extract
echo -e "\e[33m[+] Downloading resources...\e[0m"
curl -L -o master.zip "https://github.com/Alexander-McQuen/MasterDnsTermux/releases/download/app/MasterDnsVPN_Client_Termux_ARM64.zip"

echo -e "\e[33m[+] Extracting files...\e[0m"
unzip -q master.zip
rm master.zip

find . -type f -name "MasterDnsVPN_Client_Termux_ARM64_*" -exec mv {} ./master \;
chmod +x master

echo -e "\e[32m[+] Core files ready.\e[0m"
echo -e "\e[36m======================================\e[0m"
echo -e "\e[36m     Basic Configuration Setup \e[0m"
echo -e "\e[36m  (Press ENTER to use default values) \e[0m"
echo -e "\e[36m======================================\e[0m"

# Default Basic Values
DEF_DOMAIN="v.domain.com"
DEF_KEY="smoke-test-key-12345678901234567890123456789012"
DEF_PORT="18000"
DEF_PROTO="SOCKS5"
DEF_ENC="1"

# Ask Basic Questions
read -r -p "$(echo -e "\e[33m[?] Domain \e[37m[$DEF_DOMAIN]: \e[0m")" USER_DOMAIN
USER_DOMAIN=${USER_DOMAIN:-$DEF_DOMAIN}

read -r -p "$(echo -e "\e[33m[?] Key \e[37m[$DEF_KEY]: \e[0m")" USER_KEY
USER_KEY=${USER_KEY:-$DEF_KEY}

read -r -p "$(echo -e "\e[33m[?] Listen Port \e[37m[$DEF_PORT]: \e[0m")" USER_PORT
USER_PORT=${USER_PORT:-$DEF_PORT}

read -r -p "$(echo -e "\e[33m[?] Protocol (SOCKS5/TCP) \e[37m[$DEF_PROTO]: \e[0m")" USER_PROTO
USER_PROTO=${USER_PROTO:-$DEF_PROTO}

read -r -p "$(echo -e "\e[33m[?] Encryption (0 to 5) \e[37m[$DEF_ENC]: \e[0m")" USER_ENC
USER_ENC=${USER_ENC:-$DEF_ENC}

# --- ADVANCED SETTINGS LOGIC ---
# Default Advanced Values (from your provided file)
ADV_STRATEGY="2"
ADV_PACKET_DUP="2"
ADV_DNS_ENABLED="false"
ADV_MTU_MIN_UP="38"
ADV_MTU_MAX_UP="150"

echo -e "\n\e[36m[?] Do you want to configure advanced settings? (y/N): \e[0m"
read -r WANT_ADVANCED

if [[ "$WANT_ADVANCED" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "\e[35m--- Advanced Configuration ---\e[0m"
    
    read -r -p "$(echo -e "\e[33m[?] Balancing Strategy (1-8) \e[37m[$ADV_STRATEGY]: \e[0m")" USER_STRATEGY
    ADV_STRATEGY=${USER_STRATEGY:-$ADV_STRATEGY}

    read -r -p "$(echo -e "\e[33m[?] Packet Duplication Count (1-4) \e[37m[$ADV_PACKET_DUP]: \e[0m")" USER_PACKET_DUP
    ADV_PACKET_DUP=${USER_PACKET_DUP:-$ADV_PACKET_DUP}

    read -r -p "$(echo -e "\e[33m[?] Enable Local DNS? (true/false) \e[37m[$ADV_DNS_ENABLED]: \e[0m")" USER_DNS_ENABLED
    ADV_DNS_ENABLED=${USER_DNS_ENABLED:-$ADV_DNS_ENABLED}
    
    read -r -p "$(echo -e "\e[33m[?] Max Upload MTU \e[37m[$ADV_MTU_MAX_UP]: \e[0m")" USER_MTU_MAX_UP
    ADV_MTU_MAX_UP=${USER_MTU_MAX_UP:-$ADV_MTU_MAX_UP}
fi

# Generate the TOML file
echo -e "\e[33m[+] Generating config file...\e[0m"
cat << EOF > client_config.toml
DOMAINS = ["${USER_DOMAIN}"]
DATA_ENCRYPTION_METHOD = ${USER_ENC}
ENCRYPTION_KEY = "${USER_KEY}"
PROTOCOL_TYPE = "${USER_PROTO}"
LISTEN_IP = "127.0.0.1"
LISTEN_PORT = ${USER_PORT}
SOCKS5_AUTH = false
SOCKS5_USER = "master_dns_vpn"
SOCKS5_PASS = "master_dns_vpn"
LOCAL_DNS_ENABLED = ${ADV_DNS_ENABLED}
LOCAL_DNS_IP = "127.0.0.1"
LOCAL_DNS_PORT = 53
LOCAL_DNS_CACHE_MAX_RECORDS = 10000
LOCAL_DNS_CACHE_TTL_SECONDS = 14400.0
LOCAL_DNS_PENDING_TIMEOUT_SECONDS = 300.0
DNS_RESPONSE_FRAGMENT_TIMEOUT_SECONDS = 60.0
LOCAL_DNS_CACHE_PERSIST_TO_FILE = true
LOCAL_DNS_CACHE_FLUSH_INTERVAL_SECONDS = 60.0
RESOLVER_BALANCING_STRATEGY = ${ADV_STRATEGY}
PACKET_DUPLICATION_COUNT = ${ADV_PACKET_DUP}
SETUP_PACKET_DUPLICATION_COUNT = 2
STREAM_RESOLVER_FAILOVER_RESEND_THRESHOLD = 2
STREAM_RESOLVER_FAILOVER_COOLDOWN = 2.5
RECHECK_INACTIVE_SERVERS_ENABLED = true
AUTO_DISABLE_TIMEOUT_SERVERS = true
AUTO_DISABLE_TIMEOUT_WINDOW_SECONDS = 30.0
BASE_ENCODE_DATA = false
UPLOAD_COMPRESSION_TYPE = 0
DOWNLOAD_COMPRESSION_TYPE = 0
COMPRESSION_MIN_SIZE = 120
MIN_UPLOAD_MTU = ${ADV_MTU_MIN_UP}
MIN_DOWNLOAD_MTU = 100
MAX_UPLOAD_MTU = ${ADV_MTU_MAX_UP}
MAX_DOWNLOAD_MTU = 500
MTU_TEST_RETRIES = 2
MTU_TEST_TIMEOUT = 2.0
MTU_TEST_PARALLELISM = 16
SAVE_MTU_SERVERS_TO_FILE = false
MTU_SERVERS_FILE_NAME = "masterdnsvpn_success_test_{time}.log"
MTU_SERVERS_FILE_FORMAT = "{IP} ({DOMAIN}) - UP: {UP_MTU} DOWN: {DOWN-MTU}"
MTU_USING_SECTION_SEPARATOR_TEXT = ""
MTU_REMOVED_SERVER_LOG_FORMAT = "Resolver {IP} ({DOMAIN}) removed at {TIME} due to {CAUSE}"
MTU_ADDED_SERVER_LOG_FORMAT = "Resolver {IP} ({DOMAIN}) added back at {TIME} (UP {UP_MTU}, DOWN {DOWN_MTU})"
MTU_REACTIVE_ADDED_SERVER_LOG_FORMAT = "Resolver {IP} ({DOMAIN}) added back at {TIME} after reactive recheck (UP {UP_MTU}, DOWN {DOWN_MTU})"
RX_TX_WORKERS = 4
TUNNEL_PROCESS_WORKERS = 6
TUNNEL_PACKET_TIMEOUT_SECONDS = 10.0
DISPATCHER_IDLE_POLL_INTERVAL_SECONDS = 0.020
RX_CHANNEL_SIZE = 4096
SOCKS_UDP_ASSOCIATE_READ_TIMEOUT_SECONDS = 30.0
CLIENT_TERMINAL_STREAM_RETENTION_SECONDS = 45.0
CLIENT_CANCELLED_SETUP_RETENTION_SECONDS = 120.0
SESSION_INIT_RETRY_BASE_SECONDS = 1.0
SESSION_INIT_RETRY_STEP_SECONDS = 1.0
SESSION_INIT_RETRY_LINEAR_AFTER = 5
SESSION_INIT_RETRY_MAX_SECONDS = 60.0
SESSION_INIT_BUSY_RETRY_INTERVAL_SECONDS = 60.0
SESSION_INIT_RACING_COUNT = 3
PING_AGGRESSIVE_INTERVAL_SECONDS = 0.100
PING_LAZY_INTERVAL_SECONDS = 0.750
PING_COOLDOWN_INTERVAL_SECONDS = 2.0
PING_COLD_INTERVAL_SECONDS = 15.0
PING_WARM_THRESHOLD_SECONDS = 8.0
PING_COOL_THRESHOLD_SECONDS = 20.0
PING_COLD_THRESHOLD_SECONDS = 30.0
MAX_PACKETS_PER_BATCH = 8
ARQ_WINDOW_SIZE = 600
ARQ_INITIAL_RTO_SECONDS = 1.0
ARQ_MAX_RTO_SECONDS = 5.0
ARQ_CONTROL_INITIAL_RTO_SECONDS = 0.5
ARQ_CONTROL_MAX_RTO_SECONDS = 3.0
ARQ_MAX_CONTROL_RETRIES = 400
ARQ_INACTIVITY_TIMEOUT_SECONDS = 1800.0
ARQ_DATA_PACKET_TTL_SECONDS = 2400.0
ARQ_CONTROL_PACKET_TTL_SECONDS = 1200.0
ARQ_MAX_DATA_RETRIES = 1200
ARQ_DATA_NACK_MAX_GAP = 16
ARQ_DATA_NACK_INITIAL_DELAY_SECONDS = 0.1
ARQ_DATA_NACK_REPEAT_SECONDS = 1.0
ARQ_TERMINAL_DRAIN_TIMEOUT_SECONDS = 120.0
ARQ_TERMINAL_ACK_WAIT_TIMEOUT_SECONDS = 90.0
LOG_LEVEL = "INFO"
EOF

# Resolvers Setup
echo -e "\e[36m======================================\e[0m"
echo -e "\e[36m           Resolvers Setup \e[0m"
echo -e "\e[36m======================================\e[0m"

echo "8.8.8.8" > client_resolvers.txt
echo -e "\e[32m[+] Default resolver 8.8.8.8 added.\e[0m"

while true; do
    read -r -p "$(echo -e "\e[33m[?] Enter a resolver IP (or press ENTER to finish): \e[0m")" NEW_RESOLVER
    if [ -z "$NEW_RESOLVER" ]; then
        break
    fi
    echo "$NEW_RESOLVER" >> client_resolvers.txt
    echo -e "\e[32m[+] Resolver $NEW_RESOLVER added successfully.\e[0m"
done

# Execute
clear
echo -e "\e[32m[+] All setups completed!\e[0m"
echo -e "\e[32m[+] Starting MasterDNS Client...\e[0m"
./master
