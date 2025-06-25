# Use Ubuntu as the base image
FROM ubuntu:latest
RUN echo "Before LABEL"
LABEL org.opencontainers.image.source=https://github.com/tiiuae/sitl-hitl-automation
# Set environment variable for non-interactive installs
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
  libxcb-cursor0 \
  libxkbcommon-x11-0 \
  libxcb-xinerama0 \
  libxcb-icccm4 libxcb-image0 \
  libxcb-keysyms1 libxcb-randr0 \
  libxcb-render-util0 libxcb-xfixes0 \
  libxcb-shm0
  
# Install dependencies and clean up cache in a single step
RUN apt update && apt install -y \
    gdisk \
    python3 \
    python3-pip \
    dosfstools \
    libglew-dev \
    libglib2.0-0 \
    libxslt1.1 \
    libssl-dev \
    libusb-1.0-0-dev \
    libkrb5-dev \
    libx11-dev \
    libglib2.0-dev \
    sudo \
    vim \
    git \
    jq \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*  # Remove unnecessary apt cache

# Install Python packages in one layer to minimize image size
RUN pip3 install pyserial cryptography --break-system-packages
# Verify library dependencies
RUN ldd /usr/lib/x86_64-linux-gnu/libicuuc.so.74

# Clean up any temporary files after the build
RUN rm -rf /tmp/*
