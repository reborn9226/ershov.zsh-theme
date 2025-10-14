# --- Модули и базовые опции ---
zmodload zsh/stat   # встроенный stat (быстрее внешнего stat)

setopt autocd              # cd по имени директории
setopt interactivecomments # комментарии в интерактивном режиме
setopt magicequalsubst     # расширение имён в x=y
setopt nonomatch           # не ругаться на шаблон без совпадений
setopt notify              # сразу сообщать о завершении фоновых задач
setopt numericglobsort     # числовая сортировка
setopt promptsubst         # подстановки в приглашении
setopt hist_expire_dups_first hist_ignore_dups hist_ignore_space hist_verify
setopt extended_history    # время/дата в истории
setopt noclobber           # защита от перезаписи через > (исп. >| при необходимости)
setopt no_flow_control     # отключить XON/XOFF для удобства

# Выравниваем определение "слов" с логикой виджетов
WORDCHARS='*?_[]~=&;!#$%^(){}<>'

export PROMPT_EOL_MARK=""

# --- Виджеты ZLE: навигация по пути и удаление компонентов ---
# Унифицированные разделители для виджетов
local_delims=(/ . : @ -)

is_delim() { [[ " ${local_delims[*]} " == *" $1 "* ]]; }

backward-filesystem-word() {
  local buf=$BUFFER cur=$CURSOR pos=$cur
  (( pos <= 0 )) && return
  (( pos-- ))
  while (( pos > 0 )); do
    is_delim ${buf[$pos]} && break
    (( pos-- ))
  done
  CURSOR=$pos
  zle reset-prompt
}

forward-filesystem-word() {
  local buf=$BUFFER len=${#BUFFER} cur=$CURSOR pos=$(( cur + 1 ))
  while (( pos < len )); do
    is_delim ${buf[$pos]} && { (( pos++ )); break }
    (( pos++ ))
  done
  CURSOR=$pos
  zle reset-prompt
}

backward-kill-path-component() {
  local buf=$BUFFER cur=$CURSOR start=$cur
  (( cur <= 0 )) && return
  (( start-- ))
  while (( start > 0 )); do
    local ch=${buf[$start]}
    is_delim $ch && break
    (( start-- ))
  done
  (( start < 1 )) && start=0
  BUFFER="${buf[1,$start]}${buf[$((CURSOR+1)),-1]}"
  CURSOR=$start
  zle reset-prompt
}

zle -N backward-filesystem-word
zle -N forward-filesystem-word
zle -N backward-kill-path-component

# --- Клавиатурные привязки ---
bindkey -e
bindkey ' ' magic-space
bindkey '^[[3;5~' kill-word
bindkey '^[[1;5C' forward-word
bindkey '^[[C'    forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[D'    backward-word
bindkey '^[[5~'   beginning-of-buffer-or-history
bindkey '^[[6~'   end-of-buffer-or-history
bindkey '^[[Z'    undo
bindkey '^[^[[D'  backward-filesystem-word
bindkey '^[^[[C'  forward-filesystem-word
bindkey '^[[1;3D' backward-filesystem-word
bindkey '^[[1;3C' forward-filesystem-word
bindkey '\e^?'   backward-kill-path-component
# Поиск как в fish (по подстроке)
bindkey '^R' history-incremental-pattern-search-backward
bindkey '^S' history-incremental-pattern-search-forward

# --- Completion ---
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Zа-яА-Я}={A-Za-zА-Яа-я}' \
  'r:|=* l:|=*'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'

# Быстрые алиасы для директорий
hash -d w=/var/www -d l=/var/log -d d=~/Downloads

# --- История ---
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
alias history='history 0'

# --- Цвета для ls/grep/diff и less ---
if command -v dircolors >/dev/null 2>&1; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias ll='ls -lh --group-directories-first'
  alias la='ls -lAh --group-directories-first'
  alias l='ls -CF'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
  alias diff='diff --color=auto'
  alias ip='ip --color=auto'
  export LESS_TERMCAP_mb=$'\E[1;31m'
  export LESS_TERMCAP_md=$'\E[1;36m'
  export LESS_TERMCAP_me=$'\E[0m'
  export LESS_TERMCAP_so=$'\E[01;33m'
  export LESS_TERMCAP_se=$'\E[0m'
  export LESS_TERMCAP_us=$'\E[1;32m'
  export LESS_TERMCAP_ue=$'\E[0m'
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# --- Подсветка синтаксиса и автоподсказки ---
# Важно: ksharrays конфликтовал — не включаем его вовсе.
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
  ZSH_HIGHLIGHT_STYLES[default]=none
  ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold
  ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
  ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=green,underline
  ZSH_HIGHLIGHT_STYLES[global-alias]=fg=magenta
  ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
  ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
  ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=green,underline
  ZSH_HIGHLIGHT_STYLES[path]=underline
  ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
  ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
  ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta
  ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta
  ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=magenta
  ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=magenta
  ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
  ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
  ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
  ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta
  ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta
  ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta
  ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
  ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
  ZSH_HIGHLIGHT_STYLES[arg0]=fg=green
  ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
  ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
  ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
  ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
  ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
  ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
  ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
fi

if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_ASYNC=1
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=51200
fi

# --- Терминальный заголовок ---
case "$TERM" in
  xterm*|rxvt*) TERM_TITLE='\e]0;%n@%m: %~\a' ;;
  *) TERM_TITLE=''
esac

# --- Цвет пути по правам (через zstat, без внешних вызовов) ---
PATH_COLOR=%F{green}
get_path_color() {
  local -a s
  zstat -H s +mode "$PWD" 2>/dev/null || { PATH_COLOR='%F{red}'; return }
  local m=$s[mode]                    # восьмеричный, напр. 40755
  local owner=$(( (m >> 6) & 7 ))     # биты rwx владельца
  case $owner in
    7) PATH_COLOR='%F{green}'   ;;
    6) PATH_COLOR='%F{208}'     ;;
    5|3|1) PATH_COLOR='%F{blue}';;
    4) PATH_COLOR='%F{magenta}' ;;
    2) PATH_COLOR='%F{208}'     ;;
    0|*) PATH_COLOR='%F{red}'   ;;
  esac
}

# --- Лёгкий кэш Git-индикатора ---
typeset -gA __git_cache
GIT_PROMPT=""
_git_ckey() {
  local head idx ts
  head=$(command git rev-parse --short HEAD 2>/dev/null) || return 1
  idx=$(command git rev-parse --git-dir 2>/dev/null)/index
  ts=$( [[ -e $idx ]] && zstat +mtime -- "$idx" 2>/dev/null )
  print -r -- "$PWD:$head:$ts"
}

git_prompt_info() {
  command git rev-parse --is-inside-work-tree &>/dev/null || { GIT_PROMPT=""; return }
  local ckey; ckey=$(_git_ckey) || { GIT_PROMPT=""; return }
  [[ -n $__git_cache[$ckey] ]] && { GIT_PROMPT=$__git_cache[$ckey]; return }

  local branch; branch=$(command git symbolic-ref --short HEAD 2>/dev/null || command git rev-parse --short HEAD 2>/dev/null) || { GIT_PROMPT=""; return }

  local -a s; s=(${(f)"$(command git status --porcelain=v2 -uno 2>/dev/null)"})
  local staged modified untracked
  for line in $s; do
    [[ -z $line ]] && continue
    case $line[1] in
      1) local x=${line[3]} y=${line[4]}
         [[ $x == [AMDR] ]] && staged="%F{green}✚%f"
         [[ $y == [MD]   ]] && modified="%F{208}✘%f" ;;
      \?) untracked="%F{red}?%f" ;;
    esac
  done
  local branch_color='%F{magenta}'
  GIT_PROMPT=${branch_color}"(${branch}${staged}${modified}${untracked})%f"
  __git_cache[$ckey]=$GIT_PROMPT
}

# --- Укорачивание пути для глубоких директорий ---
shorten_path() {
  local p=${1:-$PWD} IFS=/ parts=(${(s:/:)p})
  (( ${#parts} > 3 )) && print -r -- "/${parts[1]}/…/${parts[-1]}" || print -r -- "$p"
}

# --- Тайминг последней команды для RPROMPT ---
typeset -g __cmd_start=0 __last_duration=0
preexec() { __cmd_start=$EPOCHREALTIME }

# --- PROMPT/RPROMPT и precmd ---
new_line_before_prompt=yes
if [[ $TERM == *-256color || $TERM == xterm-color ]]; then color_prompt=yes; fi

if [[ $color_prompt == yes ]]; then
  PROMPT='%F{blue}%f %F{blue}%n%f %F{yellow}%m%f %F{green}%f ${PATH_COLOR}$(shorten_path)%f ${GIT_PROMPT}
%F{%(?.green.red)}%(!.#.❯)%f '
  RPROMPT='%(?.. %? %F{red}⨯%f) ${${((__last_duration>0.2)):+%F{cyan}${__last_duration}s%f}} %(1j. %F{yellow}⚙ %j%f .)'
else
  PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%# '
fi

precmd() {
  # обновляем git и цвет пути
  git_prompt_info
  get_path_color

  # заголовок окна
  [[ -n $TERM_TITLE ]] && print -Pn "$TERM_TITLE"

  # длительность последней команды
  if (( __cmd_start )); then
    local now=$EPOCHREALTIME
    __last_duration=$(( now - __cmd_start ))
    __cmd_start=0
  fi

  # пустая строка перед приглашением (со 2-й строки)
  if [[ $new_line_before_prompt == yes ]]; then
    if [[ -z $_NEW_LINE_BEFORE_PROMPT ]]; then
      _NEW_LINE_BEFORE_PROMPT=1
    else
      print ""
    fi
  fi
}

unset color_prompt
