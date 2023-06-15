
```sh
tar xvJ --acls -f /10-base/lh-bb.tar.xz -C /home/vuser/.ssh/;

git config user.name "sak"
git config user.email "MY_NAME@example.com"

git branch -a
# git clone --branch <branchname> <remote-repo-url> <folder-to-clone-into>
# git clone --branch <branchname> --single-branch <remote-repo-url>

```

### Set consistent `LF` line endings
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
