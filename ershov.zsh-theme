# Перемещение по частям пути (разделитель — /)
backward-filesystem-word() {
  local buf="$BUFFER"
  local cur="$CURSOR"
  local pos=$cur

  # Идём назад от курсора, ищем '/'
  while [[ $pos -gt 0 && ${buf[$pos]} != "/" ]]; do
    (( pos-- ))
  done

  # Если не нашли '/', идём до начала
  if [[ $pos -eq 0 && ${buf[1]} != "/" ]]; then
    pos=0
  fi

  # Устанавливаем курсор
  CURSOR=$pos
  zle reset-prompt
}

forward-filesystem-word() {
  local buf="$BUFFER"
  local len=${#buf}
  local cur="$CURSOR"
  local pos=$(( cur + 1 ))

  # Идём вперёд от курсора, ищем '/'
  while [[ $pos -lt $len && ${buf[$pos]} != "/" ]]; do
    (( pos++ ))
  done

  # Если нашли '/', ставим курсор после него
  if [[ $pos -lt $len && ${buf[$pos]} == "/" ]]; then
    (( pos++ ))
  else
    pos=$len
  fi

  CURSOR=$pos
  zle reset-prompt
}

# Удаление по разделителям: . @ : / -
backward-kill-path-component() {
  local buf="$BUFFER"
  local cur="$CURSOR"
  local pos=$cur

  # Символы-разделители
  local delimiters="[@:/\.-]"

  # Идём назад, пока не найдём разделитель или начало строки
  while [[ $pos -gt 0 && ${buf[$pos]} != "[" && ${buf[$pos]} != "@" && ${buf[$pos]} != ":" && ${buf[$pos]} != "/" && ${buf[$pos]} != "." && ${buf[$pos]} != "-" ]]; do
    (( pos-- ))
  done

  # Если остановились на разделителе — включаем его в удаление
  if [[ $pos -gt 0 ]]; then
    (( pos-- ))
  fi

  # Удаляем от pos до cur
  BUFFER="${buf[1,$((pos))]}${buf[$((cur+1)),$len]}"
  CURSOR=$pos
  zle reset-prompt
}

# Регистрируем функции как виджеты ZLE
zle -N backward-filesystem-word
zle -N forward-filesystem-word
zle -N backward-kill-path-component


# Определяет цвет пути в зависимости от прав доступа
get_path_color() {
  local dir="$PWD"
  local perms

  # Получаем права в виде числа (например, 755)
  perms=$(stat -c "%a" "$dir" 2>/dev/null) || {
    PATH_COLOR="%F{red}"  # если stat недоступен
    return
  }

  # Преобразуем в биты (только права владельца)
  local owner_perms=$((0${perms: -3} / 100))

  case $owner_perms in
    7) PATH_COLOR="%F{green}"     ;;  # rwx — полный доступ
    6) PATH_COLOR="%F{208}"       ;;  # rw- — чтение+запись → оранжевый
    5) PATH_COLOR="%F{blue}"      ;;  # r-x — чтение+выполнение
    4) PATH_COLOR="%F{magenta}"   ;;  # r-- — только чтение → фиолетовый
    3) PATH_COLOR="%F{blue}"      ;;  # -wx — запись+выполнение (редко)
    2) PATH_COLOR="%F{208}"       ;;  # -w- — только запись → оранжевый
    1) PATH_COLOR="%F{blue}"      ;;  # --x — только выполнение → синий
    0) PATH_COLOR="%F{red}"       ;;  # --- — нет доступа → красный
    *) PATH_COLOR="%F{red}"       ;;  # на всякий случай
  esac
}

# === Пользовательское приглашение с Git с цветами для каждого статуса ===
git_prompt_info() {
  # Быстрая проверка: есть ли .git?
  if [[ ! -d .git ]] && [[ ! -f .git ]]; then
    GIT_PROMPT=""
    return
  fi

  # Получаем имя ветки
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || \
  branch=$(git rev-parse --short HEAD 2>/dev/null) || {
    GIT_PROMPT=""
    return
  }

  local staged=""
  local modified=""
  local untracked=""

  # Получаем статус в формате porcelain=v2
  local -a status_lines
  status_lines=("${(@f)$(git status --porcelain=v2 2>/dev/null)}")

  for line in $status_lines; do
    [[ -z "$line" ]] && continue

    case $line[1] in
      '1')  # Отслеживаемые файлы
        local x=${line[3]}  # X — staged
        local y=${line[4]}  # Y — рабочая директория

        # Staged: A (added), M (modified), D (deleted), R (renamed)
        if [[ $x == [AMDR] ]]; then
          staged="%F{green}✚%f"
        fi

        # Modified: M (modified), D (deleted)
        if [[ $y == [MD] ]]; then
          modified="%F{208}✘%f"
        fi
        ;;
      '?')  # Untracked
        untracked="%F{red}?%f"
        ;;
    esac
  done

  # Цвет ветки — фиолетовый
  local branch_color="%F{magenta}"

  # Собираем результат
  if [[ -n "$staged$modified$untracked" ]]; then
    GIT_PROMPT="${branch_color}(${branch}${staged}${modified}${untracked})%f"
  else
    GIT_PROMPT="${branch_color}(${branch})%f"
  fi
}

# Файл ~/.zshrc для нелогиновых оболочек zsh.
# Примеры: /usr/share/doc/zsh/examples/zshrc

setopt autocd              # Переход в директорию простым вводом её имени
#setopt correct            # Автоматическое исправление опечаток
setopt interactivecomments # Разрешить комментарии в интерактивном режиме
setopt ksharrays           # Массивы начинаются с индекса 0
setopt magicequalsubst     # Включить расширение имён файлов для аргументов вида «что-то=выражение»
setopt nonomatch           # Скрывать сообщение об ошибке, если шаблон не найден
setopt notify              # Немедленно сообщать о статусе фоновых задач
setopt numericglobsort     # Сортировать имена файлов численно, когда это уместно
setopt promptsubst         # Включить подстановку команд в приглашении

WORDCHARS=${WORDCHARS//\/} # Не считать некоторые символы частью слова

# Скрыть знак конца строки ('%')
export PROMPT_EOL_MARK=""

# Настройка клавиатурных привязок
bindkey -e                                        # Клавиши в стиле Emacs
bindkey ' ' magic-space                           # Расширение истории при нажатии пробела подставляется команда из истории но не выполняется
bindkey '^[[3;5~' kill-word                       # Ctrl + Delete Удаляет слово справа от курсора
bindkey '^[[1;5C' forward-word                    # Ctrl + → Перемещает курсор на одно слово вправо
bindkey '^[[C' forward-word                       # Ctrl + → (альтернативный код) Перемещает курсор на одно слово вправо
bindkey '^[[1;5D' backward-word                   # Ctrl + ← Перемещает курсор на одно слово влево
bindkey '^[[D' backward-word                      # Ctrl + ← (альтернативный код) Перемещает курсор на одно слово влево
bindkey '^[[5~' beginning-of-buffer-or-history    # Page Up Прокручивает вверх по истории команд, как стрелка вверх, но быстрее
bindkey '^[[6~' end-of-buffer-or-history          # Page Down Прокручивает вниз по истории (обратно к новым командам)
bindkey '^[[Z' undo                               # Shift + Tab — отмена последнего действия. Отменяет последнее изменение в строке (например, удаление слова, ввод символа)
# Alt + ← / → — перемещение по частям пути (разделитель: /)
bindkey '^[^[[D' backward-filesystem-word   # Alt + ←
bindkey '^[^[[C' forward-filesystem-word    # Alt + →
bindkey '^[[1;3D' backward-filesystem-word   # Alt + ← (альтернативный код)
bindkey '^[[1;3C' forward-filesystem-word    # Alt + → (альтернативный код)
# Alt + Backspace — удаление по разделителям (@, :, /, ., -)
bindkey '\e^?' backward-kill-path-component  # Alt + Backspace

# Включение функций автодополнения
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Регистронезависимое автодополнение

# Настройки истории
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first # Удалять дубликаты первыми при превышении размера истории
setopt hist_ignore_dups       # Игнорировать дублирующиеся команды в истории
setopt hist_ignore_space      # Игнорировать команды, начинающиеся с пробела
setopt hist_verify            # Показывать команду с расширением истории перед выполнением
#setopt share_history         # Совместно использовать историю между сессиями

# Заставить zsh показывать полную историю
alias history="history 0"

# Сделать less дружелюбнее к не-текстовым файлам (см. lesspipe(1))
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Установить переменную, идентифицирующую chroot-окружение (используется в приглашении)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Установить красивое приглашение (без цвета, если не уверены в поддержке)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# Раскомментируйте для цветного приглашения, если терминал поддерживает цвета.
# По умолчанию отключено, чтобы не отвлекать: фокус должен быть на выводе команд, а не на приглашении.
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# Поддержка цвета есть; предполагаем совместимость с Ecma-48 (ISO/IEC-6429).
	# Отсутствие такой поддержки крайне редко, и в таких случаях обычно используется setf вместо setaf.
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
     PROMPT='%F{blue}%f %F{blue}%n%f %F{blue}%f %F{yellow}%m%f %F{green}%f ${PATH_COLOR}%~%f ${GIT_PROMPT}
%F{%(?.green.red)}❯%f '
    RPROMPT=$'%(?.. %? %F{red}%B⨯%b%F{reset})%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'

    # Включить подсветку синтаксиса
    if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && [ "$color_prompt" = yes ]; then
	# ksharrays ломает плагин. Это уже исправлено, но пока отключим.
	# https://github.com/zsh-users/zsh-syntax-highlighting/pull/689    
	unsetopt ksharrays
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
	ZSH_HIGHLIGHT_STYLES[path_pathseparator]=
	ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=
	ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
	ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
	ZSH_HIGHLIGHT_STYLES[command-substitution]=none
	ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta
	ZSH_HIGHLIGHT_STYLES[process-substitution]=none
	ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta
	ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=magenta
	ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=magenta
	ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
	ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
	ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
	ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
	ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
	ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
	ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta
	ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta
	ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta
	ZSH_HIGHLIGHT_STYLES[assign]=none
	ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
	ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
	ZSH_HIGHLIGHT_STYLES[named-fd]=none
	ZSH_HIGHLIGHT_STYLES[numeric-fd]=none
	ZSH_HIGHLIGHT_STYLES[arg0]=fg=green
	ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
	ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
	ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
	ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
	ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
	ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
	ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
    	
    fi
else
    PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%# '
fi
unset color_prompt force_color_prompt

# Если это xterm, установить заголовок окна в формате user@host:dir
case "$TERM" in
xterm*|rxvt*)
    TERM_TITLE='\e]0;${debian_chroot:+($debian_chroot)}%n@%m: %~\a'
    ;;
*)
    ;;
esac

new_line_before_prompt=yes
precmd() {
    git_prompt_info  # ← ВЫЗОВ НАШЕЙ ФУНКЦИИ
    get_path_color # ← новая строка

    # Вывести ранее настроенный заголовок
    print -Pn "$TERM_TITLE"

    # Вывести пустую строку перед приглашением, но только если это не первая строка
    if [ "$new_line_before_prompt" = yes ]; then
	if [ -z "$_NEW_LINE_BEFORE_PROMPT" ]; then
	    _NEW_LINE_BEFORE_PROMPT=1
	else
	    print ""
	fi
    fi
}

# Включить цветовую поддержку для ls, less и man, а также добавить удобные алиасы
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    export LESS_TERMCAP_mb=$'\E[1;31m'     # Начало мигания
    export LESS_TERMCAP_md=$'\E[1;36m'     # Начало жирного шрифта
    export LESS_TERMCAP_me=$'\E[0m'        # Сброс жирного/мигания
    export LESS_TERMCAP_so=$'\E[01;33m'    # Начало инверсии (reverse video)
    export LESS_TERMCAP_se=$'\E[0m'        # Сброс инверсии
    export LESS_TERMCAP_us=$'\E[1;32m'     # Начало подчёркивания
    export LESS_TERMCAP_ue=$'\E[0m'        # Сброс подчёркивания

    # Использовать $LS_COLORS и для автодополнения
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# Дополнительные алиасы для ls
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# Включить автоподсказки на основе истории
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    # Изменить цвет подсказок
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi
