#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run as root"
    exit 1
fi

echo "Installing base tools and dependencies..."
pacman -Syu --noconfirm \
    git \
    wget \
    curl \
    bash \
    base-devel \
    firefox \
    flatpak \
    lutris \
    steam \
    vlc \
    7zip \
    qbittorrent

echo "Installing media/office apps packages..."
flatpak install flathub com.discordapp.Discord

echo "Installing additional web browsers..."
yay -S --noconfirm chromium google-chrome

echo "Installing .NET SDK, runtime and PowerShell..."
yay -S --noconfirm dotnet-sdk dotnet-runtime dotnet-host powershell \
    dotnet-runtime-8.0-bin aspnet-runtime-8.0-bin dotnet-sdk-8.0-bin \
    dotnet-runtime-7.0-bin aspnet-runtime-7.0-bin dotnet-sdk-7.0-bin \
    dotnet-runtime-6.0-bin aspnet-runtime-6.0-bin dotnet-sdk-6.0-bin \
    dotnet-runtime-5.0-bin aspnet-runtime-5.0-bin dotnet-sdk-5.0-bin \

echo "Done. Verify installations:"
dotnet --list-sdks
dotnet --list-runtimes
pwsh --version
