#!/bin/bash

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
