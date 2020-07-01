#!/bin/bash
KEY1="mykey"
KEY="mykey2"
CHAINID=8
MONIKER="localtestnet"
DIR="$HOME/.emintd2"

# remove existing daemon and client
rm -rf ~/.emintd2*

make install

# if $KEY exists it should be deleted
emintcli keys add $KEY

# Set moniker and chain-id for Ethermint (Moniker can be anything, chain-id must be an integer)
emintd init $MONIKER --chain-id $CHAINID --home $DIR

# Allocate genesis accounts (cosmos formatted addresses)
emintd add-genesis-account $(emintcli keys show $KEY1 -a) 1000000000000000000photon,1000000000000000000stake --home $DIR
emintd add-genesis-account $(emintcli keys show $KEY -a) 1000000000000000000photon,1000000000000000000stake --home $DIR

# Sign genesis transaction
#emintd gentx --name $KEY --keyring-backend test 
#rm -r $DIR/config/gentx/
cp -r $HOME/.emintd/config/gentx $DIR/config/

# Collect genesis tx
emintd collect-gentxs --home $DIR

# Enable faucet
cat  $DIR/config/genesis.json | jq '.app_state["faucet"]["enable_faucet"]=true' >  $DIR/config/tmp_genesis.json && mv $DIR/config/tmp_genesis.json $DIR/config/genesis.json

echo -e '\n\ntestnet faucet enabled'
echo -e 'to transfer tokens to your account address use:'
echo -e "emintcli tx faucet request 100photon --from $KEY\n"


# Run this to ensure everything worked and that the genesis file is setup correctly
emintd validate-genesis --home $DIR

cp $DIR/config/genesis.json $HOME/.emintd/config/

# Command to run the rest server in a different terminal/window
echo -e '\nrun the following command in a different terminal/window to run the REST server and JSON-RPC:'
echo -e "emintcli rest-server --laddr \"tcp://localhost:8545\" --unlock-key $KEY --chain-id $CHAINID --trace\n"

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
emintd start --pruning=nothing --rpc.unsafe --log_level "main:info,state:info,mempool:info" --trace --home $DIR --rpc.laddr "tcp://127.0.0.1:26659" --p2p.laddr "tcp://127.0.0.1:26660" --p2p.persistent_peers "tcp://127.0.0.1:26657/"$(emintd tendermint show-node-id)