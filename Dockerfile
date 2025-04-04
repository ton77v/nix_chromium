# Stage 1: Building the application, we'll use Node since it supports ARM as well
FROM node:20-slim AS build-stage

WORKDIR /app_build

# ...

# installing Python for node-gyp: ARM version requires it
RUN apt-get update && apt-get install -y python3 build-essential

# running to cache separately since installing this package often breaks everything with errors like
# npm error gyp http GET https://nodejs.org/download/release/v20.18.0/node-v20.18.0-headers.tar.gz
RUN npm rebuild node-gyp

# ...

# Stage 2: Setup the production environment
FROM node:20-slim

# ...

WORKDIR /usr/src/app

# --- required libraries for the Puppeteer ---
# https://pptr.dev/troubleshooting#chrome-doesnt-launch-on-linux
# curl & xz & sudo are required to install Nix PM & we'll install Chromium from it
RUN apt-get update && apt-get install gnupg wget curl xz-utils sudo -y && \
  apt-get install -y \
  ca-certificates \
  fonts-liberation \
  libasound2 \
  libatk-bridge2.0-0 \
  libatk1.0-0 \
  libc6 \
  libcairo2 \
  libcups2 \
  libdbus-1-3 \
  libexpat1 \
  libfontconfig1 \
  libgbm1 \
  libgcc1 \
  libglib2.0-0 \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libstdc++6 \
  libx11-6 \
  libx11-xcb1 \
  libxcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxrender1 \
  libxss1 \
  libxtst6 \
  lsb-release \
  wget \
  xdg-utils \
  libc-bin \
  curl \
&&  rm -rf /var/lib/apt/lists/*

# creating non-root user with sudo (for Nix PM) + required directories and setting permissions
RUN groupadd -r pptruser && useradd -r -g pptruser -G audio,video,sudo pptruser \
    && echo 'pptruser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/pptruser \
    && chmod 440 /etc/sudoers.d/pptruser \
    && mkdir -p /nix \
    && mkdir -p /home/pptruser/Downloads \
    && mkdir -p /usr/src/app/scheduler \
    && chown -R pptruser:pptruser /home/pptruser \
    && chown -R pptruser:pptruser /usr/src/app \
    && chown -R pptruser:pptruser /usr/src/app/scheduler \
    && chown -R pptruser:pptruser /nix

USER pptruser

# ...
COPY --chown=pptruser:pptruser scripts/install_nix.sh ./install_nix.sh

# we don't need Puppeteer to download its own version of Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
# even with PATH extended we'll get ChromeLauncher.resolveExecutablePath error w/o this
ENV PUPPETEER_EXECUTABLE_PATH=/home/pptruser/.nix-profile/bin/chromium
# allowing execution of Nix command + packages like Chromium installed with Nix
ENV PATH="/home/pptruser/.nix-profile/bin:$PATH"

# installing Nix + Chromium as a non-root user
# util-linux update is required to prevent libmount issues "version 'MOUNT_2_40' not found"
RUN chmod +x ./install_nix.sh && ./install_nix.sh pptruser && \
    rm install_nix.sh && \
    nix-env -iA nixpkgs.util-linux && \
    nix-env --install chromium && \
    echo "Chromium has been installed | version: $(chromium --version)"

ENTRYPOINT ["sh", "-c"]
CMD ["chromium --version && exec tail -f /dev/null"]
