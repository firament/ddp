# ddp - Docker Development Pads

Development pads to test applications in isolation and fixed environments.

## Pads and Environments

### Lite Pad
Ubuntu LTS with XFCE and VNC server

- BUILD
```sh
docker buildx build -t devpad/lite-pad -f 100-base/lite-pad.dockerfile 100-base
```
- TEST
```sh
docker run --name dp-lite-01 -dit -v <put-CWD-FQDN-here>:/80-Host -p 19110:10010 -p 19120:10020 -p 19191:10101 devpad/lite-pad
docker attach dp-lite-01
docker container start dp-lite-01
docker exec -it --user root dp-lite-01 /bin/bash
```
- Connect
```sh
vncviewer64-1.13.1.exe localhost::19191
java -jar VncViewer-1.13.1.jar localhost::19191
```

- CLEAN
```sh
docker container rm dp-lite-01
docker image rm devpad/lite-pad
```

***

### Base Pad
Ubuntu LTS with XFCE, VNC server and 
- Visual studio code, with extensions
	- markdown, edit and preview
	- eslint
	- timestamp

```sh
# 
# BUILD
docker buildx build -t devpad/base-pad -f 100-base/base-pad.dockerfile 100-base
# TEST
docker run --name dp-base-01 -dit -v <put-CWD-FQDN-here>:/80-Host -p 10110:10010 -p 10120:10020 -p 10191:10101 devpad/base-pad
docker attach dp-base-01
docker container start dp-base-01
docker exec -it --user root dp-base-01 /bin/bash
vncviewer64-1.13.1.exe localhost::10191
java -jar VncViewer-1.13.1.jar localhost::10191
# CLEAN
docker container rm dp-base-01
docker image rm devpad/base-pad
# 
```

***

### Python Pad
> based on `Base Pad`

Ubuntu LTS with XFCE, VNC server and 
- Visual studio code, with Python extensions
- Python, with `venv`
- Legacy versions enabled for install
- Python debugger
- PgSQL client library

**TBD**

***

### Ruby Pad
> based on `Base Pad`

Ubuntu LTS with XFCE, VNC server and 
- Visual studio code, with Ruby extensions
- Ruby on Rails, with `rbenv`
- Ruby debugger
- MSSQL client library

```sh
# 
# BUILD
docker buildx build -t devpad/ruby-pad -f 220-ruby/ruby-pad.dockerfile 220-ruby
# TEST
docker run --name dp-ruby-01 -dit -v <put-CWD-FQDN-here>:/80-Host -p 23110:10010 -p 23120:10020 -p 23130:3000 -p 23191:10101 devpad/ruby-pad
docker attach dp-ruby-01
docker container start dp-ruby-01
docker exec -it --user root dp-ruby-01 /bin/bash
vncviewer64-1.13.1.exe localhost::23191
java -jar VncViewer-1.13.1.jar localhost::23191
# CLEAN
docker container rm dp-ruby-01
docker image rm devpad/ruby-pad
# 
```

***

## Notes:
- Cleanup build caches to free up space on build machine.
	```sh
	docker buildx du
	docker buildx prune -a
	```

- Set consistent `LF` line endings
	- on Windows machine, scripts copied to Linux images fail to run due ot `CRLF` endings
	- https://gist.github.com/ajdruff/16427061a41ca8c08c05992a6c74f59e
	- Ensure `LF` in filesystem and git repository
		```sh
		# Check
		git config --get core.eol
		git config --get core.autocrlf
		# Set
		git config core.eol lf
		git config core.autocrlf false
		```
	- Set this before creating file. Or open, edit and save files again to apply line endings properly.

***


## Notes:

### Download links
- http://jdk.java.net/
- https://www.umldesigner.org/download/
- https://www.visual-paradigm.com/download/?platform=linux&arch=64bit&install=no
- https://www.visual-paradigm.com/download/community.jsp?platform=linux&arch=64bit&install=no
- https://github.com/ModelioOpenSource/Modelio/releases
	- https://github.com/ModelioOpenSource/Modelio.wiki.git
	```sh
	echo "deb http://fr.archive.ubuntu.com/ubuntu bionic main universe" | tee -a /etc/apt/sources.list
	apt install libwebkitgtk-3.0-0
	# https://packages.ubuntu.com/mantic/libwebkitgtk-6.0-4
	```

***
