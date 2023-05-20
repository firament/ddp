# Branding and Customization


## Notes - Buffer
- chown - desktop items
- apt install dconf-cli
- /home/vuser/.config/xfce4/terminal/terminalrc
- /home/vuser/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml
- /home/vuser/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

### dconf usage
Sample commands
```sh
dconf list /
dconf list /org/
dconf list /org/xfce/mousepad/preferences/view/
dconf read /org/xfce/mousepad/preferences/view/font-name
dconf write /org/xfce/mousepad/preferences/view/font-name "'Fira Code 10'"
```
