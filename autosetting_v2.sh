#!/bin/bash

# ノードの役割を正しく入力するまで繰り返す
while true; do
    read -p "このノードの役割を入力してください (1: router, 2: data_host, 3: interest_sender): " NODE_ROLE
    case $NODE_ROLE in
      1) NODE_ROLE="router"; break ;;
      2) NODE_ROLE="data_host"; break ;;
      3) NODE_ROLE="interest_sender"; break ;;
      *) echo "無効な選択です。1, 2, または 3 を入力してください。" ;;
    esac
done

# フォワーディング戦略を正しく入力するまで繰り返す
while true; do
    read -p "このノードに適用するフォワーディング戦略を入力してください (1: best-route, 2: multicast, 3: ncc, 4: best-route-2): " STRATEGY_CHOICE
    case $STRATEGY_CHOICE in
      1) STRATEGY_PATH="/localhost/nfd/strategy/best-route"; break ;;
      2) STRATEGY_PATH="/localhost/nfd/strategy/multicast"; break ;;
      3) STRATEGY_PATH="/localhost/nfd/strategy/ncc"; break ;;
      4) STRATEGY_PATH="/localhost/nfd/strategy/best-route-2"; break ;;
      *) echo "無効な選択です。1, 2, 3, または 4 を入力してください。" ;;
    esac
done

# 接続されているノードの数を入力
read -p "接続されているノードの数を入力してください: " NODE_COUNT

# プレフィックスの設定 (必要に応じて追加)
PREFIXES=("/ping" "/example" "/ndn" "/test" "/ndnping")

# ノードのIPアドレスと役割を入力
NODE_INFO=()
for (( i=1; i<=NODE_COUNT; i++ )); do
  read -p "接続されているノード $i のIPアドレスを入力してください: " NODE_IP
  read -p "ノード $i の役割を入力してください (1: interest_sender, 2: data_host, 3: router): " NODE_TYPE
  NODE_INFO+=("$NODE_IP,$NODE_TYPE")
done

# NFDの再起動
echo "NFDを再起動しています..."
sudo nfd-stop
sleep 2
sudo nfd-start
sleep 2

# Forwarding Strategyの設定
echo "すべてのプレフィックスに対して $STRATEGY_PATH のフォワーディング戦略を設定しています..."
for PREFIX in "${PREFIXES[@]}"; do
  if nfdc strategy set $PREFIX $STRATEGY_PATH; then
    sleep 2
    echo "$PREFIX に対するフォワーディング戦略を $STRATEGY_PATH に設定しました。"
  else
    echo "$PREFIX に対するフォワーディング戦略の設定に失敗しました。" >&2
    exit 1
  fi
done

# ノードごとにFaceの作成と確認
for NODE in "${NODE_INFO[@]}"; do
  IFS=',' read -r NODE_IP NODE_TYPE <<< "$NODE"
  echo "ノード $NODE_IP に対する Face を作成しています..."

  # フェイスの存在チェックと作成
  FACE_EXISTS=$(nfdc face list | grep -c "udp://$NODE_IP")
  if [ $FACE_EXISTS -eq 0 ]; then
    if nfdc face create udp://$NODE_IP; then
      sleep 2
      echo "ノード $NODE_IP に対する Face を正常に作成しました。"
    else
      echo "ノード $NODE_IP に対する Face の作成に失敗しました。" >&2
      exit 1
    fi
  else
    echo "ノード $NODE_IP に対する Face は既に存在します。"
  fi
done

# ルーティング設定とフォワーディング戦略適用
case $NODE_ROLE in
  "data_host")
    for PREFIX in "${PREFIXES[@]}"; do
      echo "data_host に対する $PREFIX の FIB を設定しています..."
      if nfdc route add $PREFIX udp://$(hostname -I | awk '{print $1}'); then
        sleep 2
        echo "$PREFIX に対する FIB エントリを追加しました。"
      else
        echo "$PREFIX に対する FIB エントリの追加に失敗しました。" >&2
        exit 1
      fi
    done
    ;;
  "interest_sender")
    echo "interest_sender に対するルーティング設定を行っています..."
    for NODE in "${NODE_INFO[@]}"; do
      IFS=',' read -r NODE_IP NODE_TYPE <<< "$NODE"
      if [ "$NODE_TYPE" == "router" ] || [ "$NODE_TYPE" == "data_host" ]; then
        for PREFIX in "${PREFIXES[@]}"; do
          echo "ノード $NODE_IP に対する $PREFIX の FIB を設定しています..."
          if nfdc route add $PREFIX udp://$NODE_IP; then
            sleep 2
            echo "ノード $NODE_IP に対する $PREFIX の FIB エントリを追加しました。"
          else
            echo "ノード $NODE_IP に対する $PREFIX の FIB エントリの追加に失敗しました。" >&2
            exit 1
          fi
        done
      fi
    done
    ;;
  "router")
    echo "router に対するルーティング設定を行っています..."
    for NODE in "${NODE_INFO[@]}"; do
      IFS=',' read -r NODE_IP NODE_TYPE <<< "$NODE"
      if [ "$NODE_TYPE" == "router" ] || [ "$NODE_TYPE" == "data_host" ]; then
        for PREFIX in "${PREFIXES[@]}"; do
          echo "ノード $NODE_IP に対する $PREFIX の FIB を設定しています..."
          if nfdc route add $PREFIX udp://$NODE_IP; then
            sleep 2
            echo "ノード $NODE_IP に対する $PREFIX の FIB エントリを追加しました。"
          else
            echo "ノード $NODE_IP に対する $PREFIX の FIB エントリの追加に失敗しました。" >&2
            exit 1
          fi
        done
      fi
    done
    ;;
  *)
    echo "無効なノードの役割が指定されました。" >&2
    exit 1
    ;;
esac

# ネットワークの安定化待ち
echo "ネットワークの安定化を待っています..."
sleep 5

# 設定確認
echo "ノードの設定が完了しました。"
nfdc face list
nfdc route list
