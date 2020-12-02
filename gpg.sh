# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ GnuPG configuration                                                       ║
# ║ Use GnuPG's gpg-agent(1) for SSH keys instead of ssh-agent(1)             ║
# ║                                                                           ║
# ║ This file needs to be sources by ~/.bashrc (or similar) if gpg-agent is   ║
# ║ used instead of ssh-agent for SSH keys.                                   ║
# ║                                                                           ║
# ║ If this is not the case, adding "export GPG_TTY=$(tty)" to ~/.bashrc is   ║
# ║ enough.                                                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# Notes:
#
# - There seems to be a bug when gpg(1) is used for the first time to
#   generate a key while the gpg-agent daemon is already running, for example,
#   because this script launched the agent. Therefore, before the very first key
#   is generated make sure that gpg-agent is not running, or the following error
#   shows up:
#
#       gpg: agent_genkey failed: No such file or directory
#
# - All GnuPG tools start the gpg-agent as needed. This is not possible for the
#   SSH support because SSH doesn't know about it. Thus, if no GnuPG tool which
#   accesses the agent has been run, SSH won't be able to use gpg-agent for
#   authentication. So, we have to make sure that gpg-agent is always started
#   with login.
#   Once gpg-agent is running use ssh-add to approve keys, following the same
#   steps as for ssh-agent. The list of approved keys is stored in the
#   ~/.gnupg/sshcontrol file. Once a key is approved, a pinentry dialog pops up
#   every time a passphrase is needed.


# Start gpg-agent if not already running
if ! pgrep -x -u "${USER}" gpg-agent &> /dev/null; then
    gpg-connect-agent /bye &> /dev/null
fi


# Set SSH to use gpg-agent [see gpg-agent(1), section EXAMPLES]. The test is
# needed if the agent is started as 'gpg-agent --daemon /bin/sh', in which case
# the shell inherits SSH_AUTH_SOCK from the parent, gpg-agent.
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi


# Refresh gpg-agent TTY in case user switches into an X session. If the user
# needs to be prompted for a passphrase, which is necessary for decrypting the
# stored key, the ssh-agent protocol does not contain a mechanism for telling
# the agent on which display/terminal it is running. gpg-agent's ssh-support
# will therefore use the TTY or X display where gpg-agent has been started. To
# switch this display to the current one, the following command may be used:
gpg-connect-agent updatestartuptty /bye > /dev/null


# Always set GPG_TTY
export GPG_TTY=$(tty)
