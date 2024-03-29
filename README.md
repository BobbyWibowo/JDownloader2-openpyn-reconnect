# JDownloader2-openpyn-reconnect

A small utility to hook [openpyn-nordvpn](https://github.com/jotyGill/openpyn-nordvpn) into JDownloader2 to facilitate auto-rotating NordVPN (via OpenVPN) servers, to bypass IP bandwidth limit on certain file hosts that have them.

This was written to target MEGA's download bandwidth limit issue in particular, so no guarantee it will simply work as-is with other file hosts that have similar bandwidth limit concept.

## Disclaimer

**I'm not a bash expert.**

**During the writing of this script, countless searches in StackOverflow and Unix StackExchange had to be done.**

**And since this script needs root/sudo access, please consult the codes and use at your own risk. I'm not responsible for any damages done to your machine.**

Unless you want to run JDownloader2 as root (not recommended), `jd2opreconnect.sh` needs to be permitted in your sudoers file to be able to run unattended, e.g:

```conf
%sudo ALL=(root) NOPASSWD:/path/to/jd2opreconnect.sh
```

Why? `openpyn` itself requires root/sudo access.

When adding a script into sudoers file, you still need to run said script with sudo afterwards. It will just then run without prompting for auth (thus `run-logged.sh` and `run-silent.sh` explicitly use sudo inside).

## Configuration

Modify `COUNTRY` variable within the script to set which country's servers the script will rotate through.

This needs to be set, since from my experience, MEGA typically breaks resuming download if the IPs are of different countries.

This also means that you need to choose a country that have at least 2 servers.

## Installation

In your JDownloader2, do all of the following (adapt if required):

Settings > Reconnect > General Reconnect Options > Tick **Auto Reconnect Enabled**

Settings > Reconnect > Reconnect Method > Pick **External Tool Reconnect**

Settings > Reconnect > Reconnect Method > Command > Fill in `/path/to/run-logged.sh` or `/path/to/run-silent.sh`

Settings > Advanced Settings > Search for **Reconnect: Seconds Before First IP Check** > Fill in `15` or more. The script needs some time to fetch servers list and reconnecting. You can try to run `sudo ./jd2opreconnect.sh` directly in your terminal and see how long it takes for your system to reconnect in average.

Settings > Plugins > `mega.co.nz` > **Set preferred limit mode** > Pick **Global: Wait or get new IP** (its default value will not trigger JDownloader2's Auto-Reconnect feature).

Settings > Plugins > `mega.co.nz` > **Max. wait time on limit reached** > Set `10` (it should be fine to set this even lower if the plugin ever allows you to in future updates).

You may have to find similar options as the above in other file hosts' plugins.
