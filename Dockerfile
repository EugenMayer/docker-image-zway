FROM resin/rpi-raspbian:jessie

# thank you for https://github.com/WATTx/iot-gateway-zway-server-docker/blob/master/Dockerfile
# as beein my starting point

# needed to autoate the zway installation
ENV BOXED yes
ENV INSTALL_DIR /opt

# upgrade and install all the libs zway needs ourself in one go
RUN apt-get update && apt-get upgrade -y && apt-get install -y rpi-update \
 && apt-get install -y install sharutils tzdata gawk libc-ares2 libavahi-compat-libdnssd-dev libarchive-dev
# /etc/z-way/box_type will put the script into boxed mode - automated install
RUN touch /etc/z-way/box_type &&
 wget -q -O http://razberry.z-wave.me/install | bash

# seems like in the end http://razberry.z-wave.me/z-way-server/z-way-server-RaspberryPiXTools-v2.2.5.tgz is used
# as the zway-server

# then it installs the webinterface http://razberry.z-wave.me/webif_raspberry.tar.gz with mongoose as webserver http://razberry.z-wave.me/mongoose.pkg.rPi.tgz

ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/z-way-server/libs

# stop all the systemd services, since we need to do this differently with docker
RUN /etc/init.d/mongoose stop && /etc/init.d/z-way-server stop \
 && update-rc.d z-way-server remove && update-rc.d mongoose remove &&
 && apt-get install -y supervisor && mkdir -p /var/log/supervisor \

COPY supervisor/supervisor_main.conf /etc/supervisor/conf.d/main.conf
COPY supervisor/mongoose.conf /etc/supervisor/conf.d/mongoose.conf
COPY supervisor/zway-server.conf /etc/supervisor/conf.d/zway-server.conf

ENTRYPOINT ["/usr/bin/supervisord", "-c"]
CMD ["/etc/supervisor/supervisord.conf"]