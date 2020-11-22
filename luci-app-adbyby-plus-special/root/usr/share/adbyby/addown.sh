#!/bin/sh
	[ "$1" != "--down" ] && exit 1
	# 防止重复启动
	[ -f /var/lock/adbyby.lock ] && exit 1
	touch /var/lock/adbyby.lock

	if ! mount | grep adbyby >/dev/null 2>&1;then
		/etc/init.d/adbyby start &
		exit 1
	fi

	for a in $(opkg print-architecture | awk '{print $2}'); do
		case "$a" in
			all|noarch)
				;;
			arm_arm1176jzf-s_vfp|arm_arm926ej-s|arm_fa526|arm_xscale|armeb_xscale)
				ARCH="arm"
				P="2p"
				;;
			aarch64_cortex-a53|aarch64_cortex-a72|aarch64_generic|arm_cortex-a15_neon-vfpv4|arm_cortex-a5_neon-vfpv4|arm_cortex-a7_neon-vfpv4|arm_cortex-a8_vfpv3|arm_cortex-a9|arm_cortex-a9_neon|arm_cortex-a9_vfpv3|arm_mpcore|arm_mpcore_vfp)
				ARCH="armv7"
				P="4p"
				;;
			mips_24kc|mips_mips32|mips64_mips64|mips64_octeon)
				ARCH="mips"
				P="6p"
				;;
			mipsel_24kc|mipsel_24kec_dsp|mipsel_74kc|mipsel_mips32|mipsel_1004kc_dsp)
				ARCH="mipsel"
				P="8p"
				;;
			x86_64)
				ARCH="x64"
				P="10p"
				;;
			i386_pentium|i386_pentium4)
				ARCH="x86"
				P="12p"
				;;
			*)
				echo_date "不支持当前CPU架构 $a"
				exit 1
				;;
		esac
	done

	rm -f /usr/share/adbyby/adbyby /usr/share/adbyby/md5 /usr/share/adbyby/adbyby_adblock/dnsmasq.adblock
	while : ; do
		wget --no-hsts -T 3 -O /usr/share/adbyby/adbyby https://small_5.coding.net/p/adbyby/d/adbyby/git/raw/master/$ARCH
		if [ "$?" == "0" ];then
			chmod +x /usr/share/adbyby/adbyby
			break
		else
			sleep 2
		fi
	done

	while : ; do
		wget --no-hsts -T 3 -O /usr/share/adbyby/md5 https://small_5.coding.net/p/adbyby/d/adbyby/git/raw/master/md5
		if [ "$?" == "0" ];then
			break
		else
			sleep 2
		fi
	done

	md5_local=$(md5sum /usr/share/adbyby/adbyby | awk -F' ' '{print $1}')
	md5_online=$(sed 's/":"/\n/g' /usr/share/adbyby/md5 | sed 's/","/\n/g' | sed -n "$P")
	rm -f /usr/share/adbyby/md5
	[ "$md5_local"x != "$md5_online"x ] && rm -f /usr/share/adbyby/adbyby

	if [ "$(head -1 /usr/share/adbyby/data/lazy.txt | awk -F' ' '{print $3,$4}')" == "2017-1-2 00:12:25" ];then
		while : ; do
			wget --no-hsts -T 3 -O /tmp/lazy.txt https://cdn.jsdelivr.net/gh/adbyby/xwhyc-rules/lazy.txt
			if [ "$?" == "0" ];then
				cp -f /tmp/lazy.txt /usr/share/adbyby/data/lazy.txt
				rm -f /tmp/lazy.txt
				break
			else
				sleep 2
			fi
		done
		while : ; do
			wget --no-hsts -T 3 -O /tmp/video.txt https://cdn.jsdelivr.net/gh/adbyby/xwhyc-rules/video.txt
			if [ "$?" == "0" ];then
				cp -f /tmp/video.txt /usr/share/adbyby/data/video.txt
				rm -f /tmp/video.txt
				break
			else
				sleep 2
			fi
		done
	fi

	if [ "$(uci -q get adbyby.@adbyby[0].wan_mode)" == "1" ];then
		mkdir -p /usr/share/adbyby/adbyby_adblock
		while : ; do
			wget --no-hsts -T 3 -O /usr/share/adbyby/adbyby_adblock/dnsmasq.adblock https://small_5.coding.net/p/adbyby/d/adbyby/git/raw/master/dnsmasq.adblock
			[ "$?" == "0" ] && break || sleep 2
		done

		while : ; do
			wget --no-hsts -T 3 -O /usr/share/adbyby/md5 https://small_5.coding.net/p/adbyby/d/adbyby/git/raw/master/md5_1
			if [ "$?" == "0" ];then
				break
			else
				sleep 2
		fi
		done
		md5_local=$(md5sum /usr/share/adbyby/adbyby_adblock/dnsmasq.adblock | awk -F' ' '{print $1}')
		md5_online=$(sed 's/":"/\n/g' /usr/share/adbyby/md5 | sed 's/","/\n/g' | sed -n '2P')
		rm -f /usr/share/adbyby/md5
		[ "$md5_local"x != "$md5_online"x ] && rm -rf /usr/share/adbyby/adbyby_adblock
	fi

	rm -f /var/lock/adbyby.lock
	/etc/init.d/adbyby start &
