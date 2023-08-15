#!/bin/bash
# this script will read voltage of battery from beepy
# convert to a percentage, assuming 3.2v is 0% and 4.2% is maximum
# sudo modprobe -r bbqX0kbd
# this re-enables it
# sudo modprobe bbqX0kbd
# maybe this should be reconfigured to blink or solid show batt% color
# when side button pressed|held?
# disable keyboard for battery poll and RGB update
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
sudo modprobe -r bbqX0kbd
V=$(i2cget -y 1 0x1F 0x17 w | sed s/0x// | tr '[:lower:]' '[:upper:]')
V=$(echo "obase=10; ibase=16; $V" | bc)

min_volt=3.2
max_volt=4.2
# using 3.3 as the reference voltage here
# tricorder arduino had to use 3.6 as reference mult after a firmware update
batt_volt=$(echo "$V * 3.6 * 2 / 4095" | bc -l | cut -c1-5)
now_volt=$batt_volt
if ((`echo $now_volt '<' $min_volt|bc`)); then
  now_volt=$min_volt
fi

if ((`echo $now_volt '>' $max_volt|bc`)); then
  now_volt=$max_volt
fi
# now_volt=$((batt_volt > max_volt ? max_volt : batt_volt))
# now_volt=$((now_volt < min_volt ? min_volt : now_volt))
# echo $(($batt_volt-$min_volt))
percent=$(awk -v min=$min_volt -v now=$now_volt -v max=$max_volt \
'BEGIN { printf("%d\n", ((now-min)/(max-min))*100) }')

# battpct=42
battpct=percent
brightness=0.3
# 0xA1 -> red write, 0xA2 -> green write, 0xA3 -> blue write
# 80 = 128 (255/2)
# 55 = 85 (255/3)
# 4B = 75 (224/3)
# 43 = 67 (112/255) *.3
# 40 = 64 (96/255) *.3
# sudo modprobe -r bbqX0kbd
if ((battpct>80)); then
  # blue, 0|0|255*.3
  sudo i2cset -y 1 0x1F 0xA1 0x00
  sudo i2cset -y 1 0x1F 0xA2 0x00
  sudo i2cset -y 1 0x1F 0xA3 0x80
elif ((battpct>60)); then
  # green, 0|255*.3|0
  sudo i2cset -y 1 0x1F 0xA1 0x00
  sudo i2cset -y 1 0x1F 0xA2 0x80
  sudo i2cset -y 1 0x1F 0xA3 0x00
elif ((battpct>40)); then
  # yellow, 67 (112/255)*.3|85 (128/255)*.3|0
  sudo i2cset -y 1 0x1F 0xA1 0x43
  sudo i2cset -y 1 0x1F 0xA2 0x80
  sudo i2cset -y 1 0x1F 0xA3 0x00
elif ((battpct>20)); then
  # orange, 85 (128/255)*.3|64 (96/255)*.3|0
  sudo i2cset -y 1 0x1F 0xA1 0x80
  sudo i2cset -y 1 0x1F 0xA2 0x40
  sudo i2cset -y 1 0x1F 0xA3 0x00
else
  # red, 85 (128/255)*.3|0|0
  sudo i2cset -y 1 0x1F 0xA1 0x80
  sudo i2cset -y 1 0x1F 0xA2 0x00
  sudo i2cset -y 1 0x1F 0xA3 0x00
fi
# turns LED on. use 0xFF for on, 0x00 for off
sudo i2cset -y 1 0x1F 0xA0 0xFF
# this re-enables it
sudo modprobe bbqX0kbd

# while true
# do
# set_rgb percent
# poll once per minute maximum
# sleep 60
# done
# to-do: remove while/sleep and just set this up as a cron job?
# * * * * * /home/batteryLED.sh
