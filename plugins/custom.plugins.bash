shopt -s autocd cdspell direxpand dirspell globstar histreedit histverify nocaseglob xpg_echo

function cdn {
    local cmd i

    for ((i=0; i < $1; i++)); do
        cmd+="../"
    done

    cd "$cmd"
}


dots='../'

for ((i=2; i <= 12; i++)); do
  dots+='../'
  alias "${dots//.\/}."="$dots"
  alias ".$i"="$dots"
done

unset dots i

HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F, %T '
HISTIGNORE="[[:space:]]*:&:?:exit"
function historymerge {
    history -n; history -w; history -c; history -r
}

function _hist_exit {
    history -n; history -w
}

# trap _hist_exit EXIT
# PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

_dedup_hist() {
    local -i RELOAD=0

    # print only one line of history to make the test faster
    [[ -n "$(history 1)" ]] && ((RELOAD++))

    history -a
    history -c

    if hash sponge 2>/dev/null; then
        tac "${HISTFILE:?}"|awk '!a[$0]++'|tac|sponge "$HISTFILE"
    else
        tac "${HISTFILE:?}"|awk '!a[$0]++'|tac > ~/".hist.tmp.$$" &&
        mv ~/".hist.tmp.$$" "$HISTFILE"
    fi

    # when running `bashit {reload,restart}, there will be no history in the buffer,
    # because `history -c` is ran above.
    # Even worse, upon exit $HISTFILE will be blanked,
    # because an empty buffer will be written to it, thus history will be lost.
    # running `history -r` at the end of the function would be enough, but it turned to be
    # loading $HISTFILE twice on startup, which could be considered not much of a problem,
    # if it didn't go against the initial goal of making sure not having duplicates in history.
    # Duplicates would still be cleared when starting a new shell, but while using,
    # buffer would be holding the same history twice.
    (( RELOAD )) && history -r
}

_dedup_hist

VISUAL='vim'
EDITOR="$VISUAL"
FCEDIT="$EDITOR"
LESSEDIT="$EDITOR"

function conflicts (

shopt -s extglob xpg_echo

local git_dir="$(git rev-parse --git-dir 2>/dev/null)"

if [[ -z "$git_dir" ]]
then
  echo "\nNot a git repository" >&2
  return 1
fi

local conflicting_file="$(git diff --check|awk 'NR==1{print $1}' FS=:)"

if [[ -n "$conflicting_file" ]]
  then "${EDITOR:-vim}" "$conflicting_file"
  if ! git diff --check|\grep -Fwq "$conflicting_file"
    then git add "$conflicting_file"
  fi
elif ! compgen -G "$git_dir/@(@(REBASE|MERGE|CHERRY_PICK|REVERT)*_HEAD|rebase-@(apply|merge))" >/dev/null
  then echo "\nNo action in progress.\n" >&2
else echo "\nNo other conflicts!\n"
  read -p "Would you like to continue? [Y/n] "
  case "${REPLY,,}" in
    y|yes)
      for i in rebase cherry_pick revert merge; do
        if \grep -qm1 ^${i^^}_.*HEAD$ < <(\ls -t1 "$git_dir"); then
          git "${i/_/-}" --continue
          return
        fi
      done

      if \grep -Eqm1 ^rebase-apply/?$ < <(\ls -t1 "$git_dir")
        then git am --continue
      elif \grep -Eqm1 ^rebase-merge/?$ < <(\ls -t1 "$git_dir")
	then git rebase --continue
      else echo "\nCouldn't determine the action in progress.\n" >&2
	return 3
      fi
    ;;
    n|no)
      echo "\nOkay! You can continue manually.\n"
    ;;
    *)
      echo "\nInvalid reply\n" >&2
      return 2
    ;;
  esac
fi
)

alias tcl='rlwrap -A -D2 -c -pred tclsh'
