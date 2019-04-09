FROM ubuntu:18.04

########################################
# System Stuff
########################################

## Create a user
RUN groupadd -g 61000 dev
RUN useradd -u 61000 -ms /bin/zsh -g dev dev
WORKDIR /home/dev
ENV HOME /home/dev

WORKDIR $HOME


## Avoid user interaction, for example when installing `tzdata`
# https://askubuntu.com/a/1013396
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Bangkok

## Locales
RUN apt-get update && apt-get install -y locales

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

## Generally a good idea to have these, extensions sometimes need them
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV TERM xterm-256color-italic


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


# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash
RUN apt-get install --yes nodejs


## Install SSH
RUN apt-get update && apt-get install -y \
    openssh-server \
    mosh
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config


## Install Fzf
RUN git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf && $HOME/.fzf/install


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

## Install Neovim
RUN add-apt-repository ppa:neovim-ppa/stable
RUN apt-get update && apt-get install -y neovim

# Install Vim Plug for plugin management
RUN curl -fLo $HOME/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
COPY configs/nvim/init.vim $HOME/.config/nvim/init.vim
COPY configs/nvim/pep8 $HOME/.config/pep8


# Install Tmux Plugin Manager
RUN git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm


## Python
# Install python linting and neovim plugin
COPY configs/py2_requirements.txt /opt/py2_requirements.txt
RUN cd /opt && pip2 install -r py2_requirements.txt
#
COPY configs/py3_requirements.txt /opt/py3_requirements.txt
RUN cd /opt && pip3 install -r py3_requirements.txt



########################################
# Personalizations
########################################

# TMUX

## Colors and italics for tmux
# https://github.com/tmux/tmux/blob/310f0a960ca64fa3809545badc629c0c166c6cd2/FAQ#L355-L383
# https://medium.com/@dubistkomisch/how-to-actually-get-italics-and-true-colour-to-work-in-iterm-tmux-vim-9ebe55ebc2be
COPY configs/tmux/xterm-256color-italic.terminfo $HOME/configs/
COPY configs/tmux/tmux-256color.terminfo $HOME/configs/
RUN tic -x $HOME/configs/xterm-256color-italic.terminfo
RUN tic -x $HOME/configs/tmux-256color.terminfo

# Add some aliases
COPY configs/dotfiles/bashrc $HOME/.bashrc

# Neovim needs this so that <ctrl-h> can work
RUN infocmp $TERM | sed 's/kbs=^[hH]/kbs=\\177/' > /tmp/$TERM.ti
RUN tic /tmp/$TERM.ti

# Add nvim config. Put this last since it changes often
COPY configs/nvim/nvim $HOME/.config/nvim

# Install neovim plugins
RUN nvim -i NONE -c PlugInstall -c quitall > /dev/null 2>&1

## Install YouCompleteMe
# https://vi.stackexchange.com/a/5413
RUN cd $HOME/.config/nvim/plugged/YouCompleteMe && python3 install.py --ts-completer


# Add flake8 config, don't trigger a long build process
#COPY dotfiles/flake8 $HOME/.flake8

# Add local vim-options, can override the one inside
# ADD vim-options $HOME/.config/nvim/plugged/vim-options

# Add isort config, also changes often
#COPY dotfiles/isort.cfg $HOME/.isort.cfg

# Add ranger config
#COPY configs/rc.conf $HOME/.config/ranger/rc.conf

# editorconfig
#COPY dotfiles/editorconfig $HOME/.editorconfig

# Add my git config
COPY configs/gitconfig /etc/gitconfig

# SSH Config
COPY configs/sshd_config /etc/ssh/sshd_config

# OH_MY_ZSH
COPY configs/dotfiles/zshrc $HOME/.zshrc


# Setup SSH
RUN mkdir -p /root/.ssh
RUN mkdir -p $HOME/.ssh


# Start Script
COPY configs/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Setting permission
RUN chown -R dev: $HOME


WORKDIR /workspace

#       ssh    mosh
EXPOSE 62222 60001/udp

# ENTRYPOINT ["bash", "/usr/local/bin/start.sh"]
# CMD ["zsh"]
ENTRYPOINT /usr/local/bin/start.sh && zsh
