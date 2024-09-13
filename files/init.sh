#!ALD_PATH/init/safe/busybox sh

ALD_PATH/init/safe/busybox mount -o remount,rw /
if [ "$(ALD_PATH/init/safe/busybox cat ALD_PATH/current)" != "INSERT_DEPLOYMENT" ]; then
    ALD_PATH/init/safe/busybox chattr -i /
    ALD_PATH/init/safe/busybox mkdir -p /usr
    ALD_PATH/init/safe/busybox mkdir -p /etc
    if ALD_PATH/init/safe/exch /usr ALD_PATH/INSERT_DEPLOYMENT/usr; then
        ALD_PATH/init/safe/exch /etc ALD_PATH/INSERT_DEPLOYMENT/etc
        ALD_PATH/init/safe/busybox mv ALD_PATH/INSERT_DEPLOYMENT ALD_PATH/"$(ALD_PATH/init/safe/busybox cat ALD_PATH/current)"
        ALD_PATH/init/safe/busybox echo "INSERT_DEPLOYMENT" > ALD_PATH/current
    fi
fi

mount -o bind,ro /usr /usr
mount -o bind,rw /usr/local /usr/local
ALD_PATH/init/safe/busybox chattr +i /

exec /usr/sbin/init
