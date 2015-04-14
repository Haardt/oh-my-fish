###############################################################################
#
# Prompt theme name:
#   budspencer
#
# Description:
#   a sophisticated airline/powerline theme
#
# Author:
#   Joseph Tannhuber <sepp.tannhuber@yahoo.de>
#
# Sections:
#   -> Functions
#     -> Toggle functions
#     -> Command duration segment
#     -> Git segment
#     -> PWD segment
#   -> Prompt
#
###############################################################################

###############################################################################
# => Prompt initialization
###############################################################################

# Initialize some global variables
set -g budspencer_prompt_error
set -g budspencer_current_bindmode_color
set -U budspencer_sessions_active $budspencer_sessions_active
set -U budspencer_sessions_active_pid $budspencer_sessions_active_pid
set -g budspencer_session_current ''
set -g cmd_hist_nosession
set -g cmd_hist cmd_hist_nosession
set -g CMD_DURATION 0
set -g dir_hist_nosession
set -g dir_hist dir_hist_nosession
set -g pwd_hist_lock false
set -g pcount 1
set -g prompt_hist
set -g no_prompt_hist 'F'
set -g symbols_style 'symbols'

# Set PWD segment style
if not set -q budspencer_pwdstyle
  set -U budspencer_pwdstyle short long none
end
set pwd_style $budspencer_pwdstyle[1]

###############################################################################
# => Functions
###############################################################################

################
# => Git segment
################
function __budspencer_is_git_ahead_or_behind -d 'Check if there are unpulled or unpushed commits'
  command git rev-list --count --left-right 'HEAD...@{upstream}' ^ /dev/null  | sed 's|\s\+|\n|g'
end

function _get_git_changed_files -d "Gets the current git status"
  if command git rev-parse --is-inside-work-tree >/dev/null 2>&1
    set -l dirty (command git status -s --ignore-submodules=dirty | wc -l | sed -e 's/^ *//' -e 's/ *$//' 2> /dev/null)
    set -l ref (command git symbolic-ref HEAD | sed  "s-refs/heads/--" | sed -e 's/^ *//' -e 's/ *$//' 2> /dev/null)
    if [ "$dirty" != "0" ]
      set_color -b normal
      set_color red
      if [ "$dirty" != "1" ]
        echo " $dirty changed files"
      else
        echo " $dirty changed file"
      end
    end
  end
end


function __budspencer_git_status -d 'Check git status'
  set -l git_status (command git status --porcelain ^/dev/null | cut -c 1-2)
  set -l added (echo -sn $git_status\n | egrep -c "[ACDMT][ MT]|[ACMT]D")
  set -l deleted (echo -sn $git_status\n | egrep -c "[ ACMRT]D")
  set -l modified (echo -sn $git_status\n | egrep -c ".[MT]")
  set -l renamed (echo -sn $git_status\n | egrep -c "R.")
  set -l unmerged (echo -sn $git_status\n | egrep -c "AA|DD|U.|.U")
  set -l untracked (echo -sn $git_status\n | egrep -c "\?\?")
  echo -n $added\n$deleted\n$modified\n$renamed\n$unmerged\n$untracked
end

function __budspencer_is_git_stashed -d 'Check if there are stashed commits'
  command git log --format="%gd" -g $argv 'refs/stash' -- ^ /dev/null | wc -l
end

function __budspencer_prompt_git_symbols -d 'Displays the git symbols'
  set -l is_repo (command git rev-parse --is-inside-work-tree ^/dev/null)
  if [ -z $is_repo ]
    return
  end

  set -l git_ahead_behind (__budspencer_is_git_ahead_or_behind)
  set -l ab_count 1
  if [ (count $git_ahead_behind) -eq 2 ]
    set -l ab_count (expr $git_ahead_behind[1] + $git_ahead_behind[2])
  end
  set -l git_status (__budspencer_git_status)
  set -l git_stashed (__budspencer_is_git_stashed)

  if [ (expr $git_status[1] + $git_status[2] + $git_status[3] + $git_status[4] + $git_status[5] + $git_status[6] + $git_stashed + $ab_count) -ne 0 ]
    set_color $budspencer_colors[3]
    echo -n ''
    set_color -b $budspencer_colors[3]
      if [ (count $git_ahead_behind) -eq 2 ]
        if [ $git_ahead_behind[1] -gt 0 ]
          set_color -o $budspencer_colors[5]
          echo -n ' ↑'$git_ahead_behind[1]
        end
        if [ $git_ahead_behind[2] -gt 0 ]
          set_color -o $budspencer_colors[5]
          echo -n ' ↓'$git_ahead_behind[2]
        end
      end
          if [ $git_status[1] -gt 0 ]
            set_color -o $budspencer_colors[12]
            echo -n ' +'$git_status[1]
          end
          if [ $git_status[2] -gt 0 ]
            set_color -o $budspencer_colors[7]
            echo -n ' –'$git_status[2]
          end
          if [ $git_status[3] -gt 0 ]
            set_color -o $budspencer_colors[10]
            echo -n ' ✱'$git_status[3]
          end
          if [ $git_status[4] -gt 0 ]
            set_color -o $budspencer_colors[8]
            echo -n ' →'$git_status[4]
          end
          if [ $git_status[5] -gt 0 ]
            set_color -o $budspencer_colors[9]
            echo -n ' ═'$git_status[5]
          end
          if [ $git_status[6] -gt 0 ]
            set_color -o $budspencer_colors[4]
            echo -n ' ●'$git_status[6]
          end
          if [ $git_stashed -gt 0 ]
            set_color -o $budspencer_colors[11]
            echo -n ' ✭'$git_stashed
          end
      end
      set_color -b $budspencer_colors[3] normal
end

function __budspencer_prompt_git_branch -d 'Return the current branch name'
  set -l branch (command git symbolic-ref HEAD ^ /dev/null | sed -e 's|^refs/heads/||')
  if not test $branch > /dev/null
    set -l position (command git describe --contains --all HEAD ^ /dev/null)
    if not test $position > /dev/null
      set -l commit (command git rev-parse HEAD ^ /dev/null | sed 's|\(^.......\).*|\1|')
      echo -n (set_color $budspencer_colors[3])''(set_color -b $budspencer_colors[3])(set_color $budspencer_colors[5])' ➦ '$commit' '(set_color $budspencer_colors[1])
    else
      echo -n (set_color $budspencer_colors[3])''(set_color -b $budspencer_colors[3])(set_color $budspencer_colors[5])'  '$position' '(set_color $budspencer_colors[1])
    end
  else
    _get_git_changed_files
    echo -n (set_color $budspencer_colors[3])''(set_color -b $budspencer_colors[3])(set_color $budspencer_colors[5])'  '$branch' '(set_color $budspencer_colors[1])
  end
end

################
# => PWD segment
################
function __budspencer_prompt_pwd -d 'Displays the present working directory'
  set -l user_host ' '
  if set -q SSH_CLIENT
    if [ $symbols_style = 'symbols' ]
      switch $pwd_style
          case short
            set user_host " $USER@"(hostname -s)':'
          case long
            set user_host " $USER@"(hostname -f)':'
          end
      else
        set user_host " $USER@"(hostname -i)':'
      end
  end
  set_color $budspencer_current_bindmode_color
  echo -n ''
  set_color normal
  set_color -b $budspencer_current_bindmode_color $budspencer_colors[1]
  if [ (count $budspencer_prompt_error) != 1 ]
    switch $pwd_style
      case short
        echo -n $user_host(prompt_pwd)' '
      case long
        echo -n $user_host(pwd)' '
      end
  else
    echo -n " $budspencer_prompt_error "
    set -e budspencer_prompt_error[1]
  end
  set_color normal
end

###############################################################################
# => Prompt
###############################################################################

function fish_right_prompt -d 'Write out the right prompt of the budspencer theme'
  echo -n (__budspencer_prompt_git_branch) (__budspencer_prompt_git_symbols)
  set_color normal
end

#function fish_right_prompt -d "Prints right prompt"
#  get_git_status
#end
