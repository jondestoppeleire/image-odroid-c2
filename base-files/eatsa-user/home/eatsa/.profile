# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    # shellcheck disable=SC1090
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin directories
PATH="$HOME/bin:$HOME/.local/bin:$PATH"
# Don't set Xauthority file in case we have no permissions to it!
# Wrong permissions to this file causes a TON of trouble.
#export XAUTHORITY=/tmp/Xauthority
export DISPLAY=:0

# run supervisor?  It doesn't seem to display the gui correctly, but X does start.

# this is the command that supervisor runs.  Our issue now is what happens when this process dies.
exec /usr/bin/startx
