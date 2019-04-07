### Inspired from 
- https://github.com/jayniz/zsh-tmux-neovim-docker/blob/master/Dockerfile
- https://github.com/thornycrackers/docker-neovim
- https://medium.com/@ls12styler/docker-as-an-integrated-development-environment-95bc9b01d2c1
- https://hackernoon.com/clife-or-my-development-setup-67868b86cb57

### Run Docker
docker run -it --rm phongsakornp/shell
docker run -it -p 62222:62222 -p 60001:60001/udp phongsakornp/shell

### Mosh
mosh --ssh="ssh -p 62222" -- root@192.168.1.42
