FROM ubuntu:18.04

########################################
# System Stuff
########################################

## Avoid user interaction, for example when installing `tzdata`
# https://askubuntu.com/a/1013396
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Bangkok

## Locales
RUN apt-get update && apt-get install -y locales

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8  

## Colors and italics for tmux
# https://github.com/tmux/tmux/blob/310f0a960ca64fa3809545badc629c0c166c6cd2/FAQ#L355-L383
# https://medium.com/@dubistkomisch/how-to-actually-get-italics-and-true-colour-to-work-in-iterm-tmux-vim-9ebe55ebc2be
COPY tmux/xterm-256color-italic.terminfo /root
COPY tmux/tmux-256color.terminfo /root
RUN tic -x /root/xterm-256color-italic.terminfo
RUN tic -x /root/tmux-256color.terminfo
ENV TERM=xterm-256color-italic

## Common packages
RUN apt-get update && apt-get install -y \
      build-essential \
      curl \
      git  \
      iputils-ping \
      jq \
      libncurses5-dev \
      libevent-dev \
      net-tools \
      netcat-openbsd \
      silversearcher-ag \
      socat \
      apt-transport-https \
      ca-certificates \
      software-properties-common \
      tmux \
      tzdata \
      wget \
      zsh 

RUN chsh -s /usr/bin/zsh

## Install oh-my-zsh
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
COPY dotfiles/zshrc /root/.zshrc

## Install Docker
# https://www.linode.com/docs/applications/containers/how-to-use-docker-compose/
# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
RUN apt update
RUN apt-cache policy docker-ce
RUN apt install -y docker-ce

## Install Docker Compose
# https://github.com/docker/compose/releases
RUN curl -L https://github.com/docker/compose/releases/download/1.24.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

## Install Fzf
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /root/.fzf && /root/.fzf/install

## Install Tmux
# https://github.com/tmux/tmux/releases/tag/2.8
WORKDIR /usr/local/src
RUN wget https://github.com/tmux/tmux/releases/download/2.8/tmux-2.8.tar.gz
RUN tar xzvf tmux-2.8.tar.gz
WORKDIR /usr/local/src/tmux-2.8
RUN ./configure
RUN make 
RUN make install
RUN rm -rf /usr/local/src/tmux*

## Install Neovim Neccessary
# https://github.com/thornycrackers/docker-neovim/blob/master/Dockerfile
RUN apt-get update && apt-get install -y \
      htop \
      bash \
      python-dev \
      python-pip \
      python3-dev \
      python3-pip \
      ctags \
      shellcheck \
      netcat \
      ack-grep \
      sqlite3 \
      unzip \
      # For python crypto libraries
      libssl-dev \
      libffi-dev \
      # For Youcompleteme
      cmake

## Generally a good idea to have these, extensions sometimes need them
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8      

## Install Neovim
RUN add-apt-repository ppa:neovim-ppa/stable
RUN apt-get update && apt-get install -y neovim

# Install Vim Plug for plugin management
RUN curl -fLo /root/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
COPY nvim/init.vim /root/.config/nvim/init.vim
COPY nvim/pep8 /root/.config/pep8

# Install Tmux Plugin Manager
RUN git clone https://github.com/tmux-plugins/tpm /root/.tmux/plugins/tpm

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash
RUN apt-get install --yes nodejs
RUN node -v

## Python
# Install python linting and neovim plugin
COPY py2_requirements.txt /opt/py2_requirements.txt
RUN cd /opt && pip2 install -r py2_requirements.txt

COPY py3_requirements.txt /opt/py3_requirements.txt
RUN cd /opt && pip3 install -r py3_requirements.txt


########################################
# Personalizations
########################################

# Add some aliases
COPY dotfiles/bashrc /root/.bashrc

# Add my git config
COPY configs/gitconfig /etc/gitconfig

# Change the workdir, Put it inside root so I can see neovim settings in finder
# WORKDIR /root/app

# Neovim needs this so that <ctrl-h> can work
RUN infocmp $TERM | sed 's/kbs=^[hH]/kbs=\\177/' > /tmp/$TERM.ti
RUN tic /tmp/$TERM.ti

# Add nvim config. Put this last since it changes often
COPY nvim/nvim /root/.config/nvim

# Install neovim plugins
RUN nvim -i NONE -c PlugInstall -c quitall > /dev/null 2>&1

# Install tmux plugins
# RUN /root/.tmux/plugins/tpm/bin/install_plugins

## Install YouCompleteMe
# https://vi.stackexchange.com/a/5413
RUN cd /root/.config/nvim/plugged/YouCompleteMe && python3 install.py --ts-completer

# RUN cd /root/.nvim/plugged/YouCompleteMe && ./install.py 

# Add flake8 config, don't trigger a long build process
COPY dotfiles/flake8 /root/.flake8

# Add local vim-options, can override the one inside
# ADD vim-options /root/.config/nvim/plugged/vim-options

# Add isort config, also changes often
COPY dotfiles/isort.cfg /root/.isort.cfg

# Add ranger config
COPY configs/rc.conf /root/.config/ranger/rc.conf

# editorconfig
COPY dotfiles/editorconfig /root/.editorconfig

CMD ["zsh"]
