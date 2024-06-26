# NDN-setting-shell
純粋にcore-emulatorでfaceやらrouteを追加するのがめんどくさいので半自動化

エミュレータを走らせた後、それぞれのノードの仮想ファイルのところに置く。場所は、tmpにある。

# core emulatorでNDN実装
### その1
```
sudo apt-get update
sudo apt-get install build-essential libboost-all-dev libpcap-dev libssl-dev
sudo apt-get install python3-pip
pip3 install --upgrade sphinx
pip3 install sphinxcontrib-doxylink
```
依存関係インストール

### その2
```
git clone https://github.com/named-data/ndn-cxx.git
cd ndn-cxx
./waf configure
./waf
sudo ./waf install
sudo ldconfig
```
ndn-cxxのインストール

### その3
```
git clone https://github.com/named-data/NFD.git
cd NFD
mkdir -p websocketpp
cd websocketpp
curl -L https://github.com/cawka/websocketpp/archive/0.8.1-hotfix.tar.gz > websocketpp.tar.gz
tar xf websocketpp.tar.gz --strip 1
cd ..
git submodule update --init
./waf configure
./waf
sudo ./waf install
```
NFD、デーモン👿のインストール

### その4
nfd confファイルを持ってくる

### その5
nfd-toolのインストール
```
git clone https://github.com/named-data/ndn-tools.git
cd ndn-tools
./waf configure
./waf
sudo ./waf install
sudo ldconfig
```

### その6
`nfd-start`で起動できる。
```
nfdc face create udp://XX.XX.XX.XX
```
でfaceの作成

```
nfdc route add プレフィックス udp://XX.XX.XX.XX
```
でルートの設定

その6の部分を半自動で行う。

以下はchatGPTからのコマンドの説明
### 便利なコマンド

1. **ndnping と ndnpingserver**
   - **ndnpingserver**：特定のプレフィックスでping応答を行うサーバーを起動します。
     ```
     ndnpingserver /example/test
     ```
   - **ndnping**：指定されたプレフィックスに対してpingリクエストを送信し、応答時間を測定します。
     ```
     ndnping -c 10 /example/test
     ```

2. **ndn-traffic-generator**
   - **ndn-traffic-server**：トラフィックを生成するためのサーバーを起動します。
     ```
     ndn-traffic-server -v
     ```
   - **ndn-traffic-client**：トラフィックを生成し、サーバーに送信します。
     ```
     ndn-traffic-client -v -i /example
     ```

3. **nfd-status**
   - **nfd-status**：NFD（NDN Forwarding Daemon）の現在のステータスを表示します。
     ```
     nfd-status
     ```

4. **nfdc**
   nfdc は、NFDの管理と制御を行うためのコマンドラインツールです。以下は一般的なコマンドの例です。

   - **フェイスの作成**：
     ```
     nfdc face create udp://<NODE_IP>
     ```

   - **ルートの追加**：
     ```
     nfdc route add /example/test udp://<NEXT_HOP_IP>
     ```

   - **フェイスの一覧表示**：
     ```
     nfdc face list
     ```

   - **ルートの一覧表示**：
     ```
     nfdc route list
     ```

