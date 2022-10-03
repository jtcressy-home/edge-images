#!/usr/bin/env python3
import os
import re
import subprocess


def slugify(s):
    s = s.lower().strip()
    s = re.sub(r'[^\w\s-]', '', s)
    s = re.sub(r'[\s_-]+', '-', s)
    s = re.sub(r'^-+|-+$', '', s)
    return s

def rpiserial():
    try:
        f = open('/proc/cpuinfo', 'r')
        for line in f:
            if line[0:6]=='Serial':
                cpuserial = line.split(':')[-1].strip()[-8:-1]
                break
        f.close()
    except:
        cpuserial = "ERROR000000000"
    return cpuserial

def rpimfg():
    return "raspberrypi"

def dmiserial():
    serial = subprocess.check_output("dmidecode -s system-serial-number", shell=True)
    return slugify(serial)

def dmimfg():
    mfg = subprocess.check_output("dmidecode -s system-manufacturer", shell=True)
    return slugify(mfg)

if os.path.exists("/sys/firmware/dmi"):
    mfg = dmimfg()
    serial = dmiserial()
    os.system(f"hostnamectl set-hostname {mfg}-{serial}")
elif os.path.exists("/sys/firmware/fdt"):
    mfg = rpimfg()
    serial = rpiserial()
    os.system(f"hostnamectl set-hostname {mfg}-{serial}")
else:
    mfg = "unknown"
    serial = "0"
    os.system(f"hostnamectl set-hostname {mfg}-{serial}")
exit(0)