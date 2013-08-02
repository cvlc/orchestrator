#!/bin/bash
# These should be adjusted to reflect the plugin helper's settings.cfg.
DIR="/home/$USER/orchestrator/dnsmasq"
HOST="localhost"
PORT="8998"
ADDRESS="fd39:9706:2786:6333::1"
SERVER_ID=$(/usr/bin/curl -s -k "https://$HOST:$PORT/cloud/$ADDRESS")

if [[ "$SERVER_ID" == 'false' ]]; then
    SERVER_ID=$(/usr/bin/curl -s -k --data "service_address=$ADDRESS" "https://$HOST:$PORT/cloud/add")
    echo "Server ID: $SERVER_ID"
fi

if [[ "$1" == "add" ]]; then
    if [[ "$DNSMASQ_IAID" ]]; then
        echo "$DNSMASQ_IAID found, creating image"
        ADDINSTANCE=$(/usr/bin/curl -s -k --data "server_id=$SERVER_ID&instance_address=$3&instance_duid=$2" "https://$HOST:$PORT/instance/add")
        echo $ADDINSTANCE
        EXISTS=$(grep "$2" "$DIR/int-staticaddr")
        if [[ "$EXISTS" == '' ]]; then
            echo "id:$2,[$3]" >> "$DIR/int-staticaddr"
        fi
    fi
fi

if [[ "$1" == "old" ]]; then
    if [[ "$DNSMASQ_IAID" ]]; then
        echo "$DNSMASQ_IAID found, old"
        OLDINSTANCE=$(/usr/bin/curl -s -k "https://$HOST:$PORT/instance/up" 2>/dev/null)
        echo $OLDCLIENT
    fi
fi

if [[ $1 == "del" ]]; then
    if [[ "$DNSMASQ_IAID" ]]; then
        echo "$DNSMASQ_IAID found, del"
        DELINSTANCE=$(/usr/bin/curl -s -k "--data \"instance_address=$3\"" "https://$HOST:$PORT/instance/rm" 2>/dev/null)
        echo $DELINSTANCE
        EXISTS=$(grep --quiet "$2" "$DIR/int-staticaddr")
        if $EXISTS; then
            sed -i "/$3/d" "$DIR/int-staticaddr"
        fi
    fi
fi


/usr/bin/ps aux | awk '/[d]nsmasq-internal/{print $2}' | xargs kill -HUP
