# syntax=docker/dockerfile:1.5.2
# escape=\

# Globals
ARG HOST_NAME_ARG=ddp-ftp-01
ARG VNC_PORT_ARG=47101
# Transitives
ARG TEMP_WORK=/80-Temp
ARG DONT_PROMPT_WSL_INSTALL_ARG=true

#----------------------------------------------------------------------------------------------------------------------#
# 
# Build image
# 
FROM devpad/base-pad:latest
#----------------------------------------------------------------------------------------------------------------------#

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date="2023-06-06T00:00:00Z"
LABEL org.label-schema.name="devpad/ftp-pad"
LABEL org.label-schema.version="1.0.0"
LABEL org.label-schema.description="Quick FTP server for local network data transfer"
LABEL org.label-schema.url="https://github.com/firament/ddp/"
LABEL org.label-schema.docker.cmd="docker run --name $CONTAINER --user vuser -dit -v /Projects/Docker-Work/base-pad:/80-Host -p 11191:47101 devpad/ftp-pad"
LABEL org.label-schema.docker.debug="docker exec -it --user root $CONTAINER /bin/bash"
LABEL com.devpad.vnc-passwd="sesame"

ARG HOST_NAME_ARG
ARG VNC_PORT_ARG

ENV HOST_NAME=${HOST_NAME_ARG}
ENV VNC_PORT=${VNC_PORT_ARG}

# 
USER root
# 

RUN <<APT-PACKS-INSTALL
	# Add packages
	apt update

	# Touch timestamped file, to ensure layer cache is not reused
	# Backup core files, that we may modify
	cp -fv /etc/environment /etc/environment.$(date +"%Y%m%d-%s").bak

	# Core
	apt install -y --no-install-recommends vsftpd

APT-PACKS-INSTALL

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
EXPOSE 20
EXPOSE 21
EXPOSE 40000-40009

# Container runtime defaults
USER $DEVELOPER_LOGIN
WORKDIR $PROJECT_ROOT
ENTRYPOINT [ "/usr/local/sbin/startvnc" ]


# 
# BUILD
# docker buildx build -t devpad/ftp-pad -f 900-Utils/ftp-pad.dockerfile 900-Utils
# TEST
# docker run --name dp-ftp-01 --user vuser -dit -v <put-CWD-FQDN-here>:/80-Host -p 47110:10010 -p 47120:20 -p 47121:21 -p 47191:47101 -p 40000-40009:40000-40009 devpad/ftp-pad
# docker run --name dp-ftp-01 --user vuser -dit -v D:\Docker-Work:/80-Host      -p 47110:10010 -p 47120:20 -p 47121:21 -p 47191:47101 -p 40000-40009:40000-40009 devpad/ftp-pad
# docker attach dp-ftp-01
# docker container start dp-ftp-01
# docker exec -it --user root dp-ftp-01 /bin/bash
# vncviewer64-1.13.1.exe localhost::47191
# java -jar VncViewer-1.13.1.jar localhost::47191
# CLEAN
# docker container rm dp-ftp-01
# docker image rm devpad/ftp-pad
# 
