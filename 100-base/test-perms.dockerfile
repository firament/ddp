# syntax=docker/dockerfile:1.5.2
# escape=\

# Test run to confirm files are copied with CHOWN set.
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
ARG DONT_PROMPT_WSL_INSTALL=true

WORKDIR $TEMP_WORK

# Base packs and create user - OK
RUN <<-MAKE-USER-01
	# Add base packs
	apt update;
	apt install -y --no-install-recommends apt-utils sudo;

	# Add user
	addgroup ghepf
	addgroup ghepfsuperusers
	useradd -m -N -s /bin/bash -g users -G sudo,ghepf,ghepfsuperusers $DEVELOPER_LOGIN
	echo "%ghepfsuperusers ALL=(ALL) NOPASSWD:ALL" | tee -a  /etc/sudoers
	cp -fv /etc/environment /etc/environment.$(date +"%Y%m%d-%s").bak
MAKE-USER-01

COPY common/bg-black-10.png   $APP_ROOT/bg-black-10.png
COPY vnc/                     /home/$DEVELOPER_LOGIN/.vnc/
COPY test-files/              /10-test-files/

RUN <<-PREPVNC
	echo "C6dVqSMEt4o=" | base64 --decode | tee /home/$DEVELOPER_LOGIN/.vnc/passwd
	chmod 600 /home/$DEVELOPER_LOGIN/.vnc/passwd
	chmod +x /home/$DEVELOPER_LOGIN/.vnc/xstartup
	chmod +x /home/$DEVELOPER_LOGIN/.vnc/startvnc
	chmod +x /home/$DEVELOPER_LOGIN/.vnc/stopvnc
	# tar cvJ --acls -f $APP_ROOT/tvnc-profile.tar.xz -C /home/$DEVELOPER_LOGIN/ .vnc/
PREPVNC

#----------------------------------------------------------------------------------------------------------------------#
# 
# Build final image
# 
FROM ubuntu:22.04
#----------------------------------------------------------------------------------------------------------------------#

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date="2023-04-17T12:00:00Z"
LABEL org.label-schema.name="dockerpad/base"
LABEL org.label-schema.description="Base image for development pads, and for testbeds to investigate features."
LABEL org.label-schema.version="1.0"
LABEL docker.cmd.debug="docker exec -it --user root CONTAINER /bin/bash"
LABEL com.pods.vnc-passwd="sesame"

ARG APP_ROOT
ARG PROJECT_ROOT
ARG PACKAGE_ROOT
ARG DEVELOPER_LOGIN
ARG DEVELOPER_PASSWD
ARG DEBIAN_FRONTEND
ARG  TZ
ARG HOST_NAME_ARG
ARG VNC_PORT_ARG
# Transitives

ENV DONT_PROMPT_WSL_INSTALL=true
ENV HOST_NAME=${HOST_NAME_ARG}
ENV VNC_PORT=${VNC_PORT_ARG}

RUN <<-MAKE-USER-02
	# Add base packs
	apt update
	# apt install -y --no-install-recommends apt-utils sudo

	# Add user
	addgroup ghepf
	addgroup ghepfsuperusers
	useradd -m -N -s /bin/bash -g users -G sudo,ghepf,ghepfsuperusers $DEVELOPER_LOGIN
	echo "%ghepfsuperusers ALL=(ALL) NOPASSWD:ALL" | tee -a  /etc/sudoers
	# echo -e '${DEVELOPER_PASSWD}\n${DEVELOPER_PASSWD}' | passwd $DEVELOPER_LOGIN

	# Touch timestamped file, to ensure layer cache is not reused
	cp -fv /etc/environment /etc/environment.$(date +"%Y%m%d-%s").bak

MAKE-USER-02

COPY --from=base-components --chown=$DEVELOPER_LOGIN:ghepf $APP_ROOT/                     $APP_ROOT/
COPY --from=base-components --chown=$DEVELOPER_LOGIN:users 10-test-files/                 /10-test-files/
COPY --from=base-components --chown=$DEVELOPER_LOGIN:users /home/$DEVELOPER_LOGIN/.vnc/   /home/$DEVELOPER_LOGIN/.vnc/

# Container runtime defaults
USER $DEVELOPER_LOGIN
WORKDIR $PROJECT_ROOT
ENTRYPOINT [ "/bin/bash" ]

# 
# BUILD
# docker build -t testpad/test-copy-perm -f 100-base\test-perms.dockerfile 100-base
# docker buildx build -t testpad/test-copy-perm -f 100-base\test-perms.dockerfile 100-base
# docker build -t testpad/test-copy-perm -f O:\curr-work-notes\Generic\Docker\dockerpad-base.dockerfile D:\Docker-Work\
# TEST
# docker run --name tp-copy-230507 --user vuser -dit -v D:\Docker-Work:/80-Host testpad/test-copy-perm
# docker attach tp-copy-230507
# docker container start tp-copy-230507
# docker exec -it --user root tp-copy-230507 /bin/bash
# CLEAN
# docker container rm tp-copy-230507
# docker image rm testpad/test-copy-perm
# 


# 
# docker run --name tp-jammy-temp -it ubuntu:22.04 /bin/bash
