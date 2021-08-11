# FreePBX 15, Asterisk 17/18 on Docker (Raspberry Pi). 

Properly working with IVR and call forwarding to an extension on a Raspberry pi 4 32-bit architecture.

Quick tips:
No 2-way sound on outgoing calls but sound is available on inbound calls? Check if the RTP start/end ports in "Settings - Asterisk SIP Settings" match the ports defined in the docker-compose file.
Check documentation on: https://hub.docker.com/r/tiredofit/freepbx

Changelog:
26-03-2021 - tag 18.15-alpha:

Asterisk 18.3.0
FreePBX 15.0.17.24
PHP 7.3
Tested with IVR / Queues / Conferences
24-03-2021 - tag 17.15.2 / 17.15-latest:

updated Asterisk to 17.9.3
FreePBX 15.0.16.56
PHP 5.6
ODBC mariadb driver updated to self compiled version instead of using the deprecated mysql driver
XMPP is now installing and the daemon is running after integrating an armv7 mongodb supported version and tweeking some startup scripts
Not working:
FOP - automatic intallation script can't find the proper package.
Example docker-compose.yaml (change tag to 18.15-alpha instead of 17.15-latest, if you want Asterisk 18 instead of Asterisk 17)

```
version: '2'

services:
  freepbx-app:
    container_name: freepbx-app
    image: epandi/asterisk-freepbx-arm:17.15-latest
    ports:
     #### If you aren't using a reverse proxy
      - 80:80
     #### If you want SSL Support and not using a reverse proxy
     #- 443:443
      - 5060:5060/udp
      - 5160:5160/udp
      - 18000-18100:18000-18100/udp
     #### Flash Operator Panel
      - 4445:4445
    volumes:
      - /home/pi/Docker/asterisk17/certs:/certs
      - /home/pi/Docker/asterisk17/data:/data
      - /home/pi/Docker/asterisk17/logs:/var/log
      - /home/pi/Docker/asterisk17/data/www:/var/www/html
     ### Only Enable this option below if you set DB_EMBEDDED=TRUE
      - /home/pi/Docker/asterisk17/db:/var/lib/mysql
     ### You can drop custom files overtop of the image if you have made modifications to modules/css/whatever - Use with care
     #- ./assets/custom:/assets/custom
     ### Only Enable this if you use Chan_dongle/USB modem.
     #- /dev:/dev

    environment:
      - VIRTUAL_HOST=asterisk.local
      - VIRTUAL_NETWORK=nginx-proxy
     ### If you want to connect to the SSL Enabled Container
     #- VIRTUAL_PORT=443
     #- VIRTUAL_PROTO=https
      - VIRTUAL_PORT=80
      - LETSENCRYPT_HOST=hostname.example.com
      - LETSENCRYPT_EMAIL=email@example.com

      - ZABBIX_HOSTNAME=freepbx-app

      - RTP_START=18000
      - RTP_FINISH=18100

     ## Use for External MySQL Server
      - DB_EMBEDDED=TRUE

     ### These are only necessary if DB_EMBEDDED=FALSE
     # - DB_HOST=freepbx-db
     # - DB_PORT=3306
     # - DB_NAME=asterisk
     # - DB_USER=asterisk
     # - DB_PASS=asteriskpass

     ### If you are using TLS Support for Apache to listen on 443 in the container drop them in /certs and set these:
     #- TLS_CERT=cert.pem
     #- TLS_KEY=key.pem
     ### Set your desired timezone
      - TZ= 'TimeZone'
    restart: always
    network_mode: "bridge"

    ### These final lines are for Fail2ban. If you don't want, comment and also add ENABLE_FAIL2BAN=FALSE to your environment
    cap_add:
      - NET_ADMIN
    privileged: true
```
# Accessing the USB modem:

You need to use sudo chmod 777 /dev/ttyUSB* on the host machine. 
But, this is not persistent after reboot. To make it persistent after boot on your host machine

sudo nano /etc/udev/rules.d/92-dongle.rules and add 
```
KERNEL=="ttyUSB*"
MODE="0666"
OWNER="asterisk"
GROUP="uucp"
```
This will make the permission persistent. Source: https://wiki.e1550.mobi/doku.php?id=troubleshooting#

Credits https://github.com/tiredofit/docker-freepbx
