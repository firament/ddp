# syntax=docker/dockerfile:1.5.2
# escape=\

# TODO:
# 	Build ruby versions on 'Build components' and only install dependency binaries on pad
# Update syntax
# 	syntax=docker/dockerfile:1.4
# 	syntax=docker/dockerfile:1.5.2


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
FROM devpad/base-pad:latest as base-components
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
ARG DONT_PROMPT_WSL_INSTALL

USER root

RUN <<-PREP-ENV
	# apt update
	apt install -y --no-install-recommends ca-certificates;

	mkdir -p /${APP_ROOT}/new-assets/;
	chown -R ${DEVELOPER_LOGIN}:ghepf /${APP_ROOT}/new-assets/;

	mkdir -vp ${TEMP_WORK};
	chown -Rv ${DEVELOPER_LOGIN}:ghepf ${TEMP_WORK};

PREP-ENV

# 
USER $DEVELOPER_LOGIN
# 

RUN <<-RBENV-SETUP
	# Install
	git clone https://github.com/rbenv/rbenv.git            /home/$DEVELOPER_LOGIN/.rbenv;
	mkdir -p /home/$DEVELOPER_LOGIN/.rbenv/plugins/;
	git clone https://github.com/rbenv/ruby-build.git       /home/$DEVELOPER_LOGIN/.rbenv/plugins/ruby-build;

	# Cleanup
	rm -vRf /home/$DEVELOPER_LOGIN/.rbenv/.git;
	rm -vRf /home/$DEVELOPER_LOGIN/.rbenv/.github/;
	rm -vRf /home/$DEVELOPER_LOGIN/.rbenv/plugins/ruby-build/.git;
	rm -vRf /home/$DEVELOPER_LOGIN/.rbenv/plugins/ruby-build/.github/;
RBENV-SETUP

RUN <<-INSTALL-NODEJS
	mkdir -vp $TEMP_WORK/downloads;
	wget --directory-prefix $TEMP_WORK/downloads https://nodejs.org/dist/latest/node-v20.1.0-linux-x64.tar.xz;
	mkdir -vp ${APP_ROOT}/new-assets/node;
	tar -xvJ --strip-components=1 -C ${APP_ROOT}/new-assets/node -f $TEMP_WORK/downloads/node-v20.1.0-linux-x64.tar.xz;
INSTALL-NODEJS

# Bundle all copy items in one folder
# COPY --chown=${DEVELOPER_LOGIN}:users  ssh                      /home/$DEVELOPER_LOGIN/.ssh
COPY                                  ssh                       /home/$DEVELOPER_LOGIN/.ssh
COPY --chown=${DEVELOPER_LOGIN}:ghepf Assets                    ${APP_ROOT}/new-assets
COPY --chown=${DEVELOPER_LOGIN}:ghepf vscode/ror-settings.jsonc $APP_ROOT/new-assets/VSCode/data/user-data/User/settings.json
COPY --chown=${DEVELOPER_LOGIN}:ghepf README.md                 $APP_ROOT/new-assets/README-ruby.md
RUN <<-BUNDLE-ASSETS
	mkdir -p $APP_ROOT/new-assets/VSCode/data/extensions;
	cp -f    $APP_ROOT/VSCode/data/extensions/extensions.json   $APP_ROOT/new-assets/VSCode/data/extensions/extensions-$(date +"%Y%m%d-%s").json;
	# Set ACLs
	chmod -R a+x ${APP_ROOT}/new-assets/Commands;
	chmod -R a+x ${APP_ROOT}/new-assets/ShortCuts;
	
	# chmod a-x /home/${DEVELOPER_LOGIN}/.ssh/*;
	chmod a-x ${APP_ROOT}/new-assets/VSCode/data/user-data/User/settings.json;

	# # Audit Trail, for copy
	# ls -l ${APP_ROOT}/new-assets/                      >> ${APP_ROOT}/new-assets.txt;
	# echo "***"                                         >> ${APP_ROOT}/new-assets.txt;
	# echo "All extensions installed  "                  >> ${APP_ROOT}/new-assets.txt;
	# ls -l $APP_ROOT/new-assets/VSCode/data/extensions/ >> ${APP_ROOT}/new-assets.txt;
	# echo "***"                                         >> ${APP_ROOT}/new-assets.txt;
	# cp -ft ${APP_ROOT}/new-assets                         ${APP_ROOT}/new-assets.txt;

BUNDLE-ASSETS



#----------------------------------------------------------------------------------------------------------------------#
# 
# Build final image
# 
FROM devpad/base-pad:latest
#----------------------------------------------------------------------------------------------------------------------#
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date="2023-05-11T13:13:13Z"
LABEL org.label-schema.name="devpad/ruby-pad"
LABEL org.label-schema.version="1.0.0"
LABEL org.label-schema.description="Image for Ruby-on-Rails development pads."
LABEL org.label-schema.url="https://github.com/firament/ddp/"
LABEL org.label-schema.docker.cmd="docker run --name $CONTAINER --user vuser -dit -v /Projects/Docker-Work/base-pad:/80-Host -p 23130:3000 -p 23191:10101 devpad/ruby-pad"
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
USER root
# 
RUN <<APT-PACKS-RUBY
	# Add packages
	apt update
	apt install -y --no-install-recommends autoconf bison ca-certificates patch build-essential rustc libssl-dev libyaml-dev libreadline-dev zlib1g-dev libgmp-dev libncurses-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev sqlite3 mysql-client libmysqlclient-dev;

	# BEGIN - only till new base is built
	apt install -y --no-install-recommends dconf-cli
	# FINIS - only till new base is built

	cp -fv /etc/environment /etc/environment.$(date +"%Y%m%d-%s").bak
APT-PACKS-RUBY

# COPY --from=base-components --chown=${DEVELOPER_LOGIN}:users  /home/${DEVELOPER_LOGIN}/.ssh     /home/${DEVELOPER_LOGIN}/.ssh
COPY --from=base-components                                   /home/${DEVELOPER_LOGIN}/.ssh     /home/${DEVELOPER_LOGIN}/.ssh
COPY --from=base-components --chown=${DEVELOPER_LOGIN}:users  /home/${DEVELOPER_LOGIN}/.rbenv   /home/${DEVELOPER_LOGIN}/.rbenv
COPY --from=base-components --chown=${DEVELOPER_LOGIN}:ghepf  ${APP_ROOT}/new-assets            ${APP_ROOT}
COPY                        --chown=${DEVELOPER_LOGIN}:ghepf  README.md                         ${PROJECT_ROOT}/README-ruby.md

RUN	<<-CONFIG-SYSTEM
	# rbenv
	ln -fs /home/${DEVELOPER_LOGIN}/.rbenv/bin/rbenv                              /usr/local/sbin/rbenv;
	ln -fs /home/${DEVELOPER_LOGIN}/.rbenv/plugins/ruby-build/bin/rbenv-install   /usr/local/sbin/rbenv-install;
	ln -fs /home/${DEVELOPER_LOGIN}/.rbenv/plugins/ruby-build/bin/rbenv-uninstall /usr/local/sbin/rbenv-uninstall;
	ln -fs /home/${DEVELOPER_LOGIN}/.rbenv/plugins/ruby-build/bin/ruby-build      /usr/local/sbin/ruby-build;

	# node-js
	ln -sT ${APP_ROOT}/node/bin/corepack        /usr/local/sbin/corepack;
	ln -sT ${APP_ROOT}/node/bin/node            /usr/local/sbin/node;
	ln -sT ${APP_ROOT}/node/bin/npm             /usr/local/sbin/npm;
	ln -sT ${APP_ROOT}/node/bin/npx             /usr/local/sbin/npx;

	# VSCode
	ln -sT ${APP_ROOT}/Commands/code-ror        /usr/local/sbin/code-ror;

	# launchers
	mkdir -p /home/${DEVELOPER_LOGIN}/Desktop;
	cp       ${APP_ROOT}/ShortCuts/*desktop     /usr/share/applications;
	cp -ft   /home/${DEVELOPER_LOGIN}/Desktop   ${APP_ROOT}/ShortCuts/code-ror.desktop;
	chown -R $DEVELOPER_LOGIN:users             /home/${DEVELOPER_LOGIN}/Desktop;

	chmod a+x ${APP_ROOT}/Commands/rbenv-activate.sh;
	chown -R ${DEVELOPER_LOGIN}:users /home/${DEVELOPER_LOGIN}/.ssh;
	chmod a-x                         /home/${DEVELOPER_LOGIN}/.ssh/*;

	touch /build-tag-ror.txt;
	chmod a+rw /build-tag-ror.txt;
CONFIG-SYSTEM

# 
USER $DEVELOPER_LOGIN
# 

RUN <<-RUBY-INSTALL
	/bin/bash -c $APP_ROOT/Commands/rbenv-activate.sh;
	rm -Rf /tmp/ruby-build.*.log;
RUBY-INSTALL

RUN <<-VSCode-EXTNS
	# Install new extensions
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension rebornix.ruby;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension Shopify.ruby-lsp;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension KoichiSasada.vscode-rdbg;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension bung87.rails;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension bung87.vscode-gemfile;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension sianglim.slim;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension esbenp.prettier-vscode;
	/usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --install-extension ecmel.vscode-html-css;
	# Cleanup
	rm -vf  $APP_ROOT/VSCode/data/user-data/machineid;
	rm -vf  $APP_ROOT/VSCode/bin/code-tunnel;
	rm -vRf $APP_ROOT/VSCode/data/user-data/logs/*;
	rm -vRf $APP_ROOT/VSCode/data/user-data/CachedExtensionVSIXs/*;
VSCode-EXTNS


# Runtime snapshot
RUN <<-FILL-MARKER-FILE
    # Set marker files 

    date +"%T [%a] %d %b %Y" >> /build-tag-ror.txt;

	echo " " >>  /build-tag-ror.txt;
	cat /etc/lsb-release >> /build-tag-ror.txt;

	echo " " >>  /build-tag-ror.txt;
	cat /proc/version >> /build-tag-ror.txt;

	echo " " >> /build-tag-ror.txt;
    printenv >> /build-tag-ror.txt;

	echo " " >> /build-tag-ror.txt;
	echo "VS Code extensions:" >> /build-tag-ror.txt;
	# /usr/local/sbin/code-cli --no-sandbox --user-data-dir $APP_ROOT/VSCode/data --list-extensions | tee -a /build-tag-ror.txt;
	/usr/local/sbin/code-cli --no-sandbox --list-extensions | tee -a /build-tag-ror.txt;

	# Ruby Info
	echo " " >> /build-tag-ror.txt;
	echo "Ruby active version:" >> /build-tag-ror.txt;
	ruby --version    | tee -a /build-tag-ror.txt;    

	echo " " >> /build-tag-ror.txt;
	echo "Ruby versions installed:" >> /build-tag-ror.txt;
	rbenv versions    | tee -a /build-tag-ror.txt;    

	echo " " >> /build-tag-ror.txt;
	echo "Ruby versions available:" >> /build-tag-ror.txt;
	rbenv install -l  | tee -a /build-tag-ror.txt;      

	echo " " >> /build-tag-ror.txt;
	echo "Ruby Gems installed:" >> /build-tag-ror.txt;
	gem list          | tee -a /build-tag-ror.txt;      

	# App packages installed
	echo " " >> /build-tag-ror.txt;
	echo " " >> /build-tag-ror.txt;
	echo "Installed Packages:" >> /build-tag-ror.txt;
	dpkg-query -l | grep ii | tee -a /build-tag-ror.txt;

	# TODO: Add node versions

FILL-MARKER-FILE

EXPOSE $VNC_PORT_ARG
EXPOSE 3000
EXPOSE 10010
EXPOSE 10020

# Container runtime defaults
USER $DEVELOPER_LOGIN
WORKDIR $PROJECT_ROOT
ENTRYPOINT [ "/usr/local/sbin/startvnc" ]

# 
# BUILD
# docker buildx build -t devpad/ruby-pad -f 220-ruby\ruby-pad.dockerfile 220-ruby
# TEST
# docker run --name dp-ruby-01 --user vuser -dit -v <put-CWD-FQDN-here>:/80-Host -p 23110:10010 -p 23120:10020 -p 23130:3000 -p 23191:10101 devpad/ruby-pad
# docker run --name dp-ruby-01 --user vuser -dit -v D:\Docker-Work:/80-Host      -p 23110:10010 -p 23120:10020 -p 23130:3000 -p 23191:10101 devpad/ruby-pad
# docker attach dp-ruby-01
# docker container start dp-ruby-01
# docker exec -it --user root dp-ruby-01 /bin/bash
# vncviewer64-1.13.1.exe localhost::23191
# java -jar VncViewer-1.13.1.jar localhost::23191
# CLEAN
# docker container rm dp-ruby-01
# docker image rm devpad/ruby-pad
# 
