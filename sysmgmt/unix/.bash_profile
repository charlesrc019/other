# Initialize variables.
SSH_ENV="$HOME/.ssh/environment"

# Define functions.
function start_agent {
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
}

# Check if SSH agent is started.
if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi

# Add GitHub key.
ssh-add ~/.ssh/github > /dev/null
echo ""

# Reset bash leadline.
export PS1='[\u@\h \W]\$ '
