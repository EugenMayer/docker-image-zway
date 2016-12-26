#!/bin/bash

echo "this little thingky calls back the z.wave.me servers to open a tunnel - you really do want to do this?"

# Can we run?
[[ -f /etc/zbw/flags/no_connection ]] && exit 0

echo $$ > $PIDFILE

# Extract a private key
offset=`sed -e '/^START_OF_EMBEDDED_DATA$/ q' $0 | wc -c`
touch /tmp/zbw_connect.priv
chmod 0600 /tmp/zbw_connect.priv
dd if=$0 of=/tmp/zbw_connect.priv bs=$offset skip=1 >/dev/null 2>&1

# Some constants
SERVER="find.z-wave.me"
SSH_USER="remote"

# Make forward opts string
FWD_OPTS="-R 0.0.0.0:10000:127.0.0.1:$LOCAL_PORT"
if [[ -f /etc/zbw/flags/forward_ssh ]];
then
    FWD_OPTS="$FWD_OPTS -R 0.0.0.0:10001:127.0.0.1:22"
fi

function get_local_ips()
{
    # Get local ips
    if [[ -x `which ip` ]]; then
	LOCAL_IPS=`ip a | sed -nre 's/^\s+inet ([0-9.]+).+$/\1/; T n; p; :n'`
    elif [[ -x `which ifconfig` ]]; then
	LOCAL_IPS=`ifconfig | sed -nre 's/^\s+inet addr:([0-9.]+).+$/\1/; T n; p; :n'`
    else
	echo Can\'t get local ip addresses >&2
	logger -t zbw_connect Can\'t get local ip addresses
	exit 1
    fi
    # i think filtering out only 127.0.0.1 address is sufficient
    ZBW_INTERNAL_IP=""
    for i in $LOCAL_IPS; do
	if [[ $i != "127.0.0.1" ]]; then
	    if [[ $ZBW_INTERNAL_IP ]]; then
		ZBW_INTERNAL_IP="$ZBW_INTERNAL_IP,$i";
	    else
		ZBW_INTERNAL_IP="$i";
	    fi
	fi
    done
}

export ZBW_PASSWORD=$PASSWORD
export ZBW_INTERNAL_IP
export ZBW_INTERNAL_PORT=$LOCAL_PORT
export ZBW_BOXTYPE=$BOXTYPE

while true
do
    get_local_ips

    ssh -i /tmp/zbw_connect.priv -T -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' -o 'BatchMode yes' -o 'SendEnv ZBW_*' -o "ExitOnForwardFailure yes" -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" $FWD_OPTS $SSH_USER@$SERVER
    sleep 1
done

echo "this little thingky calls back the z.wave.me servers to open a tunnel - you really do want to do this?"

exit 0

START_OF_EMBEDDED_DATA
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA55DMf26Cr+cwFiQEGRFfGV/goP+hUBcJI3bI05ERx1l2S7Rj
4ppTYCvziWYScdZr4YWFn4EZDVEylj+uvh/rwhDEaq3LGuOsrQQ1gm4jfcurWwAy
SqmfZiRNEw3W34SPTX1jSnSPQFqGtpuA3dmZ09oOp10epaXdEoUM7V+1PMQiXAhp
R5CLl9YAl4/DkUhxyvCkraCSSGJq7GEDSbX+2EY8htFxOMVZXdEsheoB9Xn6L923
R2eJrDxZaAbmRPuaD5mBOq8UAY56q7Oag+oA7AizBZbQnXWEfgLcJLhTibM6AJXS
SNIM/D6fqY0jIrABa9jaOvtkjkrbUum1JPDAhwIDAQABAoIBAFFTyI6k2F9BGeFc
ytenAzhdNP42aYhAXuRGrqenVpAl+mcCNuZ5/vhS11iVMbsrbH4rL8/iPlMwBk1A
lnWNrnZc/y7cVO3fsmCdjtF9LxfaNRdjzUXtpt7vtuYPQT0FSHMVq46Vu04FvTRb
DvpblywRdH4RNVdGFouPkQe5SmTJbnG63zj+4oPvLJj+wuKfawJcdVHoT9g/HBhT
i/tu3cDlGkBh3PEj3PApPqSMz9fUQzjE/QuuX5YDnfZzhv7MR1upYeY0Tc+gThK8
NxQZHxrZIgX65J55dZRMiD64v1/uxyZC1fBFKzhxxZUT0tC0jItkZ8B530HpnLa5
pWsfsDkCgYEA/6V+Z66KFM6w2/7IWe8uArS9v0bCmAmHM7eAPm+Egp/kpXbN25CN
gnukatdZmOYkjj2knKkeVDkm9eOiHncVWYohFfFFLbHtsXP4Asq3KBjiBGplNuGI
DeIU6xm34FdVAnT5JyAPKtc49B+MS+jfs1TTq/EejOu0caDLjpPUHZ0CgYEA5+LH
nNqtsSKG0s1Zg+7X2W28jy2olSCVB9q8h4N2xkkk3HW0AGWe12I75WXJUYHNZXvb
re+KSwLeiMPDObEwn+JG60N43rchTnj2G9RhC+BIppX6dgcXNFLJ3b48f2xyUFvM
OZbQevqw6yM36HLBYFHkA0TlLQL5XxH/ldBUT3MCgYA4/ZnKX1yk+tbulEPx2KI3
NDfAtnOXFTiwzM2oHZA61o5QXMXTlswVNJ8Yul1c+qFXnGJgEkuSlxMaad6wT/fQ
eDyb+adkYnAMyT+Wz745ECMCvP1HWMvN3IKxTpBxUMbAv3bzw+/dqxElSwspuQZ1
ogl2IVCgNcOKOUBnzojQ+QKBgQCoQCQV65WbsTGiQt1wnRyA5t6qBLcNfValHFEv
AnRr6yaTz9OLdjCKlvxetjwcp9IgkH4U9nmhc7OECIbelXJyj/xlN8+7yaShC6OH
DdJci6ArPyc7/GkZzfgqrJ241zcal4DXSFZ85Oj5s9QdFSa6fLC0roia4E2Qbb7F
NSP3gQKBgQDoBSaS7L7QQStE1pyg3PF4/e/v0TOVsy1CL8PNl0vo0PBMZRayMngY
clp0OpivhrWTaG5eF4AbjLJbLzpuSEvOW2v+yRw3vtJgzeCuVh9VUzWlbkiqzYZt
MnHJHpatU8ZRB3ciPiTZcVTMLNhDpKT4ICo1NZXY0Ifh3pTho4om7Q==
-----END RSA PRIVATE KEY-----