#!/usr/bin/env bash

interface="wlp3s0"
config_dir="~/.config/polybar/$1/scripts/rofi"

list_networks() {
  nmcli -t -f SSID,SECURITY dev wifi list ifname $interface | awk -F: '!seen[$1]++{print "📶 " $1 " - " $2}'
}

display_message() {
  rofi -e "$0" -no-config -theme "$config_dir/confirm.rasi"
}

choose_network() {
  networks=$(list_networks)
  chosen_network=$(echo -e "$networks" | rofi -dmenu -theme "$config_dir/networkmenu.rasi" -p "Wi-Fi Networks")

  if [ "$chosen_network" ]; then
    ssid=$(echo "$chosen_network" | awk -F' - ' '{print $1}' | sed 's/📶 //')

    security=$(echo "$chosen_network" | awk -F' - ' '{print $2}')
    if [ "$security" != "--" ]; then
      pass=$(rofi -dmenu -password -theme "$config_dir/networkmenu.rasi" -p "Password for $ssid")
    fi

    if [ -n "$pass" ]; then
      nmcli dev wifi connect "$ssid" password "$pass" ifname $interface
    else
      nmcli dev wifi connect "$ssid" ifname $interface
    fi

    if [ $? -eq 0 ]; then
      display_message "Connected to $ssid."
    else
      display_message "Error connecting to $ssid."
    fi
  fi
}

current_network=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d ':' -f2)
choose_network
