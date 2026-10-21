# VEX AI Hardware Guide

This guide covers the **non-VEX hardware** needed to run the VEX AI software in this repository: the AI processor, the Intel RealSense camera, and the other parts that VEX does not sell. The extra VEX parts you need on top of a standard V5 robot are listed in [VEX hardware](#vex-hardware) at the end.

## Which platform should I use?

| Platform | Recommendation | Inference | SD card image |
|----------|----------------|-----------|---------------|
| [NVIDIA Jetson Orin Nano Super](#recommended-nvidia-jetson-orin-nano-super) | **Recommended** for new builds | NVIDIA GPU (TensorRT) | `vexai-jetson-orin-nano` |
| [Raspberry Pi 5 + Google Coral](#economical-option-raspberry-pi-5--google-coral-edge-tpu) | Lower-cost option | Coral Edge TPU | `vexai-pi5` |
| [NVIDIA Jetson Nano](#legacy-nvidia-jetson-nano) | Legacy, existing hardware only | NVIDIA GPU (TensorRT) | `vexai-jetson-nano-legacy` |

Download links for each image are in [JetsonImages/README.md](./JetsonImages/README.md).

> [!NOTE]
> We still publish software for the original **Jetson Nano** so teams that already own one can keep using it. For a new build, we recommend the **Jetson Orin Nano Super**.

## Parts every platform needs

| Qty | Part | Manufacturer | Notes |
|-----|------|--------------|-------|
| 1 | Intel RealSense Depth Camera D435 | [RealSense](https://www.realsenseai.com/product-family/430-series/) | Color and depth camera used for object detection. Includes a USB-C cable. Connect it to a **USB 3** port. |
| 1 | microSD card, 32 GB or larger | Any reputable brand | Holds the VEX AI image. A UHS-I U3 / A2 card is recommended. |
| 1 | USB-A to Micro-USB cable | Any | Connects the AI processor to the V5 Brain for serial data. |
| 1 | Lithium battery pack for the AI processor | See [Powering the AI processor](#powering-the-ai-processor) | Output must match the platform. |
| — | Mounting hardware or 3D-printed housings | — | See [3D Printing Housings for the VEX AI System](https://kb.vex.com/hc/en-us/articles/360048983291-3D-Printing-Housings-for-the-VEX-AI-System). |

You will also need a computer with a microSD card reader and [balenaEtcher](https://etcher.balena.io/) to flash the image, and a laptop or tablet with Wi-Fi to view the web dashboard.

## Powering the AI processor

We recommend powering the AI processor from its **own lithium battery pack**, not from the V5 Brain. The V5 Brain's ports are not designed to supply this much power:

| V5 Brain port | Voltage | Current limit |
|---------------|---------|---------------|
| Smart Port | Battery voltage (about 12.8 V nominal) | 4 A per port |
| 3-Wire Port (A–H) | 5 V | 2 A **total**, shared by all eight 3-Wire ports and some of the Brain's internal circuits |

The AI processors can draw 20–25 W under load. That is more than the 3-Wire ports can supply. A separate battery also keeps the processor running when the V5 Brain is turned off or restarted.

Choose a battery whose output matches your platform:

| Platform | Required output | Connector | Suggested capacity |
|----------|-----------------|-----------|--------------------|
| Jetson Orin Nano Super | **9–20 V DC** (12 V or 19 V output recommended), 45 W or more | 5.5 mm × 2.5 mm barrel plug | Enough for at least 1 hour at 25 W |
| Raspberry Pi 5 | **5.1 V / 5 A** over USB-C (USB Power Delivery) | USB-C | Enough for at least 1 hour at 25 W |
| Jetson Nano (legacy) | **5 V / 4 A** DC | 5.5 mm × 2.1 mm barrel plug | Enough for at least 1 hour at 20 W |

> [!WARNING]
> **Raspberry Pi 5:** many USB-C power banks cannot supply 5 V at 5 A. When the Pi 5 does not detect a 5 A supply, it limits its USB ports to 600 mA total. That is not enough for the RealSense camera. Use a battery that is rated for 5 V / 5 A PD output.
>
> Power the Pi 5 through its **USB-C port**, not through the 5 V pins on the GPIO header. Powering through GPIO bypasses the Pi's built-in power protection.

> [!WARNING]
> **Jetson Orin Nano:** the Developer Kit can only be powered through its barrel jack, not its USB-C port. Do not use a 5 V supply.

> [!WARNING]
> **Jetson Nano (legacy):** install the **DC_EN jumper** next to the barrel jack, or the board will not power from the barrel plug.

---

## Recommended: NVIDIA Jetson Orin Nano Super

The Orin Nano Super is the fastest supported platform. The Developer Kit includes Wi-Fi (used for the dashboard hotspot) and an active heatsink with a fan, so it needs very few extra parts.

**Parts list (per robot)**

| Qty | Part | Manufacturer | Notes |
|-----|------|--------------|-------|
| 1 | Jetson Orin Nano Super Developer Kit | [NVIDIA](https://www.nvidia.com/en-us/autonomous-machines/embedded-systems/jetson-orin/nano-super-developer-kit/) | Includes the module, carrier board, Wi-Fi, heatsink/fan, and a 19 V wall adapter for bench use. An older Jetson Orin Nano Developer Kit also works. |
| 1 | Lithium battery pack, 9–20 V DC output, 45 W or more | Any | Needs a 5.5 mm × 2.5 mm barrel plug. See [Powering the AI processor](#powering-the-ai-processor). |
| — | [Parts every platform needs](#parts-every-platform-needs) | | RealSense D435, microSD card, cables |

**Setup notes**
- Flash the `vexai-jetson-orin-nano` image to the microSD card.
- On the first run the software builds a TensorRT engine from the model. This can take several minutes. Later starts are fast.
- The Developer Kit hardware layout and power specifications are in the [Jetson Orin Nano Developer Kit User Guide](https://docs.nvidia.com/jetson/orin-nano-devkit/user-guide/latest/hardware_layout.html).

---

## Economical option: Raspberry Pi 5 + Google Coral Edge TPU

The Raspberry Pi 5 costs less than the Orin Nano, but it is not fast enough to run the model on its own. It **requires** a Google Coral Edge TPU accelerator. Without one, the software stops with `No Coral device found`.

**Parts list (per robot)**

| Qty | Part | Part number | Manufacturer | Buy | Notes |
|-----|------|-------------|--------------|-----|-------|
| 1 | Raspberry Pi 5 (4 GB or larger) | — | [Raspberry Pi](https://www.raspberrypi.com/products/raspberry-pi-5/) | [Approved resellers](https://www.raspberrypi.com/products/raspberry-pi-5/) | The VEX AI image only supports the Pi 5. Built-in Wi-Fi is used for the dashboard hotspot. |
| 1 | Raspberry Pi M.2 HAT+ (M key, standard) | SC1166 | [Raspberry Pi](https://www.raspberrypi.com/products/m2-hat-plus/) | [Mouser](https://www.mouser.com/ProductDetail/Raspberry-Pi/SC1166) | Connects the Coral to the Pi 5's PCIe port. Get the **standard** HAT+, not the Compact. |
| 1 | Coral M.2 Accelerator, B+M key | G650-04686-01 | [ASUS (Coral)](https://www.asus.com/networking-iot-servers/aiot-industrial-solutions/gpu-edge-ai-accelerators/coral-m-2-accelerator-b-m-key/) | [Mouser](https://www.mouser.com/ProductDetail/Coral/G650-04686-01) | The Edge TPU that runs the model. Must be the **B+M key** version to fit the HAT+. See the mounting note below. |
| 1 | Raspberry Pi Active Cooler | SC1148 | [Raspberry Pi](https://www.raspberrypi.com/products/active-cooler/) | [Mouser](https://www.mouser.com/ProductDetail/Raspberry-Pi/SC1148) | Keeps the Pi 5 from throttling under constant load. Fits under the M.2 HAT+. |
| 1 | Lithium battery pack, 5.1 V / 5 A USB-C PD output | — | Any | — | See [Powering the AI processor](#powering-the-ai-processor). |
| 1 | Raspberry Pi 27W USB-C Power Supply (optional) | — | [Raspberry Pi](https://www.raspberrypi.com/products/27w-power-supply/) | — | For bench use and setup. |
| — | [Parts every platform needs](#parts-every-platform-needs) | | | | RealSense D435, microSD card, cables |

> [!NOTE]
> **Mounting the Coral on the M.2 HAT+:** the Coral B+M key card is 80 mm long (M.2 2280), but the HAT+ only has mounting holes for 2230 and 2242 cards. Plug the card into the M key slot and secure it with the HAT+'s knurled screw through the card's 2242 hole. The end of the card will overhang the edge of the HAT. Make sure the overhang does not hit your robot's structure or mounts.

> [!NOTE]
> **Coral USB Accelerator:** the [Coral USB Accelerator](https://www.asus.com/networking-iot-servers/aiot-industrial-solutions/gpu-edge-ai-accelerators/coral-usb-accelerator/) (G950-06809-01, [Mouser](https://www.mouser.com/ProductDetail/Coral/G950-06809-01)) can be used instead of the M.2 HAT+ and Coral M.2 card. It plugs into a USB 3 (blue) port, but it has **lower performance** than the M.2 version.

> [!NOTE]
> Mouser lists the Coral M.2 Accelerator as **end of life**, but it still has stock. Teams that already have a Pineboards HAT AI! with a Coral **A+E key** card can keep using it; the VEX AI image supports that setup too.

**Setup notes**
- Flash the `vexai-pi5` image to the microSD card.
- Connect the RealSense camera to a USB 3 (blue) port.

---

## Legacy: NVIDIA Jetson Nano

The original Jetson Nano Developer Kit was part of the earlier VEX AI kit. We still publish a `vexai-jetson-nano-legacy` image so teams with this hardware can keep competing. NVIDIA no longer makes the Jetson Nano, so **we do not recommend buying one for a new build**.

**Parts list (per robot)**

| Qty | Part | Manufacturer | Notes |
|-----|------|--------------|-------|
| 1 | Jetson Nano Developer Kit | [NVIDIA](https://developer.nvidia.com/embedded/jetson-nano-developer-kit) | End of life. |
| 1 | Cooling fan for the Jetson Nano | Any 40 mm, 5 V PWM fan | Mounts on the heatsink. |
| 1 | Intel Dual Band Wireless-AC 8265 (M.2 E-key) | [Intel](https://www.intel.com/content/www/us/en/products/sku/94150/intel-dual-band-wirelessac-8265/specifications.html) | Required for the dashboard hotspot. |
| 2 | Wi-Fi antennas (U.FL / IPEX connector) | Any | Attach to the Wi-Fi card. |
| 1 | Lithium battery pack, 5 V / 4 A DC output | Any | Needs a 5.5 mm × 2.1 mm barrel plug. Install the DC_EN jumper. Use this instead of the VEX 3-Wire to barrel plug cable from the original kit. |
| — | [Parts every platform needs](#parts-every-platform-needs) | | RealSense D435, microSD card, cables |

**Setup notes**
- Flash the `vexai-jetson-nano-legacy` image to the microSD card.
- Installation guides: [Connecting and Powering the Jetson](https://kb.vex.com/hc/en-us/articles/360048973491-Connecting-and-Powering-the-Jetson-for-VEX-AI) and [Installing the Intel Dual Band Wi-Fi and Antennas](https://kb.vex.com/hc/en-us/articles/360048489132-Installing-the-Intel-Dual-Band-Wi-Fi-and-Antennas-for-VEX-AI).

---

## VEX hardware

Each robot needs a standard V5 robot (Brain, battery, controller, motors, and so on). The VEX AI system also needs these parts **in addition to** a typical V5 kit:

| Qty per robot | Part | Part number | Why it's needed |
|---------------|------|-------------|-----------------|
| 1 | [V5 GPS Sensor](https://www.vexrobotics.com/276-7405.html) | 276-7405 | Tells the AI processor and the V5 Brain where the robot is on the field. Connects to a V5 Brain Smart Port **and** to the AI processor using the included USB-A to USB-C cable. |
| 1 | [V5 Robot Radio](https://www.vexrobotics.com/276-4831.html) (second radio) | 276-4831 | Used for VEXlink, so your two robots can share data during a match. This is in addition to the radio that connects to the controller and field. |

Your practice field also needs **GPS Field Code strips** around the perimeter for the GPS Sensor to work. See [Mounting the GPS Field Code Strips](https://kb.vex.com/hc/en-us/articles/4402678201620-Mounting-the-GPS-Field-Code-Strips).

---

## More information

- [Getting Started With the VEX AI System](https://kb.vex.com/hc/en-us/articles/360048984271-Getting-Started-With-the-VEX-AI-System)
- [Coding the VEX AI Robot](https://kb.vex.com/hc/en-us/articles/360049619171-Coding-the-VEX-AI-Robot)
- [Best Practices with the GPS Sensor](https://kb.vex.com/hc/en-us/articles/31571899708180-Best-Practices-with-the-GPS-Sensor)
