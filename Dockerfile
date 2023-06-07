FROM golang:1.20.1-alpine as builder

# Pass a tag, branch or a commit using build-arg.  This allows a docker
# image to be built from a specified Git state.  The default image
# will use the Git tip of master by default.
ARG BRANCH="tags/v0.16.3-beta" 
# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies and build the binaries.
RUN apk add --no-cache --update alpine-sdk \
    git \
    make \
    gcc \
&&  git clone https://github.com/lightningnetwork/lnd /go/src/github.com/lightningnetwork/lnd \
&&  cd /go/src/github.com/lightningnetwork/lnd \
&&  git checkout "${BRANCH}" \
&&  make -j $(nproc) release-install

# Start a new, final image.
FROM alpine as playground-lnd-signet

LABEL org.opencontainers.image.authors="nbd"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.source="https://github.com/nbd-wtf/lnd_signet"

# Define a root volume for data persistence.
VOLUME /root/.lnd

# Expose lnd ports (p2p, rpc).
EXPOSE 8989 9735 9911 10009

# Add utilities for quality of life and SSL-related reasons. We also require
# curl and gpg for the signature verification script.
RUN apk --no-cache add \
    bash \
    jq \
    ca-certificates \
    gnupg \
    curl \
    coreutils 

# Copy the binaries from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/
COPY --from=builder /go/src/github.com/lightningnetwork/lnd/scripts/verify-install.sh /

# Store the SHA256 hash of the binaries that were just produced for later
# verification.
RUN sha256sum /bin/lnd /bin/lncli > /shasums.txt

ENV TLSEXTRADOMAIN=$TLSEXTRADOMAIN
ENV TORCONTROL=${TORCONTROL:-}
ENV TORSOCKS=${TORSOCKS:-}
ENV TORPASSWORD=${TORPASSWORD:-}
ENV BITCOIN_ZMQPUBRAWTX=$BITCOIN_ZMQPUBRAWTX
ENV BITCOIN_ZMQPUBRAWBLOCK=$BITCOIN_ZMQPUBRAWBLOCK
ENV BITCOIN_NODE=${BITCOIN_NODE:-'bitcoind'}
ENV BITCOIN_RPCHOST=$BITCOIN_RPCHOST
ENV BITCOIN_RPCUSER=${BITCOIN_RPCUSER:-'bitcoin'}
ENV BITCOIN_RPCPASS=${BITCOIN_RPCPASS:-'bitcoin'}
ENV TOR_TARGET_IPADDRESS=$TOR_TARGET_IPADDRESS
ENV LND_SEEDPHRASE=${LND_SEEDPHRASE:-}
ENV LND_SEEDPASSWORD=$LND_SEEDPASSWORD
ENV NEUTRINO_ADDPEER=$NEUTRINO_ADDPEER
ENV NEUTRINO_FEES=${NEUTRINO_FEES:-}
ENV BITCOIN_NETWORK=${BITCOIN_NETWORK:-'signet'}
ENV SIGNETCHALLENGE=${SIGNETCHALLENGE}
ENV LND_COLOR=$LND_COLOR
ENV LND_ALIAS=$LND_ALIAS
ENV EXTERNAL_IP=$EXTERNAL_IP
ENV REQUIRE_INTERCEPTON=${REQUIRE_INTERCEPTOR:-'false'}
ENV REMOTESIGNER_MACROON=${REMOTESIGNER_MACROON:-'/root/.lnd/signer/admin.macaroon'}
ENV REMOTESIGNER_TLSPATH=${REMOTESIGNER_TLSPATH:-'/root/.lnd/signer/tls.cert'}
ENV REMOTESIGNER_TIMEOUT=${REMOTESIGNER_TIMEOUT:-'5s'}
ENV RPC_POLLING=${RPC_POLLING:-'false'}
ENV PRUNE_REVOCATION=${PRUNE_REVOCATION:-'true'}

COPY docker-entrypoint.sh /usr/local/etc/entrypoint.sh
COPY create-lnd-conf.sh /usr/local/etc/create-lnd-conf.sh 
COPY docker-initwalletcreate.sh /usr/local/etc/docker-initwalletcreate.sh

ENTRYPOINT ["/usr/local/etc/entrypoint.sh"]

# Specify the start command and entrypoint as the lnd daemon.
CMD ["lnd"]
