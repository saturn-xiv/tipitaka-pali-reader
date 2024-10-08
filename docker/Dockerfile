FROM ubuntu:jammy
LABEL maintainer="Jeremy Zheng"

ENV DEBIAN_FRONTEND noninteractive

RUN dpkg --add-architecture i386
RUN apt update
RUN apt install -y wget gnupg2
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
# RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
RUN apt upgrade -y
RUN apt install -y zsh vim tmux locales sudo locales-all \
    build-essential clang mold cmake pkg-config ninja-build openjdk-21-jdk \
    libgtk-3-dev google-chrome-stable \
    curl git unzip xz-utils zip libglu1-mesa \
    libc6:amd64 libstdc++6:amd64 \
    libbz2-1.0:amd64 libncurses5:amd64 \
    libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386

RUN apt -y autoremove
RUN apt -y clean

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen
RUN update-locale LANG=en_US.UTF-8
RUN update-alternatives --set editor /usr/bin/vim.basic

RUN useradd -s /bin/zsh -m deploy
RUN passwd -l deploy
RUN echo 'deploy ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/101-deploy
USER deploy

RUN mkdir -p $HOME/downloads $HOME/build $HOME/local $HOME/tmp

# https://github.com/ohmyzsh/ohmyzsh
RUN git clone https://github.com/ohmyzsh/ohmyzsh.git $HOME/.oh-my-zsh
RUN cp $HOME/.oh-my-zsh/templates/zshrc.zsh-template $HOME/.zshrc
RUN echo 'export LANG=en_US.UTF-8' >> $HOME/.zshrc
RUN echo 'export LC_ALL=en_US.UTF-8' >> $HOME/.zshrc
RUN echo 'export PATH=$HOME/.local/bin:$PATH' >> $HOME/.zshrc

RUN git config --global core.quotepath false \
    && git config --global http.version HTTP/1.1 \
    && git config --global pull.rebase false \
    && git config --global url."https://".insteadOf git://
RUN echo 'set-option -g history-limit 102400' > $HOME/.tmux.conf \
    && echo 'set-option -g default-shell "/bin/zsh"' >> $HOME/.tmux.conf


ENV ANDROID_COMMAND_LINE_TOOLS_VERSION "11076708"
RUN wget -q -P $HOME/downloads https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_COMMAND_LINE_TOOLS_VERSION}_latest.zip
RUN mkdir -p $HOME/local/android-sdk/cmdline-tools
RUN unzip $HOME/downloads/commandlinetools-linux-${ANDROID_COMMAND_LINE_TOOLS_VERSION}_latest.zip -d $HOME/local/android-sdk/cmdline-tools
RUN mv $HOME/local/android-sdk/cmdline-tools/cmdline-tools $HOME/local/android-sdk/cmdline-tools/latest
RUN echo 'export PATH="$HOME/local/android-sdk/cmdline-tools/latest/bin:$PATH"' >> ~/.zshrc
RUN zsh -c "source $HOME/.zshrc \
    && yes | sdkmanager --licenses \
    && sdkmanager 'platform-tools' 'platforms;android-33' 'build-tools;34.0.0'"

ENV ANDROID_STUDIO_VERSION "2024.2.1.9"
RUN wget -q -P $HOME/downloads https://dl.google.com/dl/android/studio/ide-zips/${ANDROID_STUDIO_VERSION}/android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz
RUN cd $HOME/local \
    && tar xf $HOME/downloads/android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz -C $HOME/local/
RUN $HOME/local/android-studio/bin/studio.sh installPlugins dart
RUN $HOME/local/android-studio/bin/studio.sh installPlugins flutter

ENV FLUTTER_VERSION "3.24.3"
RUN wget -q -P $HOME/downloads https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
RUN tar -xf $HOME/downloads/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C $HOME/local/
RUN echo 'export PATH="$HOME/local/flutter/bin:$PATH"' >> ~/.zshrc


# flutter doctor -v 
RUN zsh -c "source $HOME/.zshrc \
    && flutter config --no-cli-animations \
    && flutter config --android-sdk $HOME/local/android-sdk \
    && flutter config --android-studio-dir $HOME/local/android-studio"

RUN echo "$(date -u +%4Y%m%d%H%M%S)" | sudo tee /VERSION

VOLUME /workspace
WORKDIR /workspace

CMD ["/bin/zsh", "-l"]
