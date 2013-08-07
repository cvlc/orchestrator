#!/bin/bash
# These should be adjusted to reflect orchestrator's settings.cfg.
DIR="/home/$USER/orchestrator/dnsmasq"
HOST="localhost"
PORT="8998"
CHANGED="0"
ADDRESS="fd39:9709:2766:6555::1"
SERVER_ID=$(/usr/bin/curl -s -k "https://$HOST:$PORT/dhcp/$ADDRESS")
if [[ "$SERVER_ID" == 'false' ]]; then
    SERVER_ID=$(/usr/bin/curl -s -k --data "service_address=$ADDRESS" "https://$HOST:$PORT/dhcp/add")
    echo "Server ID: $SERVER_ID"
fi

if [[ "$1" == "add" ]]; then
    if [[ "$DNSMASQ_IAID" ]]; then
        echo "$DNSMASQ_IAID found, creating image"
        ADDCLIENT=$(/usr/bin/curl -s -k --data "server_id=$SERVER_ID&client_address=$3&client_duid=$2" "https://$HOST:$PORT/client/add")
        CLIENT_ID=$(echo $ADDCLIENT | cut -d'/' -f1)
        CONTAINER_ID=$(echo $ADDCLIENT | cut -d'/' -f2)
        echo "$CLIENT_ID assigned Docker container $CONTAINER_IP"
        EXISTS=$(grep "$2" "$DIR/ext-staticaddr")
        if [[ "$EXISTS" == '' ]]; then
            echo "id:$2,[$3]" >> "$DIR/ext-staticaddr"
            CHANGED="1"
        fi
    fi
fi

if [[ "$1" == "old" ]]; then
    if [[ "$DNSMASQ_IAID" ]]; then
        echo "$DNSMASQ_IAID found, old"
        OLDCLIENT=$(/usr/bin/curl -s -k "https://$HOST:$PORT/client/up" 2>/dev/null)
        echo $OLDCLIENT
    fi
fi

if [[ $1 == "del" ]]; then
    if [[ "$DNSMASQ_IAID" ]]; then
        echo "$DNSMASQ_IAID found, del"
        delclient=$(/usr/bin/curl -s -k "--data \"client_address=$3\"" "https://$HOST:$PORT/client/rm" 2>/dev/null)
        echo $delclient
        EXISTS=$(grep --quiet "$2" "$DIR/ext-staticaddr")
        if $EXITS; then
            sed -i "/$3/d" "$DIR/int-staticaddr"
            CHANGED="1"
        fi
    fi
fi

if [[ "$CHANGED" == "1" ]]; then
/usr/bin/ps aux | awk '/[d]nsmasq-external/{print $2}' | xargs kill -HUP
fi
