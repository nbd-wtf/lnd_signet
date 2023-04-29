 #!/bin/bash
echo "[lnd_unlock] Waiting 2 seconds for lnd..."
sleep 2

LND_DIR=/root/.lnd

echo "waiting for wallet create phase"
while
    if grep -q 'lncli create' $LND_DIR/logs/bitcoin/$BITCOIN_NETWORK/lnd.log;
    then
        echo "ready to create...."
        #Need to run the python gRPC HERE
        break;
    else
        sleep 2;
        echo "waiting to create."
    fi
do true; done

# ROOTKEY_BASE64=${ROOTKEY_BASE64:-$(dd status=none if=/dev/urandom bs=32 count=1 | base64)}
# echo "ROOTKEY_BASE64: $ROOTKEY_BASE64"

#once we get here we will want to change lnd.conf with wallet-unlock-file stuff
if [[ "$LND_SEEDPHRASE" == "" ]]; then
    echo "Generate seed randomly."
    curl -X GET --cacert $LND_DIR/tls.cert https://localhost:8080/v1/genseed | jq .cipher_seed_mnemonic | tr -d '\n'| tr -d ' ' > $LND_DIR/seeds.txt
else
  echo "Importing existing seed."
  echo "$LND_SEEDPHRASE" > $LND_DIR/seeds.txt
fi

LND_SEEDPASSWORD=${LND_SEEDPASSWORD:=12345678}
echo "encoded seedword:" $(echo $LND_SEEDPASSWORD | tr -d '\n' | base64)
postdata='{"wallet_password":"'
postdata+=$(echo $LND_SEEDPASSWORD  | tr -d '\n' | base64)
postdata+='","cipher_seed_mnemonic":'
postdata+=$(cat $LND_DIR/seeds.txt)
postdata+='}'
echo "POSTDATA:" $postdata
curl -X POST --cacert $LND_DIR/tls.cert -s https://localhost:8080/v1/initwallet -d $postdata
echo $LND_SEEDPASSWORD | tr -d '\n' > /root/.lnd/unlock.password

export WALLET_UNLOCK=true
/usr/local/etc/create-lnd-conf.sh

# ensure that lnd is up and running before proceeding
while
    CA_CERT="/root/.lnd/tls.cert"
    LND_WALLET_DIR="/root/.lnd/data/chain/bitcoin/$BITCOIN_NETWORK/"
    MACAROON_HEADER="Grpc-Metadata-macaroon: $(xxd -p  -c 1000 /root/.lnd/data/chain/bitcoin/$BITCOIN_NETWORK/admin.macaroon |  tr '[:lower:]' '[:upper:]')"
    echo $MACAROON_HEADER
    STATUS_CODE=$(curl -s --cacert "$CA_CERT" -H "$MACAROON_HEADER" -o /dev/null -w "%{http_code}" https://localhost:8080/v1/getinfo)
    # if lnd is running it'll either return 200 if unlocked (noseedbackup=1) or 404 if it needs initialization/unlock
    if [ "$STATUS_CODE" == "200" ] || [ "$STATUS_CODE" == "404" ] ; then
        PUBKEY=$(curl -X GET --cacert "$CA_CERT" -s --header "$MACAROON_HEADER" https://localhost:8080/v1/getinfo | jq .identity_pubkey | tr -d '"')
        echo "Public Key: ${PUBKEY}"
        break
    else
        echo "[lnd_unlock] LND still didn't start, got $STATUS_CODE status code back... waiting another 2 seconds..."
        sleep 2
    fi
do true; done