# LND Signet Docker Image

## PUBLIC PARMS (zebnet)

signetchallenge           = "5121035e487a7320e5703d1679c1e02b393d9530e490004793207f1a152dc7c9b475a951ae"


## Notes
* Will update lnd.conf and **kill** TLS keys if container detects IP address changed 
  * Make sure you use a static IP on your docker container if you don't want the TLS cert constantly resetting the TLS cert on you
  * TLS cert change triggered on changes on these parameters: 
    * local docker IP
    * EXTERNAL_IP
    * TLSEXTRADOMAIN
## ENV Variables

* LND_SEEDPHRASE - when populated will make deterministic LND wallet/nodeid with provided seedword array ```["word0","word1","word2",...]``` if empty it will generate a new random wallet/nodeid on first startup.
* LND_SEEDPASSWORD - password to encrypted wallet with (if not provided default is ```12345678```)
* TLSEXTRADOMAIN - comma seperated list of tls extra domain fields
* BITCOIN_NODE - node mode (```bitcoind``` or ```neutrino```)
* BITCOIN_NETWORK - Bitcoin network mode: ```signet```, ```mainnet```, ```testnet```
* SIGNETCHALLENGE - Custom signet challenge **(provide when running in neutrino mode, omit with bitcoind)**
* neutrino mode
  * NEUTRINO_ADDPEER - comma seperated list of BIP158 node to sync with  
  * NEUTRINO_FEES - provide HTTP endpoint with fee information (/fees endpoint in faucet)
* bitcoin mode
  * BITCOIN_ZMQPUBRAWTX - Bitcoin ZMQ PUBRAWTX endpoint host:port
  * BITCOIN_ZMQPUBRAWBLOCK - Bitcoin ZMQ PUBRAWBLOCK endpoint host:port
  * BITCOIN_RPCHOST - Bitcoin RPC Host
  * BITCOIN_RPCUSER - Bitcoin RPC User
  * BITCOIN_RPCPASS - Bitcoin RPC Password
* Tor stuff
  * TORCONTROL - tor control port host:port  
  * TORSOCKS - tor SOCK5 port host:port  
  * TORPASSWORD - tor control password
  * TOR_TARGET_IPADDRESS - override container localip to bind tor hidden service registration to
* LND_COLOR - node color property
* LND_ALIAS - node alias property
* EXTERNAL_IP - public IP used for gossip network
* POSTGRES_DSN - DSN for Postgres (optional, if not provided will run on boltdb)
* PRUNE_REVOCATION - apply purge of historical metadata (nothing is lost other than wasted disk space)
* ROOTKEY_BASE64 - deterministic macaroon key (wip didn't end up making the 0.15.1 tag, be in 0.16)
