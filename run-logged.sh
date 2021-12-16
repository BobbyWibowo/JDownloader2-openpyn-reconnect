#!/usr/bin/env /bin/bash

# TERM=dumb disables color output for logging into text file
sudo TERM=dumb ./jd2opreconnect.sh 2>&1 > "logs/$(date).log"
