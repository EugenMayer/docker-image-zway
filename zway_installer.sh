#!/bin/bash
# installer zway to raspberry

INSTALL_DIR=/opt
ZWAY_DIR=$INSTALL_DIR/z-way-server
TEMP_DIR=/tmp
BOXED=`[ -e /etc/z-way/box_type ] && echo yes`

if [[ $ZWAY_UPIF ]]; then
    write_upi() {
	echo -e $1 > $ZWAY_UPIF
    }
else
    write_upi() {
	true;
    }
fi

##### The percentage of updates #####
write_upi "10%\nStarting upgrading"
#####################################

# Check for root priviledges
if [[ $(id -u) != 0 ]]
then
	echo "Superuser (root) priviledges are required to install Z-Way"
	echo "Please do 'sudo -s' first"
	exit 1
fi

# Accept EULA
if [[ "$BOXED" != "yes" ]]
then
	echo "Do you accept Z-Wave.Me licence agreement?"
	echo "Please read it on Z-Wave.Me web site: http://razberry.z-wave.me/docs/ZWAYEULA.pdf"
	while true
	do
		echo -n "yes/no: "
		read ANSWER < /dev/tty
		case $ANSWER in
			yes)
				break
				;;
			no)
				exit 1
				;;
		esac
		echo "Please answer yes or no"
	done
fi

# Check if Z-Way was already installed in /opt/z-way-server
upgrade_zway="no"
if [[ -d $ZWAY_DIR ]]; then
	upgrade_zway="yes"
else
	echo "z-way-server new installation"
fi

##### The percentage of updates #####
write_upi "20%\nInstalling additional libraries"
#####################################

echo "Installing additional libraries"
apt-get -y update
apt-get -y install sharutils tzdata gawk libc-ares2

##### The percentage of updates #####
write_upi "30%\nInstalling libraries for HomeKit support"
#####################################

echo "Installing additional libraries for HomeKit"
apt-get -y install libavahi-compat-libdnssd-dev

# Check symlinks
if [[ ! -e /usr/lib/arm-linux-gnueabihf/libssl.so ]]
	then
	echo "Making symlinks to libssl.so"
	cd /usr/lib/arm-linux-gnueabihf/
	ln -s libssl.so.1.0.0 libssl.so
fi

if [[ ! -e /usr/lib/arm-linux-gnueabihf/libcrypto.so ]]
	then
	echo "Making symlinks to libcrypto.so"
	cd /usr/lib/arm-linux-gnueabihf/
	ln -s libcrypto.so.1.0.0 libcrypto.so
fi

# Check that libarchive-dev is installed
if [[ ! -e /usr/lib/arm-linux-gnueabihf/libarchive ]]
then
	echo "Installing libarchive-dev"
	apt-get -qy install libarchive-dev
fi

# Check libarchive.so.12 exist
if [[ ! -e /usr/lib/arm-linux-gnueabihf/libarchive.so.12 ]]
then
	echo "Making link to libarchive.so.12"
	ln -s /usr/lib/arm-linux-gnueabihf/libarchive.so /usr/lib/arm-linux-gnueabihf/libarchive.so.12
fi

##### The percentage of updates #####
write_upi "40%\nGetting Z-Way for Raspberry Pi"
#####################################

FILE=`basename z-way-server/z-way-server-RaspberryPiXTools-v2.2.5.tgz`
if [[ -e $TEMP_DIR/$FILE ]]; then
	echo "Removing duplicate of z-way installer"
	rm -rf $TEMP_DIR/$FILE
fi
echo "Getting Z-Way for Raspberry Pi and installing"
wget -4 http://razberry.z-wave.me/z-way-server/z-way-server-RaspberryPiXTools-v2.2.5.tgz -P $TEMP_DIR/

##### The percentage of updates #####
write_upi "50%\nExtracting new z-way-server"
#####################################

# remove z-way-server if exist
rm -rf $TEMP_DIR/z-way-server
# Extracting z-way-server
echo "Extracting new z-way-server"
tar -zxf $TEMP_DIR/$FILE -C $TEMP_DIR

##### The percentage of updates #####
write_upi "60%\nMaking backup and installing Z-Way"
#####################################

# If downloading and extracting is ok, then make backup and move z-way-server from /tmp to /data
if [[ "$?" -eq "0" ]]; then
	# if need upgrade
	if [[ "$upgrade_zway" = "yes" ]]; then
		echo "Previous z-way-server installation found"

		# Stopping z-way-server
		if [[ -e /etc/init.d/z-way-server ]]
		then
			/etc/init.d/z-way-server stop
		fi

		if [[ -e /etc/init.d/Z-Way ]]
		then
			/etc/init.d/Z-Way stop
			rm /etc/init.d/Z-Way
		fi

		# Make backup
		TMP_ZWAY_DIR=${ZWAY_DIR}_$(date "+%Y-%m-%d-%H-%M-%S")
		echo "Making backup of previous version of Z-Way in $TMP_ZWAY_DIR"
		mv $ZWAY_DIR $TMP_ZWAY_DIR
		mv $TEMP_DIR/z-way-server $INSTALL_DIR/

		# Copy old configuration files to the new location
		echo "Copying settings"
		cp $TMP_ZWAY_DIR/config/Configuration.xml $ZWAY_DIR/config/
		cp $TMP_ZWAY_DIR/config/Rules.xml $ZWAY_DIR/config/
		cp -R $TMP_ZWAY_DIR/config/maps $ZWAY_DIR/config/
		cp -R $TMP_ZWAY_DIR/config/zddx $ZWAY_DIR/config/

		if [[ -e $TMP_ZWAY_DIR/automation/.syscommand ]]
			then
			cp $TMP_ZWAY_DIR/automation/.syscommand $ZWAY_DIR/automation/.syscommand
		fi

		if [[ -d $TMP_ZWAY_DIR/automation/storage ]]
			then
			rm -Rf $ZWAY_DIR/automation/storage
			cp -R $TMP_ZWAY_DIR/automation/storage $ZWAY_DIR/automation/
		fi

		if [[ -d $TMP_ZWAY_DIR/automation/userModules ]]
			then
			rm -Rf $ZWAY_DIR/automation/userModules
			cp -R $TMP_ZWAY_DIR/automation/userModules $ZWAY_DIR/automation/
		fi

		if ! diff $ZWAY_DIR/config.xml $TMP_ZWAY_DIR/config.xml -w > /dev/null
		then
			echo "config.xml replaced by the new one - make sure to restore your changes"
			echo "diff $ZWAY_DIR/config.xml $TMP_ZWAY_DIR/config.xml:"
			diff $ZWAY_DIR/config.xml $TMP_ZWAY_DIR/config.xml -w
			echo
		fi
		echo "!!! Defaults.xml and config.xml updated with new versions !!!"
	else
		mv $TEMP_DIR/z-way-server $INSTALL_DIR/
		echo "New version z-way-server installed"
	fi
else
	write_upi "30%\nDownloading and extracting z-way-server failed"

	echo "Downloading and extracting z-way-server failed"
	echo "Exiting"
	exit 1
fi

mkdir -p /etc/z-way
echo "v2.2.5" > /etc/z-way/VERSION
echo "razberry" > /etc/z-way/box_type

# Create Z-Way startup script
echo "Creating Z-Way startup script"
echo '#! /bin/sh
### BEGIN INIT INFO
# Provides:		  z-way-server
# Required-Start:
# Required-Stop:
# Default-Start:	 2 3 4 5
# Default-Stop:	  0 1 6
# Short-Description: RaZberry Z-Wave service
# Description:	   Start Z-Way server for to allow Raspberry Pi talk with Z-Wave devices using RaZberry
### END INIT INFO

# Description: RaZberry Z-Way server
# Author: Yurkin Vitaliy <aivs@z-wave.me>

PATH=/bin:/usr/bin:/sbin:/usr/sbin
NAME=z-way-server
DAEMON_PATH=/opt/z-way-server
PIDFILE=/var/run/$NAME.pid

# adding z-way libs to library path
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/z-way-server/libs

case "$1" in
  start)
	echo -n "Starting z-way-server: "
	start-stop-daemon --start  --pidfile $PIDFILE --make-pidfile  --background --no-close --chdir $DAEMON_PATH --exec $NAME > /dev/null 2>&1
	echo "done."
	;;
  stop)
	echo -n "Stopping z-way-server: "
	start-stop-daemon --stop --quiet --pidfile $PIDFILE
	rm $PIDFILE
	echo "done."
	;;
  restart)
	echo "Restarting z-way-server: "
	sh $0 stop
	sleep 10
	sh $0 start
	;;
  save)
	echo "Saving z-way-server configuration"
	PID=`sed s/[^0-9]//g $PIDFILE`
	/bin/kill -10 $PID
	;;
  *)
	echo "Usage: /etc/init.d/z-way-server {start|stop|restart|save}"
	exit 1
	;;
esac
exit 0' > /etc/init.d/z-way-server
chmod +x /etc/init.d/z-way-server

# Add z-way-server.log to logrotate
echo '/var/log/z-way-server.log {
        daily
        size=10M
        rotate 4
        compress
        nodelaycompress
        missingok
        notifempty
        postrotate
    		/usr/bin/killall -HUP z-way-server 2>/dev/null || true
		endscript
}' > /etc/logrotate.d/z-way-server

# Add Z-Way to autostart
echo "Adding z-way-server to autostart"
update-rc.d z-way-server defaults

# Stop and disable readKey if exist
if [ -f /etc/init.d/readKey ];then
	/etc/init.d/readKey stop
	update-rc.d readKey remove
fi

##### The percentage of updates #####
write_upi "70%\nGetting Webif for Raspberry Pi and installing"
#####################################

# Getting Webif and installing
echo "Getting Webif for Raspberry Pi and installing"
wget -4 http://razberry.z-wave.me/webif_raspberry.tar.gz -O - | tar -zx -C /

# If first install, get new ID
if [[ ! -e /etc/init.d/zbw_connect ]]
	then
	echo "First install, getting Remote ID"
	echo '#!/bin/bash
### BEGIN INIT INFO
# Provides:          zbw_autosetup
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: zbw_autosetup
# Description:       the script setup a zbw_connect script
### END INIT INFO


function delete_me()
{
    insserv -r zbw_autosetup
    rm -f /etc/init.d/zbw_autosetup
    rm -f $0
}

if [[ $0 == "/tmp/zbw_autosetup" ]]; then
    delete_me;
    exit
fi

case "$1" in
    start)
        # if we already have zbw_connect, delete ourself
	if [[ -x /etc/init.d/zbw_connect ]]; then
	    # a hack to eliminate an error on a remouting / ro
	    cp $0 /tmp/zbw_autosetup
	    exec /tmp/zbw_autosetup
	fi

        if wget -4 http://find.zwave.me/zbw_new_user -O /tmp/zbw_connect_setup.run; then
            sleep 10
	    if bash /tmp/zbw_connect_setup.run; then
	        # Update service file for Jessie
	        systemctl daemon-reload
	        /etc/init.d/zbw_connect start
	        # a hack to eliminate an error on a remouting / ro
	        cp $0 /tmp/zbw_autosetup
	        exec /tmp/zbw_autosetup
	    fi
	    mount -o remount,ro /
	fi
	;;
esac
' > /etc/init.d/zbw_autosetup
	chmod +x /etc/init.d/zbw_autosetup
	/etc/init.d/zbw_autosetup start
else
	# Update zbw_connect to new version
	cd /etc/init.d/
	./zbw_connect stop
	echo 'begin-base64 644 zbw_connect_with_out_key
IyEvYmluL2Jhc2gKIyMjIEJFR0lOIElOSVQgSU5GTwojIFByb3ZpZGVzOiAg
ICAgICAgICB6YndfY29ubmVjdAojIFJlcXVpcmVkLVN0YXJ0OiAgICAkYWxs
CiMgUmVxdWlyZWQtU3RvcDogICAgICRhbGwKIyBEZWZhdWx0LVN0YXJ0OiAg
ICAgMiAzIDQgNQojIERlZmF1bHQtU3RvcDogICAgICAwIDEgNgojIFNob3J0
LURlc2NyaXB0aW9uOiB6YndfY29ubmVjdAojIERlc2NyaXB0aW9uOiAgICAg
ICB0aGUgc2NyaXB0IHRvIGNvbm5lY3QgdG8gemJ3IHNlcnZlcgojIyMgRU5E
IElOSVQgSU5GTwoKUElERklMRT0vdmFyL3J1bi96YndfY29ubmVjdC5waWQK
CiMgdGVzdCBhIHdyaXRhYmxlIG9mIC90bXAKaWYgISB0b3VjaCAvdG1wLy56
YndfY29ubmVjdF9yd190ZXN0Owp0aGVuCiAgICBlY2hvICIvdG1wIGlzIG5v
dCB3cml0YWJsZSIgPiYyCiAgICBleGl0IDEKZmkKcm0gLWYgL3RtcC8uemJ3
X2Nvbm5lY3RfcndfdGVzdCAyPi9kZXYvbnVsbCB8fCB0cnVlCgojIGdldCBh
IHVzZXIgcGFzc3dvcmQKUEFTU1dPUkQ9YGNhdCAvZXRjL3pidy9wYXNzd2Rg
CmlmIFtbIC16ICRQQVNTV09SRCBdXTsKdGhlbgogICAgZWNobyAiRGlkbid0
IGZpbmQgcGFzc3dkIGZpbGUiID4mMgogICAgZXhpdCAxCmZpCgojIGdldCBh
IGxvY2FsIHBvcnQKTE9DQUxfUE9SVD1gY2F0IC9ldGMvemJ3L2xvY2FsX3Bv
cnRgCmlmIFtbIC16ICRMT0NBTF9QT1JUIF1dOwp0aGVuCiAgICBlY2hvICJE
aWRuJ3QgZmluZCBsb2NhbF9wb3J0IGZpbGUiID4mMgogICAgZXhpdCAxCmZp
CgojIGdldCBhIGJveCB0eXBlCkJPWFRZUEU9YGNhdCAvZXRjL3otd2F5L2Jv
eF90eXBlYAoKW1sgLXIgL2xpYi9sc2IvaW5pdC1mdW5jdGlvbnMgXV0gJiYg
LiAvbGliL2xzYi9pbml0LWZ1bmN0aW9ucwoKCiMgSWYgc2NyaXB0IGlzIGV4
ZWN1dGVkIGFzIGFuIGluaXQgc2NyaXB0CmNhc2UgIiQxIiBpbgogICAgc3Rh
cnQpCglsb2dfZGFlbW9uX21zZyAiU3RhcnRpbmcgemJ3X2Nvbm5lY3QiCglQ
SUQ9YGNhdCAkUElERklMRSAyPi9kZXYvbnVsbGAKCWlmIFtbICRQSUQgXV07
Cgl0aGVuCgkgICAgTkFNRT1gcHMgLUFvIHBpZCxjb21tIHwgYXdrIC12IFBJ
RD0kUElEICckMSA9PSBQSUQgJiYgJDIgfiAvemJ3X2Nvbm5lY3QvIHsgcHJp
bnQgJDIgfSdgCgkgICAgaWYgW1sgJE5BTUUgXV07CgkgICAgdGhlbgoJCWVj
aG8gImFscmVhZHkgcnVubmluZyIKCQlleGl0CgkgICAgZmkKCWZpCgkobm9o
dXAgc2V0c2lkICQwID4vZGV2L251bGwgMj4mMSAmKQoJbG9nX2FjdGlvbl9t
c2cgIm9rIgoJZXhpdAoJOzsKICAgIHN0b3ApCglsb2dfZGFlbW9uX21zZyAi
U3RvcGluZyB6YndfY29ubmVjdCIKCVBJRD1gY2F0ICRQSURGSUxFIDI+L2Rl
di9udWxsYAoJaWYgW1sgJFBJRCBdXTsKCXRoZW4KCSAgICBmb3IgcGlkIGlu
IGBwcyAtQW8gcGlkLGNvbW0gfCBhd2sgJyQyIH4gL3pid19jb25uZWN0LyB7
IHByaW50ICQxIH0nYDsKCSAgICBkbwoJCVtbICRwaWQgLWVxICRQSUQgXV0g
JiYga2lsbCAtVEVSTSAtJHBpZCAmJiBicmVhawoJICAgIGRvbmUKCWZpCgoJ
cm0gLWYgJFBJREZJTEUKCXJtIC1mIC90bXAvemJ3X2Nvbm5lY3QucHJpdgoJ
bG9nX2FjdGlvbl9tc2cgIm9rIgoJZXhpdCAwCgk7OwogICAgcmVzdGFydCkK
CSQwIHN0b3AKCSQwIHN0YXJ0CglleGl0Cgk7OwogICAgcmVzdGFydF93aXRo
X2RlbGF5KQogICAgICAgIChub2h1cCBzZXRzaWQgJDAgX3Jlc3RhcnRfZGVs
YXllZCAkMiA+L2Rldi9udWxsIDI+JjEgJikKICAgICAgICBleGl0CiAgICAg
ICAgOzsKICAgIF9yZXN0YXJ0X2RlbGF5ZWQpCiAgICAgICAgc2xlZXAgJDIK
ICAgICAgICAkMCBzdG9wCiAgICAgICAgJDAgc3RhcnQKICAgICAgICBleGl0
CiAgICAgICAgOzsKZXNhYwoKIyBDYW4gd2UgcnVuPwpbWyAtZiAvZXRjL3pi
dy9mbGFncy9ub19jb25uZWN0aW9uIF1dICYmIGV4aXQgMAoKZWNobyAkJCA+
ICRQSURGSUxFCgojIEV4dHJhY3QgYSBwcml2YXRlIGtleQpvZmZzZXQ9YHNl
ZCAtZSAnL15TVEFSVF9PRl9FTUJFRERFRF9EQVRBJC8gcScgJDAgfCB3YyAt
Y2AKdG91Y2ggL3RtcC96YndfY29ubmVjdC5wcml2CmNobW9kIDA2MDAgL3Rt
cC96YndfY29ubmVjdC5wcml2CmRkIGlmPSQwIG9mPS90bXAvemJ3X2Nvbm5l
Y3QucHJpdiBicz0kb2Zmc2V0IHNraXA9MSA+L2Rldi9udWxsIDI+JjEKCiMg
U29tZSBjb25zdGFudHMKU0VSVkVSPSJmaW5kLnotd2F2ZS5tZSIKU1NIX1VT
RVI9InJlbW90ZSIKCiMgTWFrZSBmb3J3YXJkIG9wdHMgc3RyaW5nCkZXRF9P
UFRTPSItUiAwLjAuMC4wOjEwMDAwOjEyNy4wLjAuMTokTE9DQUxfUE9SVCIK
aWYgW1sgLWYgL2V0Yy96YncvZmxhZ3MvZm9yd2FyZF9zc2ggXV07CnRoZW4K
ICAgIEZXRF9PUFRTPSIkRldEX09QVFMgLVIgMC4wLjAuMDoxMDAwMToxMjcu
MC4wLjE6MjIiCmZpCgpmdW5jdGlvbiBnZXRfbG9jYWxfaXBzKCkKewogICAg
IyBHZXQgbG9jYWwgaXBzCiAgICBpZiBbWyAteCBgd2hpY2ggaXBgIF1dOyB0
aGVuCglMT0NBTF9JUFM9YGlwIGEgfCBzZWQgLW5yZSAncy9eXHMraW5ldCAo
WzAtOS5dKykuKyQvXDEvOyBUIG47IHA7IDpuJ2AKICAgIGVsaWYgW1sgLXgg
YHdoaWNoIGlmY29uZmlnYCBdXTsgdGhlbgoJTE9DQUxfSVBTPWBpZmNvbmZp
ZyB8IHNlZCAtbnJlICdzL15ccytpbmV0IGFkZHI6KFswLTkuXSspLiskL1wx
LzsgVCBuOyBwOyA6bidgCiAgICBlbHNlCgllY2hvIENhblwndCBnZXQgbG9j
YWwgaXAgYWRkcmVzc2VzID4mMgoJbG9nZ2VyIC10IHpid19jb25uZWN0IENh
blwndCBnZXQgbG9jYWwgaXAgYWRkcmVzc2VzCglleGl0IDEKICAgIGZpCiAg
ICAjIGkgdGhpbmsgZmlsdGVyaW5nIG91dCBvbmx5IDEyNy4wLjAuMSBhZGRy
ZXNzIGlzIHN1ZmZpY2llbnQKICAgIFpCV19JTlRFUk5BTF9JUD0iIgogICAg
Zm9yIGkgaW4gJExPQ0FMX0lQUzsgZG8KCWlmIFtbICRpICE9ICIxMjcuMC4w
LjEiIF1dOyB0aGVuCgkgICAgaWYgW1sgJFpCV19JTlRFUk5BTF9JUCBdXTsg
dGhlbgoJCVpCV19JTlRFUk5BTF9JUD0iJFpCV19JTlRFUk5BTF9JUCwkaSI7
CgkgICAgZWxzZQoJCVpCV19JTlRFUk5BTF9JUD0iJGkiOwoJICAgIGZpCglm
aQogICAgZG9uZQp9CgpleHBvcnQgWkJXX1BBU1NXT1JEPSRQQVNTV09SRApl
eHBvcnQgWkJXX0lOVEVSTkFMX0lQCmV4cG9ydCBaQldfSU5URVJOQUxfUE9S
VD0kTE9DQUxfUE9SVApleHBvcnQgWkJXX0JPWFRZUEU9JEJPWFRZUEUKCndo
aWxlIHRydWUKZG8KICAgIGdldF9sb2NhbF9pcHMKCiAgICBzc2ggLWkgL3Rt
cC96YndfY29ubmVjdC5wcml2IC1UIC1vICdTdHJpY3RIb3N0S2V5Q2hlY2tp
bmcgbm8nIC1vICdVc2VyS25vd25Ib3N0c0ZpbGUgL2Rldi9udWxsJyAtbyAn
QmF0Y2hNb2RlIHllcycgLW8gJ1NlbmRFbnYgWkJXXyonIC1vICJFeGl0T25G
b3J3YXJkRmFpbHVyZSB5ZXMiIC1vICJTZXJ2ZXJBbGl2ZUludGVydmFsIDMw
IiAtbyAiU2VydmVyQWxpdmVDb3VudE1heCAzIiAkRldEX09QVFMgJFNTSF9V
U0VSQCRTRVJWRVIKICAgIHNsZWVwIDEKZG9uZQoKZXhpdCAwCg==
====' | uudecode  -o zbw_connect.new
	tail -n 29 zbw_connect >> zbw_connect.new
	mv zbw_connect.new zbw_connect
	chmod +x zbw_connect
	# Update service file for Jessie
	systemctl daemon-reload
	# Change default zbw port to 8083
	echo "8083" > /etc/zbw/local_port
	echo "zbw_connect patched"
	./zbw_connect start
fi

##### The percentage of updates #####
write_upi "80%\nGetting webserver mongoose for Webif"
#####################################

# Getting webserver mongoose for webif
cd $TEMP_DIR
if [[ -e mongoose.pkg.rPi.tgz ]]; then
	echo "Removing duplicate of mongoose"
	rm -rf mongoose.pkg.rPi.tgz
fi
echo "Getting webserver mongoose for Webif"
wget -4 http://razberry.z-wave.me/mongoose.pkg.rPi.tgz -P $TEMP_DIR

##### The percentage of updates #####
write_upi "90%\nRestarting Webif and Z-Way"
#####################################

# Stopping mongoose
if [[ -e /etc/init.d/mongoose ]]
then
	echo "Stopping mongoose http server"
	/etc/init.d/mongoose stop
fi

# Installing webserver mongoose for webif
tar -zxf $TEMP_DIR/mongoose.pkg.rPi.tgz -C /

# Adding webserver to autostart
echo "Adding mongoose to autostart"
update-rc.d mongoose defaults

# Starting webserver mongoose
echo "Start mongoose http server"
/etc/init.d/mongoose start

# Prepare AMA0
# sed 's/console=ttyAMA0,115200//; s/kgdboc=ttyAMA0,115200//; s/console=serial0,115200//' /boot/cmdline.txt > /tmp/zway_install_cmdline.txt
#
#if [[ -f /etc/inittab ]]
#then
#	sed 's|[^:]*:[^:]*:respawn:/sbin/getty[^:]*ttyAMA0[^:]*||' /etc/inittab > /tmp/zway_install_inittab
#fi

# Disable bluetooth Raspberry Pi 3
#RPI_BOARD_REVISION=`grep Revision /proc/cpuinfo | cut -d: -f2 | tr -d " "`
#if [[ $RPI_BOARD_REVISION ==  "a02082" || $RPI_BOARD_REVISION == "a22082" ]]
#then
#	echo "Raspberry Pi 3 Detected. Disabling Bluetooth"
#	systemctl disable hciuart
#	# Add "dtoverlay=pi3-miniuart-bt" to /boot/config.txt if needed
#	if [[ ! `grep "dtoverlay=pi3-miniuart-bt" /boot/config.txt` ]]
#	then
#		echo "Adding 'dtoverlay=pi3-miniuart-bt' to /boot/config.txt"
#		echo "dtoverlay=pi3-miniuart-bt" >> /boot/config.txt
#	fi
#
#	echo "!!! Update Raspberry Pi 3 Firmware for stability work with commands:"
#	echo "sudo apt-get install rpi-update"
#	echo "sudo rpi-update"
#fi

# Transform old DevicesData.xml to new format
# (cd $ZWAY_DIR && test -x ./z-cfg-update && ls -1 config/zddx/*.xml | LD_LIBRARY_PATH=./libs xargs -l ./z-cfg-update)

#if diff /boot/cmdline.txt /tmp/zway_install_cmdline.txt > /dev/null || diff /etc/inittab /tmp/zway_install_inittab > /dev/null
#then
#	rm /tmp/zway_install_cmdline.txt /tmp/zway_install_inittab
#	# Starting z-way-server mongoose
#	echo "Starting z-way-server"
#	/etc/init.d/z-way-server start
#else
#	echo "Preparing AMA0 interface:"
#	echo " removing 'console=ttyAMA0,115200' and 'kgdboc=ttyAMA0,115200 and 'console=serial0,115200' from kernel command line (/boot/cmdline.txt)"
#	mv /tmp/zway_install_cmdline.txt /boot/cmdline.txt
#	echo " removing '*:*:respawn:/sbin/getty ttyAMA0' from /etc/inittab"
#	mv /tmp/zway_install_inittab /etc/inittab
#	echo "AMA0 interface reconfigured, please restart Raspberry"
#fi

# Make sure to save changes
sync

# Subscribe user to news
if [[ "$BOXED" != "yes" ]]
then
	echo "Do you want to receive emails with news about RaZberry project?"
	echo "! Please subscribe again if you did it before 30.03.2013"
	while true
	do
		echo -n "yes/no: "
		read ANSWER < /dev/tty
		case $ANSWER in
			yes)
				echo -n "Enter your email address: "
				read EMAIL < /dev/tty
				curl -d "email=$EMAIL" http://razberry.z-wave.me/subscribe.php
				break
				;;
			no)
				break
				;;
		esac
		echo "Please answer yes or no"
	done
fi

echo "Thank you for using RaZberry!"

exit 0
