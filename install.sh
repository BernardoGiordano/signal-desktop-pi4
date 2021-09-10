set -e

sudo apt-get install git git-lfs make

wget https://github.com/signalapp/Signal-Desktop/archive/v5.17.0.tar.gz

git clone https://github.com/signalapp/signal-zkgroup-node.git
git clone https://github.com/signalapp/zkgroup.git

git clone https://github.com/lsfxz/signal-ringrtc-node.git 
cd signal-ringrtc-node
git checkout c6075e11abf770bba42e08374a319907f59c5e58
cd ..

git clone https://github.com/signalapp/libsignal-client.git
cd libsignal-client 
git checkout v0.9.0
cd ..

mv zkgroup libzkgroup
mv signal-zkgroup-node zkgroup

tar xzf v5.17.0.tar.gz

nvm install 14.16.0
nvm use 14.6.0

git lfs install

rustup toolchain install 1.51.0
rustup default 1.51.0

cd Signal-Desktop-5.17.0
sed -r 's#("zkgroup": ").*"#\1file:../zkgroup"#' -i package.json
sed -r 's#("ringrtc": ").*"#\1file:../signal-ringrtc-node"#' -i package.json
sed -r 's#("better-sqlite3": ").*"#\1file:../better-sqlite3"#' -i package.json
cd ..

git clone --depth=1 https://github.com/heftig/better-sqlite3
cd better-sqlite3
git checkout c8410c7f4091a5c4e458ce13ac35b04b2eea574b
patch -Np1 -i ../better-sqlite3.patch
cd ..

cd libzkgroup
make libzkgroup
cp -av target/release/libzkgroup.so ../zkgroup/libzkgroup-arm64.so
cd ..

cd Signal-Desktop-5.17.0
sed -r 's#("@signalapp/signal-client": ").*"#\1file:../libsignal-client"#' -i package.json
cd ..

cd libsignal-client
npm i -g yarn
yarn install
yarn tsc
mkdir -p prebuilds/linux-arm64
mv ./build/Release/libsignal_client_linux_arm64.node prebuilds/linux-arm64/node.napi.node
cd ..

cd Signal-Desktop-5.17.0
patch -Np1 -i ../no_deb.patch

CFLAGS=`echo $CFLAGS | sed -e 's/-march=armv8-a//'` && CXXFLAGS="$CFLAGS"
patch --forward --strip=1 --input="../expire-from-source-date-epoch.patch"

sed -i 's/node-abi@^2.21.0/node-abi@^2.30.1/g' yarn.lock
sed -i 's/node-abi "^2.21.0"/node-abi "^2.30.1"/g' yarn.lock
# TODO: PATCH YARN LOCK

CFLAGS=`echo $CFLAGS | sed -e 's/-march=armv8-a//'` && CXXFLAGS="$CFLAGS"

yarn generate
yarn run-s --print-label build:grunt build:typed-scss build:webpack
SIGNAL_ENV=production yarn build:electron --arm64 --linux --dir --config.directories.output=release
yarn run-s build:zip