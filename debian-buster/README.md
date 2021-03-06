# hub.docker.com/tiredofit/debian

[![Build Status](https://img.shields.io/docker/build/tiredofit/debian.svg)](https://hub.docker.com/r/tiredofit/debian)
[![Docker Pulls](https://img.shields.io/docker/pulls/tiredofit/debian.svg)](https://hub.docker.com/r/tiredofit/debian)
[![Docker Stars](https://img.shields.io/docker/stars/tiredofit/debian.svg)](https://hub.docker.com/r/tiredofit/debian)
[![Docker Layers](https://images.microbadger.com/badges/image/tiredofit/debian.svg)](https://microbadger.com/images/tiredofit/debian)

## Introduction

Dockerfile to build an [debian](https://www.debian.org/) container image.

* Currently tracking Jessie (8), Stretch (9), Buster (10).
* [s6 overlay](https://github.com/just-containers/s6-overlay) enabled for PID 1 init capabilities.
* [zabbix-agent](https://zabbix.org) for individual container monitoring.
* Cron installed along with other tools (curl, less, logrotate, nano, vim) for easier management.
* Ability to update User ID and Group ID permissions for development purposes dynamically.

## Authors

- [Dave Conroy](dave at tiredofit dot ca) [https://github.com/tiredofit]

## Table of Contents

- [Introduction](#introduction)
- [Authors](#authors)
- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Quick Start](#quick-start)
- [Configuration](#configuration)
  - [Data-Volumes](#data-volumes)
  - [Environment Variables](#environment-variables)
  - [Networking](#networking)
- [Maintenance](#maintenance)
  - [Shell Access](#shell-access)
- [References](#references)

## Prerequisites

No prerequisites required.

## Installation

Automated builds of the image are available on [Docker Hub](https://hub.docker.com/tiredofit/debian) and
is the recommended method of installation.


```bash
docker pull tiredofit/debian:(imagetag)
```

The following image tags are available:

* `latest` - Debian Buster - 10
* `buster:latest` - Debian Buster - 10
* `stretch:latest` - Debian Stretch - 9
* `jessie:latest` - Debian Jessie - 8


### Quick Start

Utilize this image as a base for further builds. By default, it does not start the S6 Overlay system, but
Bash. Please visit the [s6 overlay repository](https://github.com/just-containers/s6-overlay) for
instructions on how to enable the S6 init system when using this base or look at some of my other images
which use this as a base.

## Configuration

### Data-Volumes
The following directories are used for configure and can be mapped for persistent storage.

| Directory                           | Description                          |
| ----------------------------------- | ------------------------------------ |
| `/etc/zabbix/zabbix_agentd.conf.d/` | Zabbix Agent configuration directory |
| `/assets/cron-custom`               | Drop custom crontabs here            |


### Environment Variables

Below is the complete list of available options that can be used to customize your installation.

| Parameter             | Description                                                            | Default   |
| --------------------- | ---------------------------------------------------------------------- | --------- |
| `COLORIZE_OUTPUT`     | Enable/Disable colorized console output                                | `TRUE`    |
| `CONTAINER_LOG_LEVEL` | Control level of output of container `INFO`, `WARN`, `NOTICE`, `DEBUG` | `NOTICE`  |
| `DEBUG_MODE`          | Enable debug mode                                                      | `FALSE`   |
| `DEBUG_SMTP`          | Setup mail catch all on port 1025 (SMTP) and 8025 (HTTP)               | `FALSE`   |
| `ENABLE_CRON`         | Enable Cron                                                            | `TRUE`    |
| `ENABLE_LOGROTATE`    | Enable Logrotate                                                       | `TRUE`    |
| `ENABLE_SMTP`         | Enable SMTP services                                                   | `TRUE`    |
| `ENABLE_ZABBIX`       | Enable Zabbix Agent                                                    | `TRUE`    |
| `SKIP_SANITY_CHECK`   | Disable container startup routine check                                | `FALSE`   |
| `TIMEZONE`            | Set Timezone                                                           | `Etc/GMT` |

If you wish to have this sends mail, set `ENABLE_SMTP=TRUE` and configure the following environment variables.
See the [MSMTP Configuration Options](http://msmtp.sourceforge.net/doc/msmtp.html) for further information on options to configure MSMTP.

| Parameter             | Description                                       | Default            |
| --------------------- | ------------------------------------------------- | ------------------ |
| `ENABLE_SMTP_GMAIL`   | Add setting to support sending through Gmail SMTP | `FALSE`            |
| `SMTP_FROM`           | From name to send email as                        | `user@example.com` |
| `SMTP_HOST`           | Hostname of SMTP Server                           | `postfix-relay`    |
| `SMTP_PORT`           | Port of SMTP Server                               | `25`               |
| `SMTP_DOMAIN`         | HELO domain                                       | `docker`           |
| `SMTP_MAILDOMAIN`     | Mail domain from                                  | `local`            |
| `SMTP_AUTHENTICATION` | SMTP Authentication                               | `none`             |
| `SMTP_USER`           | SMTP Username (optional)                          |                    |
| `SMTP_PASS`           | SMTP Password (optional)                          |                    |
| `SMTP_TLS`            | Use TLS                                           | `off`              |
| `SMTP_STARTTLS`       | Start TLS from within session                     | `off`              |
| `SMTP_TLSCERTCHECK`   | Check remote certificate                          | `off`              |

See The [Official Zabbix Agent Documentation](https://www.zabbix.com/documentation/5.0/manual/appendix/config/zabbix_agentd)
for information about the following Zabbix values.

| Parameter                      | Description                             | Default                             |
| ------------------------------ | --------------------------------------- | ----------------------------------- |
| `ZABBIX_LOGFILE`               | Logfile location                        | `/var/log/zabbix/zabbix_agentd.log` |
| `ZABBIX_LOGFILESIZE`           | Logfile size                            | `1`                                 |
| `ZABBIX_DEBUGLEVEL`            | Debug level                             | `1`                                 |
| `ZABBIX_REMOTECOMMANDS_ALLOW`  | Enable remote commands                  | `*`                                 |
| `ZABBIX_REMOTECOMMANDS_DENY`   | Deny remote commands                    | `*`                                 |
| `ZABBIX_REMOTECOMMANDS_LOG`    | Enable remote commands Log (`0`/`1`)    | `1`                                 |
| `ZABBIX_SERVER`                | Allow connections from Zabbix server IP | `0.0.0.0/0`                         |
| `ZABBIX_LISTEN_PORT`           | Zabbix Agent listening port             | `10050`                             |
| `ZABBIX_LISTEN_IP`             | Zabbix Agent listening IP               | `0.0.0.0`                           |
| `ZABBIX_START_AGENTS`          | How many Zabbix Agents to start         | `3`                                 |
| `ZABBIX_SERVER_ACTIVE`         | Server for active checks                | `zabbix-proxy`                      |
| `ZABBIX_HOSTNAME`              | Container hostname to report to server  | `docker`                            |
| `ZABBIX_REFRESH_ACTIVE_CHECKS` | Seconds to refresh Active Checks        | `120`                               |
| `ZABBIX_BUFFER_SEND`           | Buffer Send                             | `5`                                 |
| `ZABBIX_BUFFER_SIZE`           | Buffer Size                             | `100`                               |
| `ZABBIX_MAXLINES_SECOND`       | Max Lines Per Second                    | `20`                                |
| `ZABBIX_ALLOW_ROOT`            | Allow running as root                   | `1`                                 |
| `ZABBIX_USER`                  | Zabbix user to start as                 | `zabbix`                            |

If you enable `DEBUG_PERMISSIONS=TRUE` all the users and groups have been modified in accordance with environment
variables will be displayed in output.
e.g. If you add `USER_NGINX=1000` it will reset the containers `nginx` user id from `82` to `1000` -
Hint, also change the Group ID to your local development users UID & GID and avoid Docker permission issues when developing.

| Parameter              | Description                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| `USER_<USERNAME>`      | The user's UID in /etc/passwd will be modified with new UID - Default `N/A`                 |
| `GROUP_<GROUPNAME>`    | The group's GID in /etc/group and /etc/passwd will be modified with new GID - Default `N/A` |
| `GROUP_ADD_<USERNAME>` | The username will be added in /etc/group after the group name defined - Default `N/A`       |


### Networking


The following ports are exposed.

| Port    | Description                                  |
| ------- | -------------------------------------------- |
| `1025`  | `DEBUG_MODE` & `DEBUG_SMTP` SMTP Catcher     |
| `8025`  | `DEBUG_MODE` & `DEBUG_SMTP` SMTP HTTP Viewer |
| `10050` | Zabbix Agent                                 |



# Debug Mode

When using this as a base image, create statements in your startup scripts to check for existence of `DEBUG_MODE=TRUE`
and set various parameters in your applications to output more detail, enable debugging modes, and so on.
In this base image it does the following:

* Sets zabbix-agent to output logs in verbosity
* Enables MailHog mailcatcher, which replaces `/usr/sbin/sendmail` with it's own catchall executable.
It also opens port `1025` for SMTP trapping, and you can view the messages it's trapped at port `8025`

## Maintenance
### Shell Access

For debugging and maintenance purposes you may want access the containers shell.

```bash
docker exec -it (whatever your container name is e.g. debian) bash
```

## References

* https://www.debian.org
* https://www.zabbix.org
* https://github.com/just-containers/s6-overlay
