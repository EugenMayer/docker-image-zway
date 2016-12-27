# WAT
A proper z-way docker image using proper pid1 setu, systemd / upstart.

You find this docker-image on [eugenmayer/zway](https://hub.docker.com/r/eugenmayer/zway)

# Run / use it

```
docker pull eugenmayer/zway
docker run --device=/dev/ttyAMA0:/dev/ttyAMA0 eugenmayer/zway
```

while /dev/ttyAMA0 should reflect your tty UART port on your host. This one should fit a raspberry on a rpi with [disabled bluetooth](https://github.com/EugenMayer/home-assistant-raspberry-zwave/wiki/RPI3.-Raspberry-PI-3---GPIO-Zwave-controller-**only**:-Disable-Bluetooth), see.

# How its made
This image should run the latest image of [z-way](https://github.com/Z-Wave-Me/home-automation) for an ARM based build for e.g. an raspberry pi.
A more brief descriptions can probably be found [here](https://www.z-wave.me/index.php?id=22).

We are based on the official raspbian [docker image](resin/rpi-raspbian:jessie).

# Z-way is ..
Z-way should be compatible with all zwave controllers, be it USB-based or GPIO based, it is not limitted to razberry`s.
It might be, that non z-wave.me based controllers will need a license, see the section 3 on the page, very much below.

You have better informations on this? Open an issue :)

# Hot to run the image on a raspberry pi
See [this howto](https://github.com/EugenMayer/home-assistant-raspberry-zwave/wiki/1.1-Raspbian-OS-with-Docker) on how to get a raspberry pi ready for docker.

# Build it yourself

You have to run this build on an ARM based CPU!
You can use the prebuild one

```
docker pull eugenmayer/zway
```

Of build it yourself

```
git clone https://github.com/EugenMayer/docker-image-zway
cd docker-image-zway
docker-compose build
```

on an RPI or likes
