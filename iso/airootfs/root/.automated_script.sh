#!/usr/bin/env bash

if [[ $(tty) == "/dev/tty1" ]]; then
    echo "run setup-arch.sh to start the installation."
    echo "Your partitions should be mounted before running the script."
fi
