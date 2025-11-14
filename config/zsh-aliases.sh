# General
# TODO: log all aliases (+their commands maybe)
# TODO: log alias command
# TODO: update aliases from this gist

# GIT
# TODO check for oh-my-zsh git aliases and remove duplicated - https://kapeli.com/cheat_sheets/Oh-My-Zsh_Git.docset/Contents/Resources/Documents/index
alias gita='git add .'
alias gits='git status'
alias gitd='git diff'
alias gitl='git log'
alias gitlp='git log -p'
alias gitc='git commit -m "$@"'
alias gitca='git commit --amend -m "$@"'
alias gitrs='git restore --staged "$@"'
alias gitpo='git push origin'
alias gitpp='git push --set-upstream origin $(git branch --show-current)'
alias gitbu='git fetch --all; git pull upstream $(git branch --show-current)'
alias gitcwip='git add --all; git commit -m "wip" --no-verify'
alias gitremotefix='git remote rename origin upstream; git remote add origin git@github.com:antonbsa/bigbluebutton.git'

# Code review
function checkpr() {
	# checkpr [PR-ID]* [BRANCH_NAME]
	if [[ ! "$1" ]]; then
		echo "Missing ID: checkpr <PR_ID>"
		return;
	fi;

	PR_NUMBER="$1";
	BRANCH_NAME="pr-$PR_NUMBER";

	if [[ "$2" ]]; then
		BRANCH_NAME="$2"
	fi;

	CURRENT_BRANCH=$(git branch --show-current) || return;	# throw error if it's not in a git reporsitory

	if [[ "$CURRENT_BRANCH" != *"release"* && "$CURRENT_BRANCH" != "develop" ]] then
		echo "ERROR: Not in a base branch, currently at "\"$CURRENT_BRANCH"\""
		return;
	fi;

	# TODO add update option to do so in the base branch
	# TODO add [--update]
	# if SHOULD_UPDATE
	# ...

	#todo find a way to avoid in all lines, if possible without repeating this same approach on each line
	# following line avoid continue the execution when throwing an error.
	$(git fetch upstream pull/$PR_NUMBER/head:$BRANCH_NAME) || return;	# throw error if invalid ID has been passed
	git checkout $BRANCH_NAME
	git fetch upstream
	git merge --no-edit upstream/$CURRENT_BRANCH
}

# Ubuntu
findf='find ~/ -type f -name "$@"'

# Random
alias py='python3'
