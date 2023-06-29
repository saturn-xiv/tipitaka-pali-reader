#!/bin/bash

# Update and upgrade the system
sudo apt update
sudo apt upgrade -y

# Install Flutter
sudo snap install flutter --classic

# Install required dependencies
sudo apt-get install libgtk-3-0 libblkid1 liblzma5 -y
# Uncomment the following line if needed:
# sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev -y

# Check Flutter installation
flutter doctor

# Install additional tools
sudo apt install p7zip-full p7zip-rar unzip python3-pip python-pip zip -y
pip install gdown

# Clone the repository
mkdir git
cd git
git clone https://github.com/bksubhuti/tipitaka-pali-reader.git
cd tipitaka-pali-reader/assets/database

# Download and extract the necessary files
gdown 1II8XYSQw0JzZxJk2J4QT9XyN2SnqT9qm
unzip tipitaka_pali.zip
sh split.sh
rm *.zip
cd ../..

# Build the Flutter app for Linux
flutter build linux --release

cd TipitakaPaliReader.AppDir

cp -r ~/git/tipitaka-pali-reader/build/linux/x64/release/bundle/* .

# Navigate back to the project root
cd ..

# Download the AppImage tool
#wget https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

#change the permissions of the app run file
chmod +x TipitakaPaliReader.AppDir/AppRun

# Build the AppImage
#ARCH=x86_64 ./appimagetool-x86_64.AppImage TipitakaPaliReader.AppDir/ tipitaka_pali_reader.AppImage
./appimagetool-x86_64.AppImage TipitakaPaliReader.AppDir/ tipitaka_pali_reader.AppImage


 chmod +x tipitaka_pali_reader.AppImage
 ./tipitaka_pali_reader.AppImage --appimage-extract
 mv squashfs-root TPR
 zip -r TPR.zip TPR

# Uncomment the following line if you want to copy the flutterstuff.zip file to the server
# scp ~/Desktop/flutterstuff.zip root@SERVER_IP:/root/tipitaka-pali-reader/

# Uncomment the following line if you want to copy the AppImage to a specific directory on your local machine
# scp root@137.184.81.217:git/tipitaka-pali-reader/tipitaka_pali_reader.AppImage C:\Users\bksub\Downloads
# scp root@137.184.81.217:git/tipitaka-pali-reader/TPR.zip C:\Users\bksub\Downloads
