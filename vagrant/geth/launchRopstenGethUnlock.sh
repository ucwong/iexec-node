nohup geth --testnet --syncmode "fast" --rpc --rpcport 8543 --port 30333 --rpcaddr 127.0.0.1 --rpccorsdomain "*" --rpcapi "eth,web3,net" --password "passpath" --unlock "address" >> ropstengeth.log &
