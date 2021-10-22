shopt -s autocd cdspell direxpand dirspell globstar histreedit histverify nocaseglob xpg_echo

function cdn {
    local cmd

    for ((i=0; i < $1; i++)); do
        cmd+="../"
    done

    cd "$cmd"
}


dots='../'

for i in {2..9}; do
  dots+='../'
  alias ."$i"="cd $dots"
done

unset dots

bind 'set completion-ignore-case on'

HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F, %T '
HISTIGNORE="[[:space:]]*:&:?:exit"
function historymerge {
    history -n; history -w; history -c; history -r
}

function _hist_exit {
    history -n; history -w
}

trap _hist_exit EXIT
#PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

_dedup_hist() {
    history -a
    history -c
    tac "${HISTFILE:?}"|awk '!a[$0]++'|tac > ~/".hist.tmp.$$" &&
    mv ~/".hist.tmp.$$" "$HISTFILE"
}

_dedup_hist

VISUAL='vim'
EDITOR="$VISUAL"
FCEDIT="$EDITOR"
LESSEDIT="$EDITOR"

function conflicts (

shopt -q xpg_echo || shopt -s xpg_echo

if ! git rev-parse --git-dir &> /dev/null
then
  echo "\nNot a git repository" >&2
  return 1
fi

local conflicting_file="$(git diff --check|awk 'NR==1{print $1}' FS=:)" \
git_dir="$(git rev-parse --git-dir)"
[ -z "$EDITOR" ] && local EDITOR="vim"

if [ -n "$conflicting_file" ]
  then eval "$EDITOR" "$conflicting_file"
  if ! git diff --check|grep -Fq "$conflicting_file"
    then git add "$conflicting_file"
  fi
elif ! ls "$git_dir"|egrep -q '(REBASE|MERGE|CHERRY_PICK|REVERT).*_HEAD|rebase-(apply|merge)'
  then echo "\nNo action in progress.\n" >&2
else echo "\nNo other conflicts!\n"
  read -p "Would you like to continue? [Y/n] "
  case "${REPLY,,}" in
    y|yes)
      for i in rebase cherry_pick revert merge; do
        if grep -qm1 ^${i^^}_.*HEAD$ < <(ls -t1 "$git_dir"); then
          git "${i/_/-}" --continue
          return
        fi
      done

      if egrep -qm1 ^rebase-apply/?$ < <(ls -t1 "$git_dir")
        then git am --continue
      elif egrep -qm1 ^rebase-merge/?$ < <(ls -t1 "$git_dir")
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

