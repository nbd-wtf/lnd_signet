#!/bin/bash
set -eo pipefail

update_tls_and_config()
{
    echo "Cleaning up TLS certs and rewriting lnd.conf"
    rm -f /root/.lnd/tls.key
    rm -f /root/.lnd/tls.cert
    #recreate the config
    if [[ -f /root/.lnd/unlock.password ]]; then
      export WALLET_UNLOCK=true
    fi
    /usr/local/etc/create-lnd-conf.sh 
}

if [[ ! -f /root/.lnd/lnd.conf ]]; then
  echo "lnd.conf file not found in volume, building."
  /usr/local/etc/create-lnd-conf.sh 
  #TODO: probably should handle postgres better here somehow
  if [[ ! -f /root/.lnd/data/chain/bitcoin/$BITCOIN_NETWORK/wallet.db ]]; then
    echo "wallet.db file not found in volume, building."
    /usr/local/etc/docker-initwalletcreate.sh &
  fi
else
  echo "lnd.conf file exists, skipping."
fi
echo "PRUNE_REVOCATION FLAG = $PRUNE_REVOCATION"

localhostip=$(hostname -i)
if [[ -f /root/.lnd/localhostip ]]; then
  savedip=$(cat /root/.lnd/localhostip)
  if [[ "$savedip" != "$localhostip" ]]; then
    echo "Local IP address changed from ${savedip} to ${localhostip}"
    #ip changed lets cleanup tls stuff
    update_tls_and_config
  fi
fi

if [[ -f /root/.lnd/EXTERNAL_IP ]]; then
  prev_EXTERNAL_IP=$(cat /root/.lnd/EXTERNAL_IP)
  if [[ "$prev_EXTERNAL_IP" != "$EXTERNAL_IP" ]]; then
    echo "External IP address changed from ${prev_EXTERNAL_IP} to ${EXTERNAL_IP}"
    update_tls_and_config
  fi
fi

if [[ -f /root/.lnd/TLSEXTRADOMAIN ]]; then
  prev_TLSEXTRADOMAIN=$(cat /root/.lnd/TLSEXTRADOMAIN)
  if [[ "$prev_TLSEXTRADOMAIN" != "$TLSEXTRADOMAIN" ]]; then
    echo "TLS Extra Domain parameters changed from ${prev_TLSEXTRADOMAIN} to ${TLSEXTRADOMAIN}"
    update_tls_and_config
  fi
fi

#save current state for checks on next startup
echo $localhostip > /root/.lnd/localhostip
echo $EXTERNAL_IP > /root/.lnd/EXTERNAL_IP
echo $TLSEXTRADOMAIN > /root/.lnd/TLSEXTRADOMAIN

if [[ "$@" = "lnd" ]]; then
# use ENV spec value or default local network IP
  echo "TOR TARGET IP:" ${TOR_TARGET_IPADDRESS:=$localhostip}
  exec lnd "--tor.targetipaddress=${TOR_TARGET_IPADDRESS:=$localhostip}"
else
  exec "$@"
fi