#!/bin/bash

# 送信ノードの設定
read -p "Enter the IP address of the Router: " ROUTER_IP

# プレフィックスの設定
PREFIXES=("/example" "/test" "/coke" "/ping")

# NFDの再起動
echo "Restarting NFD..."
sudo nfd-stop && sudo nfd-start

# Faceの作成
echo "Creating Face to Router..."
if nfdc face create udp://$ROUTER_IP; then
  echo "Face created successfully."
else
  echo "Error creating Face." >&2
  exit 1
fi

# FIBの設定
for PREFIX in "${PREFIXES[@]}"; do
  echo "Setting FIB for $PREFIX..."
  if nfdc route add $PREFIX udp://$ROUTER_IP; then
    echo "FIB entry for $PREFIX added successfully."
  else
    echo "Error adding FIB entry for $PREFIX." >&2
    exit 1
  fi
done

# 設定確認
echo "Interest sender setup completed."
nfdc face list
nfdc route list
