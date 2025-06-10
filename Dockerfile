# Use Ubuntu as the base image
FROM ubuntu:latest

# Set environment variable for non-interactive installs
ENV DEBIAN_FRONTEND=noninteractive

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
    && apt clean \
    && rm -rf /var/lib/apt/lists/*  # Remove unnecessary apt cache

# Install Python packages in one layer to minimize image size
RUN pip3 install pyserial cryptography --break-system-packages
# Verify library dependencies
RUN ldd /usr/lib/x86_64-linux-gnu/libicuuc.so.74

# Clean up any temporary files after the build
RUN rm -rf /tmp/*
