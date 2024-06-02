# A Collection of Scripts

## Over the years of maintaining my home lab, I have found it necessary to automate certain processes. This repository will serve as a collection of scripts that I have created and am currently using on my systems that may also be of use on other systems.

### Installed

This is the primary folder where I put any scripts I intend to install to the system. I install the scripts by creating symlinks in the */usr/bin* directory.

#### Installed/genThumbCustom.sh

> This interactive script will generate thumbnails for all .mp4 or .mov video files in a directory and all sub directories. By essentially wrapping around the ffmpeg command, this script allows you to choose the timestamp, size, and output format of the the thumbnail. It works by creating a custom ffmpeg command for each video file based on the parameters chosen by the user. It will then generate a script containing all of the ffmpeg commands for all of the files, run the script, and delete the script. All thumbnails will have the same name of the video file from which they were extracted with a file extension matching the chosen output format.

> The script is currently completely interactive and does not take any arguments. You can thus run it from any directory as it will prompt you to supply the target directory.

#### Installed/genThumb-00-00-20.sh

> This script is a duplicate of the genThumbCustom.sh script. However, this script is setup to grab thumbnails from the 20 second time mark and only requires a target path as input.

#### Installed/notify.sh

> This script sends an api request with the curl command to a self hosted NTFY server so that I can send notifications from the terminal. I utilize this script in other scripts so I can receive notifications for when things like automated backups either complete successfully or run into errors.

### Installed/DNS

This sub directory contains a mini suite of scripts that I use to automate the process of adding a DNS entry to a self hosted Bind9 DNS server.

A DNS entry in a forward zone configuration file looks something like this:

```zsh
hostname            IN    A       111.111.111.111
```

While an entry in a reverse zone configuration file looks something like this:

```zsh
111       IN        PTR       hostname.domain
```

At the time, I needed to get things running on a system with limited resources. I wanted to get experience writing scripts and automatically configuring things. So I wrote a script to essentially generate entries based on user input that resemble the above format, place them at specific locations in the configuration files based on user input, and restart the service that handles the DNS server.

All scripts in this folder are interactive but all necessary inputs can be passed directly to be used in other scripts. The naming convention for all DNS entries is [SERVERNAME].[HOSTNAME].[DOMAIN]. The server name basically describes what is being accessed at that domain while the hostname describes what machine that service is being hosted on. So for an NTFY server hosted on a machine with a hostname of testcomputer in a domain of local, that would be equal to ntfy.testcomputer.local. Most entries will be of type server.host.domain. But in the case of physical servers, entries will be of type host.domain. This enables me to organize the configuration file and quickly navigate to entries for specific services on specific servers. From this point onward, a service entry will refer to an entry of type server.host.domain while a host entry will refer to an entry of type host.domain.

You will want to supply the full path to your Bind9 or other configuration files of similar syntax to the following variables in order for these scripts to work.

- $FORWARDZONE
- $REVERSEZONE

These scripts will need to be run as root since they will most likely be editing files in the /etc directory and will be managing system services.

#### Installed/DNS/addLocalHostDNS.sh

> This script handles adding new host entries to the Bind9 DNS server configuration files. This script essentially places a host entry underneath another host entry or service entry based on user input. Because of this, it requires the most arguments of all the scripts.

- $INITHOST   - This is the hostname of the machine in the configuration file you would want the new entry to be placed under.
- $INITSERVER - This is the name of the service, if applicable, for the service entry you would want the new entry to be placed under. Omitting this value will cause the script to assume that you are placing the new host entry underneath a previous host entry.
- $INITIP     - This is the ip address of the machine in the configuration file you would want the new entry to be placed under.
- $HOST       - This is the hostname of the machine for which the current entry is being created.
- $IP         - This is the ip address of the machine for which the current entry is being created..
- $SERIES     - This determines whether or not the script will add a comment above the host entry describing the category of entries to follow.
- $TITLE      - If this is the first of a series of entries, you will be prompted for a title for that series which will create a comment in each configuration file above the entry.

#### Installed/DNS/addServerDNS.sh

> This script handles adding service entries to the Bind9 DNS server configuration files. This script is the most lightweight script because it depends on the presence of host entries. It essentially adds a service entry for a specified host entry by appending it to the list of entries underneath that host entry.

- $HOST       - This is the hostname of the machine for which the current entry is being created.
- $SERVER     - This is the name of the service for which the current entry is being created.
- $IP         - This is the ip address of the machine for which the current entry is being created.

#### Installed/DNS/rmLocalDNS.sh

> This script handles removing service and host entries from the Bind9 DNS server configuration files. This script uses the sed command to find all lines with service or host names and ip addresses matching the users input. As such, it is great for removing duplicate entries create by the previous two scripts. It is also equipped to remove a host series by deleting the comment denoting the series. It can also deal with isolated hosts. This happens when a host entry exists in the configuration file with no service entries underneath it. If yes is selected for the isolated host prompt, the script will remove an extra line to make sure that the configuration file stays neat an tidy.

- $HOST       - This is the hostname of the machine for the current entry being removed.
- $SERVER     - This is the name of the service for the current entry being removed. Omitting this value will cause the script to remove a host entry instead of a service entry.
- $IP         - This is the ip address of the machine for the current entry being removed.
- $SERIES     - This will determine whether or not the script will remove an extra line above the entry to remove the comment describing a series of entries.
- $ISOLATED   - This will determine whether or not the script will remove an extra line below the entry when deleting the entry to maintain formatting after removing the host.

