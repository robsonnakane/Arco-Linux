#!/bin/bash

# Função para atualizar o sistema
function atualizar_sistema() {
    sudo pacman -Syyuu --noconfirm
    flatpak update -y
}

# Função para limpar o sistema
function limpar_sistema() {
    # Remove pacotes órfãos
    sudo pacman -Rns $(pacman -Qtdq) --noconfirm
    # Limpa a cache do pacman
    sudo pacman -Scc --noconfirm
    # Remove arquivos de configuração antigos
    sudo pacman -Qe --noconfirm | grep '^extra/' | cut -d' ' -f1 | pacman -Rns --noconfirm
    # Limpa o cache do flatpak
    sudo flatpak uninstall --unused -y
}

# Função para verificar se um pacote está instalado (para pacotes do sistema)
function esta_instalado() {
    sudo pacman -Qs "$1" >/dev/null 2>&1
}

# Função para verificar se um pacote Flatpak está instalado
function esta_instalado_flatpak() {
    flatpak list --user | grep -q "$1"
}

# Função para instalar um pacote se ele não estiver instalado
function instalar_pacote() {
    if ! esta_instalado "$1"; then
        sudo pacman -S --noconfirm "$1" || { echo "Erro ao instalar $1"; return 1; }
    fi
}

# Função para instalar um pacote Flatpak se ele não estiver instalado
function instalar_pacote_flatpak() {
    if ! esta_instalado_flatpak "$1"; then
        flatpak install flathub -y "$1" || { echo "Erro ao instalar $1"; return 1; }
    fi
}

# Lista de pacotes a serem instalados
pacotes=("fastfetch" "libnotify" "foomatic-db" "flatpak" "jdk-openjdk" "gnome-boxes" "thunderbird" "vlc" "audacious")
pacotes_flatpak=("com.spotify.Client" "us.zoom.Zoom" "org.onlyoffice.desktopeditors" "com.skype.Client" "org.raspberrypi.rpi-imager" "org.gnome.Firmware" "org.kde.kdenlive" "ca.littlesvr.asunder" "org.chromium.Chromium" "org.gnome.gitlab.YaLTeR.VideoTrimmer" "com.warlordsoftwares.media-downloader" "org.gtkhash.gtkhash" "fr.handbrake.ghb" "net.fasterland.converseen" "com.transmissionbt.Transmission" "org.fedoraproject.MediaWriter")

# Instala os pacotes
for pacote in "${pacotes[@]}"; do
    instalar_pacote "$pacote"
done

for pacote in "${pacotes_flatpak[@]}"; do
    instalar_pacote_flatpak "$pacote"
done

# Verifica se o pacote libnotify está instalado (necessário para as notificações)
if ! command -v notify-send &> /dev/null; then
    echo "O pacote libnotify não está instalado. Instale-o para receber notificações."
    exit 1
fi

##Completar o IP quando for realizar o backup
#Do notebook para o desktop
#sudo rsync -avzrp /mnt/sdb1/ robsonnakane@192.168.xx.xxx:/mnt/dm-1/
#Do desktop para o notebook
#sudo rsync -avzrp robsonnakane@192.168.xx.xxx:/mnt/dm-1/ /mnt/sdb1/

# Função para verificar se há atualizações e informar o usuário
function verificar_atualizacoes() {
    houve_atualizacao=$(pacman -Qu | wc -l)

    if [ $houve_atualizacao -gt 1 ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Houve atualizações. Deseja reiniciar agora? (s/n)"
        read resposta
        if [[ $resposta =~ ^[Yy]$ ]]; then
            echo "$(date +"%Y-%m-%d %H:%M:%S") - Reiniciando o sistema." >> /home/robsonnakane/Documentos/atualizacoes.log
            notify-send "Atualização do sistema" "O sistema será reiniciado em 5 segundos."
            sleep 5
            sudo systemctl reboot
        else
            echo "$(date +"%Y-%m-%d %H:%M:%S") - Atualizações disponíveis. Reinicie o sistema manualmente." >> /home/robsonnakane/Documentos/atualizacoes.log
        fi
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Não há atualizações disponíveis." >> /home/robsonnakane/Documentos/atualizacoes.log
        notify-send "Sistema atualizado!"
    fi
}

# Executa as funções
atualizar_sistema
limpar_sistema
instalar_pacote
verificar_atualizacoes