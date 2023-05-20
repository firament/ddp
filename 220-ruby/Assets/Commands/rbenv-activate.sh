#!/bin/bash
eval "$(~/.rbenv/bin/rbenv init - bash)";
echo 'eval "$(~/.rbenv/bin/rbenv init - bash)";' | tee -a /home/$DEVELOPER_LOGIN/.bashrc;
rbenv install 3.2.2;
rbenv rehash;
rbenv global 3.2.2;
# gems for debug
gem install --no-document debug rubocop rubygems-server
