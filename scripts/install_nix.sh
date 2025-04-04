#!/bin/sh
# installing Nix package manager

# positional arg | by default we'll assume the root user
NON_ROOT_USER=$1

# exit immediately if any command within the script exits with a non-zero status
set -e

# non-interactive installation
curl -L https://nixos.org/nix/install -o install-nix.sh
sh install-nix.sh --no-daemon
rm install-nix.sh

if [ -z "$NON_ROOT_USER" ]; then
    # setting up nix environment for root user | this is how Coolify + Nixpacks works
    mkdir -p /etc/nix && echo "build-users-group =" > /etc/nix/nix.conf
    chmod +x /root/.nix-profile/etc/profile.d/nix.sh
    echo ". /root/.nix-profile/etc/profile.d/nix.sh" >> /root/.profile
    . /root/.nix-profile/etc/profile.d/nix.sh
    echo "export PATH=/root/.nix-profile/bin:/root/.nix-profile/sbin:$PATH" >> /root/.bashrc
    echo "export PATH=/root/.nix-profile/bin:/root/.nix-profile/sbin:$PATH" >> /etc/profile
    . /root/.nix-profile/etc/profile.d/nix.sh
else
    # we source the profile here basically just for the version command
    NIX_PROFILE="/home/$NON_ROOT_USER/.nix-profile/etc/profile.d/nix.sh"
    if [ -f "$NIX_PROFILE" ]; then
      # shellcheck source=/dev/null
      . "$NIX_PROFILE"
    else
      echo "Warning: Nix profile not found for $NON_ROOT_USER" >&2
    fi
fi

# can't restart the shell here, will cancel the next command in chain; works OK anyways
echo "Nix has been installed and configured | version: $(nix --version)"
