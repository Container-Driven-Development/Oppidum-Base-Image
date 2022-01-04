eval "$(starship init zsh)"

autoload -U +X bashcompinit && bashcompinit
autoload -Uz compinit && compinit
complete -o nospace -C /usr/bin/terraform terraform
complete -C '/usr/bin/aws_completer' aws

alias tf=terraform
alias mk=make