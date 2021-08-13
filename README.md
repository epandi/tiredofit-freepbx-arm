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
    image: epandi/asterisk-freepbx-arm:17.15.1
    ports:
     #### If you aren't using a reverse proxy
      - 8099:80
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
     ### Give the container access to the dongle/modem if you use Chan_dongle module.(Warning this will expose all usb devices to the container)
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
     #- DB_HOST=freepbx-db
     #- DB_PORT=3306
     #- DB_NAME=asterisk
     #- DB_USER=asterisk
     #- DB_PASS=asteriskpass

     ### If you are using TLS Support for Apache to listen on 443 in the container drop them in /certs and set these:
     #- TLS_CERT=cert.pem
     #- TLS_KEY=key.pem
     ### Set your desired timezone(If not set,UTC will be used as default. 
     #- TZ=TimeZone

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

But, in case you multiple types of devices connected to your host and only want to give dongle access to the container then on your host machine:

```
lsusb -vvv
```
Note the  idVendor(e.g.,067b) & idProduct(e.g.,2303). then again on the host 

```
sudo nano /etc/udev/rules.d/50-dongle.rules
```
and paste
```
SUBSYSTEMS=="usb"
ATTRS{idVendor}=="067b"
ATTRS{idProduct}=="2303"
GROUP="uucp" 
MODE="0666"
```
and 
```
sudo udevadm control --reload
```
or reboot.

At this point your container should've access to the dongle.

Now, you need to shell into the container file 

To get container ID 

'docker ps' list container ID
'docker exec -it <Container ID> /bin/bash

Now,
```
$ asterisk -rvvv
$ lsusb
$ dongle discovery

```
This will output the IMEI & IMSI number of the dongle. Now, type 'exit' in asterisk CLI.

```
$ cd /etc/asterisk/
$ ls
$ nano dongle.conf
```
Sample, dongle.conf:

```
[general]

interval=15			; Number of seconds between trying to connect to devices
smsdb=/var/lib/asterisk/smsdb
csmsttl=600

;------------------------------ JITTER BUFFER CONFIGURATION --------------------------
;jbenable = yes			; Enables the use of a jitterbuffer on the receiving side of a
				; Dongle channel. Defaults to "no". An enabled jitterbuffer will
				; be used only if the sending side can create and the receiving
				; side can not accept jitter. The Dongle channel can't accept jitter,
				; thus an enabled jitterbuffer on the receive Dongle side will always
				; be used if the sending side can create jitter.

;jbforce = no			; Forces the use of a jitterbuffer on the receive side of a Dongle
				; channel. Defaults to "no".

;jbmaxsize = 200		; Max length of the jitterbuffer in milliseconds.

;jbresyncthreshold = 1000	; Jump in the frame timestamps over which the jitterbuffer is
				; resynchronized. Useful to improve the quality of the voice, with
				; big jumps in/broken timestamps, usually sent from exotic devices
				; and programs. Defaults to 1000.

;jbimpl = fixed			; Jitterbuffer implementation, used on the receiving side of a Dongle
				; channel. Two implementations are currently available - "fixed"
				; (with size always equals to jbmaxsize) and "adaptive" (with
				; variable size, actually the new jb of IAX2). Defaults to fixed.

;jbtargetextra = 40		; This option only affects the jb when 'jbimpl = adaptive' is set.
				; The option represents the number of milliseconds by which the new jitter buffer
				; will pad its size. the default is 40, so without modification, the new
				; jitter buffer will set its size to the jitter value plus 40 milliseconds.
				; increasing this value may help if your network normally has low jitter,
				; but occasionally has spikes.

;jblog = no			; Enables jitterbuffer frame logging. Defaults to "no".
;-----------------------------------------------------------------------------------

[defaults]
; now you can set here any not required device settings as template
;   sure you can overwrite in any [device] section this default values

context=default			; context for incoming calls
group=0				; calling group
rxgain=0			; increase the incoming volume; may be negative
txgain=0			; increase the outgoint volume; may be negative
autodeletesms=yes		; auto delete incoming sms
resetdongle=yes			; reset dongle during initialization with ATZ command
u2diag=-1			; set ^U2DIAG parameter on device (0 = disable everything except modem function) ; -1 not use ^U2DIAG command
usecallingpres=yes		; use the caller ID presentation or not
callingpres=allowed_passed_screen ; set caller ID presentation		by default use default network settings
disablesms=no			; disable of SMS reading from device when received
				;  chan_dongle has currently a bug with SMS reception. When a SMS gets in during a
				;  call chan_dongle might crash. Enable this option to disable sms reception.
				;  default = no

language=en			; set channel default language
mindtmfgap=45			; minimal interval from end of previews DTMF from begining of next in ms
mindtmfduration=80		; minimal DTMF tone duration in ms
mindtmfinterval=200		; minimal interval between ends of DTMF of same digits in ms

callwaiting=auto		; if 'yes' allow incoming calls waiting; by default use network settings
				; if 'no' waiting calls just ignored
disable=no			; OBSOLETED by initstate: if 'yes' no load this device and just ignore this section

initstate=start			; specified initial state of device, must be one of 'stop' 'start' 'remote'
				;   'remove' same as 'disable=yes'

exten=+1234567890		; exten for start incoming calls, only in case of Subscriber Number not available!, also set to CALLERID(ndid)

dtmf=relax			; control of incoming DTMF detection, possible values:
				;   off	   - off DTMF tones detection, voice data passed to asterisk unaltered
				;              use this value for gateways or if not use DTMF for AVR or inside dialplan
				;   inband - do DTMF tones detection
				;   relax  - like inband but with relaxdtmf option
				;  default is 'relax' by compatibility reason

; dongle required settings
[dongle0]
audio=/dev/ttyUSB1		; tty port for audio connection; 	no default value
data=/dev/ttyUSB2		; tty port for AT commands; 		no default value

; or you can omit both audio and data together and use imei=123456789012345 and/or imsi=123456789012345
;  imei and imsi must contain exactly 15 digits !
;  imei/imsi discovery is available on Linux only
imei=123456789012345
imsi=123456789012345

; if audio and data set together with imei and/or imsi audio and data has precedence
;   you can use both imei and imsi together in this case exact match by imei and imsi required
```
See, at the bottom there two type of options audio,data and IMEI,IMSI. If you have multiple dongles then fill in the IMEI, IMSI field. 

Credits: 
https://github.com/tiredofit/docker-freepbx
https://wiki.e1550.mobi/doku.php?id=troubleshooting#
https://www.xmodulo.com/change-usb-device-permission-linux.html