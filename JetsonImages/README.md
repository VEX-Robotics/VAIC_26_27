## Using the VEXAI Jetson or Raspberry Pi image
We provide OS images for the NVIDIA Jetson Orin Nano, Jetson Nano, and Raspberry Pi 5 that have the VEX AI software pre-installed.

Select and download the correct image for your device from below

| Device | Image | Checksum |
|--------|-------|----------|
| Jetson Orin Nano | [Image](https://content.vexrobotics.com/V5AI/Images/26-27/vexai-jetson-orin-nano-20260806-161439.img.gz) | [SHA256](https://content.vexrobotics.com/V5AI/Images/26-27/vexai-jetson-orin-nano-20260806-161439.img.gz.sha256) |
| Jetson Nano | [Image](https://content.vexrobotics.com/V5AI/Images/26-27/vexai-jetson-nano-legacy-20260806-160444.img.gz) | [SHA256](https://content.vexrobotics.com/V5AI/Images/26-27/vexai-jetson-nano-legacy-20260806-160444.img.gz.sha256) |
| Raspberry Pi 5 | [Image](https://content.vexrobotics.com/V5AI/Images/26-27/vexai-pi5-20260806-161005.img.gz) | [SHA256](https://content.vexrobotics.com/V5AI/Images/26-27/vexai-pi5-20260806-161005.img.gz.sha256) |
  
> [!WARNING]
> Please note that the Raspberry Pi image was built specifically for the Pi 5 with a Google Coral Edge TPU device installed or plugged in and may not work or perform as expected on other Pi models.

You will need the following prerequisites:

1. Download, install, and launch [Etcher](https://www.balena.io/etcher). 
2. A formatted SD-card that is at **least 32GB**.

In Etcher, select the image you downloaded as the image to flash. Pick the correct target to flash to and then Flash using Etcher.

You should now be able to slot your SD card into your NVIDIA Jeston or Raspberry Pi and it will start running the VEX AI system.

The password to either device (should you need to bring up the display and change anything) is `password`.

## Building the image from source
If you are interested in building your own image with VAIC software from source, you can do so by following the instructions in the link below:

[Build Instructions](./BUILD.md)