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
ARG HOST_NAME_ARG=ddp-base-01
ARG VNC_PORT_ARG=10101
# Transitives
ARG TEMP_WORK=/80-Temp
ARG DONT_PROMPT_WSL_INSTALL_ARG=true

#----------------------------------------------------------------------------------------------------------------------#
# 
# Build components
# 
FROM ubuntu:22.04 as base-components
#----------------------------------------------------------------------------------------------------------------------#

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
ARG TEMP_WORK

WORKDIR $TEMP_WORK

# Base packs and create user - OK
RUN <<-MAKE-USER
	# Add base packs
	apt update
	apt install -y --no-install-recommends ca-certificates sudo wget xz-utils

	# Add user
	addgroup ghepf
	addgroup ghepfsuperusers
	useradd -m -N -s /bin/bash -g users -G sudo,ghepf,ghepfsuperusers $DEVELOPER_LOGIN
	echo "%ghepfsuperusers ALL=(ALL) NOPASSWD:ALL" | tee -a  /etc/sudoers
	# echo -e '${DEVELOPER_PASSWD}\n${DEVELOPER_PASSWD}' | passwd $DEVELOPER_LOGIN

	# Touch timestamped file, to ensure layer cache is not reused
	cp -fv /etc/environment /etc/environment.$(date +"%Y%m%d-%s").bak

MAKE-USER

# Normalize folder names - OK
RUN <<-SET-PERMS
	mkdir -vp $TEMP_WORK/;
	chown -Rv $DEVELOPER_LOGIN:ghepf      $TEMP_WORK/;
	
	mkdir -vp $APP_ROOT/ShortCuts/icons;
	chown -Rv $DEVELOPER_LOGIN:ghepf      $APP_ROOT;
	
	mkdir -vp /home/$DEVELOPER_LOGIN/Desktop/
	chown -vR $DEVELOPER_LOGIN:users      /home/$DEVELOPER_LOGIN;
	
	touch /build-tag.txt;
	chmod a+rw /build-tag.txt;
SET-PERMS
COPY --chown=$DEVELOPER_LOGIN:ghepf common/bg-black-10.png   $APP_ROOT/bg-black-10.png

# VNC Server
COPY --chown=$DEVELOPER_LOGIN:ghepf vnc/                     /home/$DEVELOPER_LOGIN/.vnc/
RUN <<-PREPVNC
	echo "C6dVqSMEt4o=" | base64 --decode | tee /home/$DEVELOPER_LOGIN/.vnc/passwd;
	chmod 600 /home/$DEVELOPER_LOGIN/.vnc/passwd;
	chmod +x /home/$DEVELOPER_LOGIN/.vnc/xstartup;
	chmod +x /home/$DEVELOPER_LOGIN/.vnc/startvnc;
	chmod +x /home/$DEVELOPER_LOGIN/.vnc/stopvnc;
PREPVNC

# Visual Studio Code
RUN <<-VSCODE-SETUP
	# use a cache volume mount for debugging
	mkdir -vp $TEMP_WORK/downloads;
	mkdir -vp $APP_ROOT/VSCode;
	mkdir -vp $APP_ROOT/VSCode/data;
	wget --directory-prefix $TEMP_WORK/downloads https://update.code.visualstudio.com/latest/linux-x64/stable;
	tar -xz --strip-components=1 -C $APP_ROOT/VSCode -f $TEMP_WORK/downloads/stable;
VSCODE-SETUP
COPY --chown=$DEVELOPER_LOGIN:ghepf vscode/code.desktop            $APP_ROOT/ShortCuts/code.desktop
COPY --chown=$DEVELOPER_LOGIN:ghepf vscode/settings.jsonc          $APP_ROOT/VSCode/data/user-data/User/settings.json

# Scrub non-essentials
RUN <<-CLEANUP
	chown -vR $DEVELOPER_LOGIN:ghepf $APP_ROOT;
	chmod a+x $APP_ROOT/ShortCuts/*desktop;
CLEANUP


#----------------------------------------------------------------------------------------------------------------------#
# 
# Build final image
# 
FROM ubuntu:22.04
#----------------------------------------------------------------------------------------------------------------------#

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date="2023-05-08T13:13:13Z"
LABEL org.label-schema.name="devpad/base-pad"
LABEL org.label-schema.version="1.0.0"
LABEL org.label-schema.description="Base image for development pads, and for testbeds to investigate features."
LABEL org.label-schema.url="https://github.com/firament/ddp/"
LABEL org.label-schema.docker.cmd="docker run --name $CONTAINER --user vuser -dit -v /Projects/Docker-Work/base-pad:/80-Host -p 11191:10101 devpad/base-pad"
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
ARG DONT_PROMPT_WSL_INSTALL_ARG
# Transitives

ENV DONT_PROMPT_WSL_INSTALL=${DONT_PROMPT_WSL_INSTALL_ARG}
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
APT-PACKS-INSTALL
RUN <<APT-PACKS-01
	# Core
	apt install -y --no-install-recommends gftp lsof rsync sudo openssh-client tzdata wget xz-utils
APT-PACKS-01
RUN <<APT-PACKS-02
	# Desktop
	apt install -y --no-install-recommends xfce4 xfce4-datetime-plugin xfce4-systemload-plugin xfce4-taskmanager xfce4-terminal
APT-PACKS-02
RUN <<APT-PACKS-03
	# VNC
	apt install -y --no-install-recommends dbus-x11 tigervnc-standalone-server
APT-PACKS-03
RUN <<APT-PACKS-04
	# Visual Studio Code
	apt install -y --no-install-recommends alsa-topology-conf alsa-ucm-conf libasound2 libasound2-data libgbm1 libnspr4 libnss3 libpopt0 libwayland-server0
APT-PACKS-04
RUN <<APT-PACKS-05
	# Candy
	apt install -y --no-install-recommends git fonts-cascadia-code fonts-firacode mousepad ristretto dconf-cli
APT-PACKS-05

RUN <<-MAKE-USER
	# Make user
	addgroup ghepf
	addgroup ghepfsuperusers
	useradd -m -N -s /bin/bash -g users -G sudo,ghepf,ghepfsuperusers $DEVELOPER_LOGIN
	echo "%ghepfsuperusers ALL=(ALL) NOPASSWD:ALL" | tee -a  /etc/sudoers
	# echo -e '${DEVELOPER_PASSWD}\n${DEVELOPER_PASSWD}' | passwd $DEVELOPER_LOGIN
MAKE-USER

COPY --from=base-components --chown=$DEVELOPER_LOGIN:ghepf $APP_ROOT/                       $APP_ROOT/
COPY --from=base-components --chown=$DEVELOPER_LOGIN:users /home/$DEVELOPER_LOGIN/.vnc/     /home/$DEVELOPER_LOGIN/.vnc/

RUN	<<-CONFIG-SYSTEM
	# Set timezone
	ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime

	# Set background
	mv /usr/share/backgrounds/xfce/xfce-verticals.png /usr/share/backgrounds/xfce/xfce-verticals-bak.png;
	cp /10-base/bg-black-10.png                       /usr/share/backgrounds/xfce/xfce-verticals.png;

	# work dir
    mkdir -vp $PROJECT_ROOT;
	chown -Rv $DEVELOPER_LOGIN:ghepf $PROJECT_ROOT;

	# Sym-Links
	ln -sT /home/$DEVELOPER_LOGIN/.vnc/startvnc  /usr/local/sbin/startvnc;
	ln -sT /home/$DEVELOPER_LOGIN/.vnc/stopvnc   /usr/local/sbin/stopvnc;
	ln -sT $APP_ROOT/VSCode/code                 /usr/local/sbin/vscode;
	ln -sT $APP_ROOT/VSCode/bin/code             /usr/local/sbin/code-cli;
	echo ":1=$DEVELOPER_LOGIN" | tee -a /etc/tigervnc/vncserver.users;

	# Aliases, do redundancy check
	echo "alias code='$APP_ROOT/VSCode/code --no-sandbox'" | tee -a /etc/bash.bashrc;

	# launchers
	ln -sT    $APP_ROOT/VSCode/resources/app/resources/linux/code.png  $APP_ROOT/ShortCuts/icons/code.png;
	mkdir -p  /home/$DEVELOPER_LOGIN/Desktop;
	cp -ft    /usr/share/applications            $APP_ROOT/ShortCuts/*desktop;
	cp -ft    /home/$DEVELOPER_LOGIN/Desktop     /usr/share/applications/org.xfce.mousepad.desktop;
	chown -R  $DEVELOPER_LOGIN:users             /home/${DEVELOPER_LOGIN}/Desktop;

	# Marker file
	touch      /build-tag.txt;
	chmod a+rw /build-tag.txt;

CONFIG-SYSTEM

# 
USER $DEVELOPER_LOGIN
# 

RUN <<-INSTALL-VSCODE-EXTNS
	# Install
	# DONT_PROMPT_WSL_INSTALL=true 
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension jsynowiec.vscode-insertdatestring;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension volkerdobler.insertnums;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension dbaeumer.vscode-eslint;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension yzhang.markdown-all-in-one;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension bierner.markdown-preview-github-styles;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension pharndt.vscode-markdown-table;
	# Cleanup
	rm -vf  $APP_ROOT/VSCode/data/user-data/machineid;
	rm -vf  $APP_ROOT/VSCode/bin/code-tunnel;
	rm -vRf $APP_ROOT/VSCode/data/user-data/logs/*;
	rm -vRf $APP_ROOT/VSCode/data/user-data/CachedExtensionVSIXs/*;
INSTALL-VSCODE-EXTNS

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
	echo "VS Code extensions:" >> /build-tag.txt;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --list-extensions | tee -a /build-tag.txt;

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
# docker buildx build -t devpad/base-pad -f 100-base\base-pad.dockerfile 100-base
# TEST
# docker run --name dp-base-01 --user vuser -dit -v <put-CWD-FQDN-here>:/80-Host -p 10110:10010 -p 10120:10020 -p 10191:10101 devpad/base-pad
# docker run --name dp-base-01 --user vuser -dit -v D:\Docker-Work:/80-Host      -p 10110:10010 -p 10120:10020 -p 10191:10101 devpad/base-pad
# docker attach dp-base-01
# docker container start dp-base-01
# docker exec -it --user root dp-base-01 /bin/bash
# vncviewer64-1.13.1.exe localhost::10191
# java -jar VncViewer-1.13.1.jar localhost::10191
# CLEAN
# docker container rm dp-base-01
# docker image rm devpad/base-pad
# 
