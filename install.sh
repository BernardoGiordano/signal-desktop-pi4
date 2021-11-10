set -e

echo "installing apt dependencies..."
sudo apt-get install -y curl git git-lfs make build-essential python3 python-is-python3 libssl-dev libcrypto++-dev libcrypto++8 libgtk-3-dev libvips42 libxss-dev

echo "installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

echo "installing nvm 14.16.0..."
nvm install 14.16.0
nvm use 14.16.0

echo "installing rustup..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

echo "downloading Signal v5.17.0 source code..."
wget https://github.com/signalapp/Signal-Desktop/archive/v5.17.0.tar.gz

echo "cloning libraries..."
git clone https://github.com/signalapp/signal-zkgroup-node.git zkgroup
git clone https://github.com/signalapp/zkgroup.git libzkgroup

git clone https://github.com/lsfxz/signal-ringrtc-node.git 
cd signal-ringrtc-node
git checkout c6075e11abf770bba42e08374a319907f59c5e58
cd ..

git clone https://github.com/signalapp/libsignal-client.git
cd libsignal-client 
git checkout v0.9.0
cd ..

git clone --depth=1 https://github.com/heftig/better-sqlite3
cd better-sqlite3
git checkout c8410c7f4091a5c4e458ce13ac35b04b2eea574b
patch -Np1 -i ../better-sqlite3.patch
cd ..

echo "extracting Signal source code..."
tar xzf v5.17.0.tar.gz

echo "running git-lfs..."
git lfs install

echo "installing rustup..."
rustup toolchain install 1.51.0
rustup default 1.51.0

echo "compiling libzkgroup..."
cd libzkgroup
make libzkgroup
cp -av target/release/libzkgroup.so ../zkgroup/libzkgroup-arm64.so
cd ..

echo "compiling libsignal-client..."
cd libsignal-client
npm i -g yarn
yarn install
yarn tsc
mkdir -p prebuilds/linux-arm64
mv ./build/Release/libsignal_client_linux_arm64.node prebuilds/linux-arm64/node.napi.node
cd ..

echo "compiling Signal Desktop..."
cd Signal-Desktop-5.17.0
sed -r 's#("zkgroup": ").*"#\1file:../zkgroup"#' -i package.json
sed -r 's#("ringrtc": ").*"#\1file:../signal-ringrtc-node"#' -i package.json
sed -r 's#("better-sqlite3": ").*"#\1file:../better-sqlite3"#' -i package.json
sed -r 's#("@signalapp/signal-client": ").*"#\1file:../libsignal-client"#' -i package.json
patch -Np1 -i ../no_deb.patch
patch --forward --strip=1 --input="../expire-from-source-date-epoch.patch"
patch yarn.lock < ../yarn.lock.patch
CFLAGS=`echo $CFLAGS | sed -e 's/-march=armv8-a//'` && CXXFLAGS="$CFLAGS"
yarn generate
yarn run-s --print-label build:grunt build:typed-scss build:webpack
SIGNAL_ENV=production yarn build:electron --arm64 --linux --dir --config.directories.output=release
yarn run-s build:zip
cd ..

echo "Signal Desktop successfully compiled."
