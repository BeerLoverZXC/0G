FROM ubuntu:latest

RUN apt-get update && \
apt-get upgrade -y && \
apt-get install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

ENV HOME=/app

WORKDIR /app

ENV GO_VER="1.22.5"

RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" && \
tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
rm "go$GO_VER.linux-amd64.tar.gz" && \
mkdir -p go/bin

ENV PATH="/usr/local/go/bin:/app/go/bin:${PATH}"
ENV WALLET="wallet"
ENV MONIKER="Stake_Shark"
ENV OG_CHAIN_ID="zgtendermint_16600-2"
ENV OG_PORT="47"

RUN wget -O 0gchaind https://github.com/0glabs/0g-chain/releases/download/v0.4.0/0gchaind-linux-v0.4.0 && \
chmod +x $HOME/0gchaind && \
mv $HOME/0gchaind $HOME/go/bin

RUN 0gchaind config node tcp://localhost:${OG_PORT}657 && \
0gchaind config keyring-backend os && \
0gchaind config chain-id zgtendermint_16600-2 && \
0gchaind init $MONIKER --chain-id zgtendermint_16600-2

run wget -O $HOME/.0gchain/config/genesis.json https://server-5.itrocket.net/testnet/og/genesis.json && \
wget -O $HOME/.0gchain/config/addrbook.json  https://server-5.itrocket.net/testnet/og/addrbook.json

ENV SEEDS="8f21742ea5487da6e0697ba7d7b36961d3599567@og-testnet-seed.itrocket.net:47656"
ENV PEERS="80fa309afab4a35323018ac70a40a446d3ae9caf@og-testnet-peer.itrocket.net:11656,5c8426b14ff9cb62f10100de54f1d134a477105d@65.21.198.58:26656,4e7e6e9a3bc116612644d11b43c9b32b4003bb2c@37.27.128.102:26656,627672939296d653b019e26310e51bf2154ae5bf@195.201.195.156:12656,38bb09933a8f2175af407887fbb37945750ebd93@109.199.127.5:12656,9efd0ac7315cbadaf7f488272360741a5b91f28e@62.169.28.60:12656,9dd8644eed89bb01229f36a575942429f1d6041c@157.173.100.2:12656,c50582aaa4a44869816e202c1a064b500270b75a@65.21.14.11:36656,8b23640e0c93a93e6caa971c002b88096dd0fb57@167.86.94.135:12656,9c665db23dbbe8a667910fb5e1482908a27ed69e@45.159.229.205:12656,4ebe957686bdd64fe44f6c00fb9f29bab6b57345@194.163.149.234:12656,3a3f76e125301db09c2379a06160f41f182a6e52@80.71.227.82:26656,c0dab875b2e19d74a830b4a13393b004d8bf9504@84.21.171.218:12656,da9ac9d516b1c2f788903b0e3ac7eb75de6eb9a1@144.91.116.117:12656,4109414b09167ad2dde0a0265827497187d906a3@89.117.58.218:12656,71e01e28fdf9c09dbd5229ecdf3d97c584c89385@149.50.96.112:26656,23e96ba46f8120735e6b5646a755f32a65bf381b@146.59.118.198:29156,922e74b2a646b0549979596bdfbeda426c3adeac@158.220.99.241:12656,fc6bf6f95d34002ba71b2098fa3d69a4f428b2c0@217.76.57.91:12656,7d5ce62cf4621c62dcef6a2ce8b98049f55ebdc1@185.218.124.231:12656,88df2f5dbe9fa7833e6019942cef07aaba7a5153@75.119.157.128:12656"
RUN sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.0gchain/config/config.toml && \
sed -i.bak -e "s%:1317%:${OG_PORT}317%g; \
s%:8080%:${OG_PORT}080%g; \
s%:9090%:${OG_PORT}090%g; \
s%:9091%:${OG_PORT}091%g; \
s%:8545%:${OG_PORT}545%g; \
s%:8546%:${OG_PORT}546%g; \
s%:6065%:${OG_PORT}065%g" $HOME/.0gchain/config/app.toml && \
sed -i.bak -e "s%:26658%:${OG_PORT}658%g; \
s%:26657%:${OG_PORT}657%g; \
s%:6060%:${OG_PORT}060%g; \
s%:26656%:${OG_PORT}656%g; \
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${OG_PORT}656\"%;\
s%:26660%:${OG_PORT}660%g" $HOME/.0gchain/config/config.toml && \
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchain/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"1000\"/" $HOME/.0gchain/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.0gchain/config/app.toml && \
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0ua0gi"|g' $HOME/.0gchain/config/app.toml && \
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.0gchain/config/config.toml && \
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.0gchain/config/config.toml

RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'sleep 10000' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh
    
ENTRYPOINT ["/app/entrypoint.sh"]
