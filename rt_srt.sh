#!/bin/bash

# ルータの設定

# 接続されているノードの数を入力
read -p "Enter the number of connected nodes: " NODE_COUNT

# ノードのIPアドレスを入力
NODE_IPS=()
for (( i=1; i<=NODE_COUNT; i++ )); do
  read -p "Enter the IP address of node $i: " NODE_IP
  NODE_IPS+=("$NODE_IP")
done

# プレフィックスの設定
PREFIXES=("/example" "/test" "/coke" "/ping")

# NFDの再起動
echo "Restarting NFD..."
if sudo nfd-stop && sudo nfd-start; then
  echo "NFD restarted successfully."
  sleep 2  # NFDが完全に起動するまで待機
else
  echo "Error restarting NFD." >&2
  exit 1
fi

# ノードごとにFaceの作成とFIBの設定
for NODE_IP in "${NODE_IPS[@]}"; do
  echo "Creating Face to node $NODE_IP..."
  if nfdc face create udp://$NODE_IP; then
    echo "Face to node $NODE_IP created successfully."
  else
    echo "Error creating Face to node $NODE_IP." >&2
    exit 1
  fi

  # 各プレフィックスに対してFIBの設定
  for PREFIX in "${PREFIXES[@]}"; do
    echo "Setting FIB for $PREFIX to node $NODE_IP..."
    if nfdc route add $PREFIX udp://$NODE_IP; then
      echo "FIB entry for $PREFIX to node $NODE_IP added successfully."
    else
      echo "Error adding FIB entry for $PREFIX to node $NODE_IP." >&2
      exit 1
    fi
  done
done

# 設定確認
echo "Router setup completed."
nfdc face list
nfdc route list
