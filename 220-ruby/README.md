# Docker for Ruby on Rails development

## Getting started

### Add ssh key
> for ssh-git operations
> https://confluence.atlassian.com/bitbucketserver/ssh-user-keys-for-personal-use-776639793.html

- Known issue:
	- Ownership of folder `~/.ssh` is set to root
		- Take ownership before proceeding.
- Copy SSH keys
	- File Name: `~/.ssh/id_lh_ed25519`
- or Generate new:
	```sh
	ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_lh_ed25519 -C "your_login_email@example.com"
	```
- Register key-identity
	- ssh-add `~/.ssh/id_lh_ed25519`
	- enter *passhprase* when asked

### From project/repository root
> From terminal, before opening in VS COde

- Get project repository (use your appropiate URL)
```sh
git clone -b ruby-upgrade git@lh.bb:sunnysmile/litehouse.git
cd litehouse;
git config core.eol lf
git config core.autocrlf false
```

- Inspech environment
```sh
ruby -v;
bundle -v;
```

- Prepare environment
```sh
gem update bundler;
mkdir -vp dump;

bundle config set --local path 'vendor/bundle';
bundle install 2>&1 | tee dump/install-$(date +"%Y%m%d-%s").log;
rm -f bin/*
bundle binstubs rake railties bundler ruby-debug-ide solargraph;
bundle exec rails app:update:bin

gem list | tee dump/local-gem-list.txt;
```

- Open in folder in Visual Studio Code.

***

## Other info
> Review and cleanup

```dockerfile
RUN <<-SSH-SETUP
	# SSH configuration
	ssh-keyscan -H bitbucket.org | tee -a /home/$DEVELOPER_LOGIN/.ssh/known_hosts;
	# sed 's|# ||g' /home/$DEVELOPER_LOGIN/.ssh/config.bak | tee /home/$DEVELOPER_LOGIN/.ssh/config;
SSH-SETUP
```

***

## Known bugs
### SSH folder permisions
workaround
```sh
mkdir -vp /90-work/git-work
sudo cat /home/vuser/.ssh/config      | tee /90-work/git-work/config
sudo cat /home/vuser/.ssh/known_hosts | tee /90-work/git-work/known_hosts
sudo rm -vrf /home/vuser/.ssh

mkdir -vp /home/vuser/.ssh
cat /90-work/git-work/config      | tee /home/vuser/.ssh/config
cat /90-work/git-work/known_hosts | tee /home/vuser/.ssh/known_hosts

tar xvJ --acls -C /home/vuser/.ssh/ -f /10-base/lh-bb.tar.xz;
```
