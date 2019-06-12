# CSpoons repo

Spoons for the superb [hammerspoon](https://www.hammerspoon.org) project.

## CMeters

Creates circles on desktop (or overlay)
requires **Python 3** to be installed and **psutils**, i.e. after install [Python 3](https://www.python.org/downloads/) do

`
pip3 install psutils
`
 in your Terminal

You can customize the rings in the init.lua under obj.rings.
Please note that drawing too many rings might drain your cpu.

Currently supported are *cpu* and *network* monitors.

You might need to adjust max and min values for network traffic in order to see something.

## CMover

Another window mover that supports multiple monitors.
Not fully functional yet.
