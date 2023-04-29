#!/bin/bash

echo "[Application Options]" > /root/.lnd/lnd.conf

if [[ "$WALLET_UNLOCK" != "" ]]; then
    echo "wallet-unlock-password-file=/root/.lnd/unlock.password" >> /root/.lnd/lnd.conf
fi
if [[ "$TLSEXTRADOMAIN" != "" ]]; then
  echo $TLSEXTRADOMAIN | tr ',' '\n' | while read tls; do
    echo "tlsextradomain=$tls" >> /root/.lnd/lnd.conf
  done
fi
if [[ "$LND_LISTEN" != "" ]]; then
  echo $LND_LISTEN | tr ',' '\n' | while read l; do
    echo "listen=$l" >> /root/.lnd/lnd.conf
  done
fi
if [[ "$LND_RPCLISTEN" != "" ]]; then
  echo $LND_RPCLISTEN | tr ',' '\n' | while read l; do
    echo "rpclisten=$l" >> /root/.lnd/lnd.conf
  done
fi
if [[ "$LND_RESTLISTEN" != "" ]]; then
  echo $LND_RESTLISTEN | tr ',' '\n' | while read l; do
    echo "restlisten=$l" >> /root/.lnd/lnd.conf
  done
fi
if [[ "$LND_COLOR" != "" ]]; then
  echo "color=$LND_COLOR" >> /root/.lnd/lnd.conf
fi
if [[ "$LND_ALIAS" != "" ]]; then
  echo "alias=$LND_ALIAS" >> /root/.lnd/lnd.conf
fi

echo "
maxpendingchannels=100
gc-canceled-invoices-on-startup=1
gc-canceled-invoices-on-the-fly=1
minchansize=100000
ignore-historical-gossip-filters=true
accept-keysend=true
accept-amp=true
allow-circular-route=true
numgraphsyncpeers=9
prometheus.listen=0.0.0.0:8989
prometheus.enable=true
stagger-initial-reconnect=true
coin-selection-strategy=random
requireinterceptor=${REQUIRE_INTERCEPTOR:-false}
" >> /root/.lnd/lnd.conf

if [[ "$EXTERNAL_IP" != "" ]]; then
  echo "externalip=$EXTERNAL_IP" >> /root/.lnd/lnd.conf
  echo "tlsextraip=$EXTERNAL_IP" >> /root/.lnd/lnd.conf
fi

echo "[Bitcoin]" >> /root/.lnd/lnd.conf

echo "bitcoin.active=true 
bitcoin.$BITCOIN_NETWORK=true
bitcoin.signetseednode=$SEEDNODE
bitcoin.defaultchanconfs=0
bitcoin.node=$BITCOIN_NODE" >> /root/.lnd/lnd.conf

if [[ "$BITCOIN_NETWORK" == "signet" ]]; then
  echo "bitcoin.dnsseed=0"  >> /root/.lnd/lnd.conf
fi
if [[ "$SIGNETCHALLENGE" != "" ]]; then
  echo "bitcoin.signetchallenge=$SIGNETCHALLENGE" >> /root/.lnd/lnd.conf
fi

if [[ "$BITCOIN_RPCHOST" != "" ]]; then

  echo "[Bitcoind]
bitcoind.rpchost=$BITCOIN_RPCHOST
bitcoind.rpcuser=$BITCOIN_RPCUSER
bitcoind.rpcpass=$BITCOIN_RPCPASS
bitcoind.zmqpubrawblock=$BITCOIN_ZMQPUBRAWBLOCK
bitcoind.zmqpubrawtx=$BITCOIN_ZMQPUBRAWTX" >> /root/.lnd/lnd.conf
fi

if [[ "$RPC_POLLING" == "true" ]]; then
echo "bitcoind.rpcpolling=true
bitcoind.blockpollinginterval=1m
bitcoind.txpollinginterval=30s
" >> /root/.lnd/lnd.conf 
fi

if [[ "$NEUTRINO_ADDPEER" != "" ]]; then
  echo "[neutrino]" >> /root/.lnd/lnd.conf
  echo "neutrino.connect=$NEUTRINO_ADDPEER" >> /root/.lnd/lnd.conf
  echo "neutrino.addpeer=$NEUTRINO_ADDPEER" >> /root/.lnd/lnd.conf
  echo "neutrino.feeurl=$NEUTRINO_FEES" >> /root/.lnd/lnd.conf
fi

echo "[autopilot]" >> /root/.lnd.lnd.conf
echo "autopilot.active=false"  >> /root/.lnd.lnd.conf

echo "[tor]" >> /root/.lnd/lnd.conf
if [[ "$TORSOCKS" != "" ]]; then
  echo "tor.active=true
tor.socks=$TORSOCKS
tor.control=$TORCONTROL
tor.password=$TORPASSWORD
tor.v3=true
tor.skip-proxy-for-clearnet-targets=true" >> /root/.lnd/lnd.conf
else
  echo "tor.active=false" >> /root/.lnd/lnd.conf
fi

echo "[protocol]
protocol.wumbo-channels=true" >> /root/.lnd/lnd.conf

echo "[db]
db.prune-revocation=$PRUNE_REVOCATION" >> /root/.lnd/lnd.conf

if [[ "$POSTGRES_DSN" != "" ]]; then
echo "db.backend=postgres
db.postgres.dsn=$POSTGRES_DSN
db.postgres.timeout=0" >> /root/.lnd/lnd.conf
else
echo "[bolt]
db.bolt.auto-compact=true" >> /root/.lnd/lnd.conf
fi

if [[ "$REMOTESIGNER_RPC" != "" ]]; then
echo "[remotesigner]
remotesigner.enable=true
remotesigner.rpchost=$REMOTESIGNER_RPC
remotesigner.macaroonpath=$REMOTESIGNER_MACROON 
remotesigner.tlscertpath=$REMOTESIGNER_TLSPATH 
remotesigner.timeout=$REMOTESIGNER_TIMEOUT
" >> /root/.lnd/lnd.conf 
fi