# syntax=docker/dockerfile:1.5.2
# escape=\

# Working data
# syntax=docker/dockerfile:1.4

# Globals
ARG APP_ROOT=/10-base
ARG PROJECT_ROOT=/90-work
ARG PACKAGE_ROOT=/00-install-packs
ARG DEVELOPER_LOGIN="vuser"
ARG DEVELOPER_PASSWD="whatisthis"
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Kolkata
ARG HOST_NAME_ARG=ddp-lite-01
ARG VNC_PORT_ARG=10101
# Transitives
ARG TEMP_WORK=/80-Temp
ARG DONT_PROMPT_WSL_INSTALL_ARG=true

#----------------------------------------------------------------------------------------------------------------------#
# 
# Build image
# 
FROM ubuntu:22.04
#----------------------------------------------------------------------------------------------------------------------#

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date="2023-05-08T13:13:13Z"
LABEL org.label-schema.name="devpad/lite-pad"
LABEL org.label-schema.version="1.0.0"
LABEL org.label-schema.description="Lite image, with only desktop, for ue as scratchpad or testing."
LABEL org.label-schema.url="https://github.com/firament/ddp/"
LABEL org.label-schema.docker.cmd="docker run --name $CONTAINER --user vuser -dit -v /Projects/Docker-Work/base-pad:/80-Host -p 11191:10101 devpad/lite-pad"
LABEL org.label-schema.docker.debug="docker exec -it --user root $CONTAINER /bin/bash"
LABEL com.devpad.vnc-passwd="sesame"

ARG APP_ROOT
ARG PROJECT_ROOT
ARG PACKAGE_ROOT
ARG DEVELOPER_LOGIN
ARG DEVELOPER_PASSWD
ARG DEBIAN_FRONTEND
ARG TZ
ARG HOST_NAME_ARG
ARG VNC_PORT_ARG
# Transitives

ENV HOST_NAME=${HOST_NAME_ARG}
ENV VNC_PORT=${VNC_PORT_ARG}

# 
# USER root
# 

RUN <<APT-PACKS-INSTALL
	# Add packages
	apt update

	# Touch timestamped file, to ensure layer cache is not reused
	# Backup core files, that we may modify
	cp -fv /etc/environment /etc/environment.$(date +"%Y%m%d-%s").bak

	# Core
	apt install -y --no-install-recommends gftp lsof rsync sudo openssh-client tzdata wget xz-utils

	# Desktop
	apt install -y --no-install-recommends xfce4 xfce4-datetime-plugin xfce4-systemload-plugin xfce4-taskmanager xfce4-terminal

	# VNC
	apt install -y --no-install-recommends dbus-x11 tigervnc-standalone-server

	# Candy
	apt install -y --no-install-recommends git fonts-cascadia-code fonts-firacode mousepad ristretto

APT-PACKS-INSTALL

RUN <<-MAKE-USER
	# Make user
	addgroup ghepf
	addgroup ghepfsuperusers
	useradd -m -N -s /bin/bash -g users -G sudo,ghepf,ghepfsuperusers $DEVELOPER_LOGIN
	echo "%ghepfsuperusers ALL=(ALL) NOPASSWD:ALL" | tee -a  /etc/sudoers
	# echo -e '${DEVELOPER_PASSWD}\n${DEVELOPER_PASSWD}' | passwd $DEVELOPER_LOGIN
MAKE-USER

# VNC Server
COPY --chown=$DEVELOPER_LOGIN:ghepf vnc/                     /home/$DEVELOPER_LOGIN/.vnc/
RUN <<-PREPVNC
	echo "C6dVqSMEt4o=" | base64 --decode | tee /home/$DEVELOPER_LOGIN/.vnc/passwd;
	chmod 600 /home/$DEVELOPER_LOGIN/.vnc/passwd;
	chmod +x /home/$DEVELOPER_LOGIN/.vnc/xstartup;
	chmod +x /home/$DEVELOPER_LOGIN/.vnc/startvnc;
	chmod +x /home/$DEVELOPER_LOGIN/.vnc/stopvnc;
PREPVNC

COPY --chown=$DEVELOPER_LOGIN:ghepf common/bg-black-10.png   $APP_ROOT/bg-black-10.png
RUN	<<-CONFIG-SYSTEM
	# Set timezone
	ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime

	mkdir -vp $TEMP_WORK/;
    mkdir -vp $PROJECT_ROOT/;
	mkdir -vp $APP_ROOT/;
	mkdir -vp /home/$DEVELOPER_LOGIN/Desktop/;

	# Set background
	mv /usr/share/backgrounds/xfce/xfce-verticals.png /usr/share/backgrounds/xfce/xfce-verticals-bak.png;
	cp $APP_ROOT/bg-black-10.png                      /usr/share/backgrounds/xfce/xfce-verticals.png;

	# Sym-Links
	ln -vsT /home/$DEVELOPER_LOGIN/.vnc/startvnc  /usr/local/sbin/startvnc
	ln -vsT /home/$DEVELOPER_LOGIN/.vnc/stopvnc   /usr/local/sbin/stopvnc
	echo ":1=$DEVELOPER_LOGIN" | tee -a /etc/tigervnc/vncserver.users

	# Copy shortcuts to desktop, if any
	mkdir -p /home/$DEVELOPER_LOGIN/Desktop;
	cp -ft /home/$DEVELOPER_LOGIN/Desktop /usr/share/applications/org.xfce.mousepad.desktop;

	# Add any other convenience shortcut here
	chmod a+x /home/$DEVELOPER_LOGIN/Desktop/*.desktop

	# Cleanup
	chown -Rv $DEVELOPER_LOGIN:ghepf      $TEMP_WORK;
	chown -Rv $DEVELOPER_LOGIN:ghepf      $PROJECT_ROOT;
	chown -Rv $DEVELOPER_LOGIN:ghepf      $APP_ROOT;
	chown -Rv $DEVELOPER_LOGIN:users      /home/$DEVELOPER_LOGIN;

	# Marker file
	touch /build-tag.txt
	chmod a+rw /build-tag.txt

CONFIG-SYSTEM

# Runtime snapshot
RUN <<-FILL-MARKER-FILE
    # Set marker files 

    touch /build-tag.txt;
    date +"%T [%a] %d %b %Y" >> /build-tag.txt;

	echo " " >>  /build-tag.txt;
	cat /etc/lsb-release >> /build-tag.txt;

	echo " " >> /build-tag.txt;
    printenv >> /build-tag.txt;

	echo " " >> /build-tag.txt;
	echo "Installed Packages:" >> /build-tag.txt;
	dpkg-query -l | grep ii | tee -a /build-tag.txt;

FILL-MARKER-FILE

EXPOSE $VNC_PORT_ARG
EXPOSE 10010
EXPOSE 10020

# Container runtime defaults
USER $DEVELOPER_LOGIN
WORKDIR $PROJECT_ROOT
ENTRYPOINT [ "/usr/local/sbin/startvnc" ]


# 
# BUILD
# docker buildx build -t devpad/lite-pad -f 100-base\lite-pad.dockerfile 100-base
# TEST
# docker run --name dp-lite-01 --user vuser -dit -v <put-CWD-FQDN-here>:/80-Host -p 19110:10010 -p 19120:10020 -p 19191:10101 devpad/lite-pad
# docker run --name dp-lite-01 --user vuser -dit -v D:\Docker-Work:/80-Host      -p 19110:10010 -p 19120:10020 -p 19191:10101 devpad/lite-pad
# docker attach dp-lite-01
# docker container start dp-lite-01
# docker exec -it --user root dp-lite-01 /bin/bash
# vncviewer64-1.13.1.exe localhost::19191
# java -jar VncViewer-1.13.1.jar localhost::19191
# CLEAN
# docker container rm dp-lite-01
# docker image rm devpad/lite-pad
# 
