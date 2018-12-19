#!/bin/bash

set -xe

mkdir build
cd build

# generate 4 nodes as validators
docker run -v `pwd`:/tmp/out -it consensys/istanbul-tools:latest bash -c "cd /tmp/out && /opt/istanbul setup --num 4 --nodes --verbose --save --quorum"

# Add 3 more nodes - they won't be validators
mkdir 4 5 6

pwd=`pwd`

sed -e '$ d' static-nodes.json > temp.txt
mv temp.txt static-nodes.json

nodekey=`docker run -v $(pwd)/4:/tmp/out consensys/quorum:latest sh -c "/opt/bootnode -genkey /tmp/out/nodekey -writeaddress;cat /tmp/out/nodekey"`;
enode=`docker run consensys/quorum:latest sh -c "/opt/bootnode -nodekeyhex $nodekey -writeaddress"`;
echo ",\"enode://$enode@0.0.0.0:30303?discport=0\"," >> static-nodes.json;

nodekey=`docker run -v $(pwd)/5:/tmp/out consensys/quorum:latest sh -c "/opt/bootnode -genkey /tmp/out/nodekey -writeaddress;cat /tmp/out/nodekey"`;
enode=`docker run consensys/quorum:latest sh -c "/opt/bootnode -nodekeyhex $nodekey -writeaddress"`;
echo "\"enode://$enode@0.0.0.0:30303?discport=0\","  >> static-nodes.json;

nodekey=`docker run -v $(pwd)/6:/tmp/out consensys/quorum:latest sh -c "/opt/bootnode -genkey /tmp/out/nodekey -writeaddress;cat /tmp/out/nodekey"`;
enode=`docker run consensys/quorum:latest sh -c "/opt/bootnode -nodekeyhex $nodekey -writeaddress"`;
echo "\"enode://$enode@0.0.0.0:30303?discport=0\"]" >> static-nodes.json;

jq . static-nodes.json > temp.txt
mv temp.txt static-nodes.json

# Create 1000 accounts and give them initial balance in the genesis.json file.

echo "password" > initial_account_password.txt
for i in `seq 1 1000`;
do
  accountaddress=`docker run -v $(pwd):/tmp/out consensys/quorum:latest bash -c "cd /tmp/out && /opt/geth --datadir=/tmp/out --password /tmp/out/initial_account_password.txt account new"`

  accountaddress=${accountaddress##*\{}
  accountaddress=${accountaddress%\}}
  initialbalance="0x446c3b15f9926687d2c40534fdb564000000000000"

  cat genesis.json | jq \
    --arg accountaddress "$accountaddress" \
    --arg initialbalance "$initialbalance" '.alloc[$accountaddress].balance = $initialbalance' > temp.txt
  mv temp.txt genesis.json
done 