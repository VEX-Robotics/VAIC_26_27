# Building VAIC Images from source

The VAIC image build system has been improved so that all images can be built with a single host machine using containers.

## Prerequisites

A Linux host machine running a Debian-based distro with Docker installed is required to build the images. WSL may work, but has not been tested. 

> [!IMPORTANT]
> Building on an x86_64 machine will work, but is much slower than building on an ARM64 machine due to emulation.
> It is **HIGHLY RECOMMENDED** to build on an ARM64 machine, such as a Raspberry Pi 5 or a Jetson device running a stock image.

Before building, install docker and add your user to the docker group
```bash
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    newgrp docker
```

## Building

To build your desired image, simply run the build script and select the image you would like to build. The build script will download dependencies and the base image, build the image rootfs in Docker, install boot firmware and kernel, and finally package the image into a compressed file. The build process can be lengthy depending on your host machine, internet speed, and the selected image.

```bash
    cd JetsonImages # Ensure you are in the JetsonImages directory
    ./build-image.sh
```

The resulting image will be placed in the `out/` directory. The image can then be flashed to an SD card using Etcher or similar software.