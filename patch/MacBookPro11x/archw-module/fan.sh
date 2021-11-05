#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# FAN - system fan control
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--fan                ;System fan control
"
fi
if [ "$1" == 'help' ]; then
  echo "
--fan <mode>...      ;System fan control <mode>s
  quiet              ;Fan speed will be as low as possible
  normal             ;Fan speed will act normally depending on CPU load
  turbo              ;Fan will not be affraid to wake up your parents
  <low> <high> <max> ;Manually set fan temp thresholds in celcius
                     ; <low>: Temp at which the fan will run at minimum speed
                     ;<high>: Temp at which the fan will gradually ramp up
                     ; <max>: Temp at which the fan will run at maximum speed
"
fi

#
# Module content
fan () {
  if [ -n "$2" ] && [ -n "$3" ] && [ -n "$4" ]; then
    sudo bash -c "cat > /etc/mbpfan.conf" << EOL
[general]
low_temp = $2
high_temp = $3
max_temp = $4
polling_interval = 1
EOL
    sudo systemctl restart mbpfan.service
    echo "System fan settings has been applied"
    return 0
  elif [[ $2 == 'quiet' ]]; then
    archw --fan 65 80 98
    return 0
  elif [[ $2 == 'normal' ]]; then
    archw --fan 60 70 95
    return 0
  elif [[ $2 == 'turbo' ]]; then
    archw --fan 55 65 85
    return 0
  fi
  error
}
