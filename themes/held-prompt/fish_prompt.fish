set normal (set_color normal)
set magenta (set_color magenta)
set yellow (set_color yellow)
set green (set_color green)
set red (set_color red)
set gray (set_color -o black)

# Fish git prompt
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showupstream 'yes'
set __fish_git_prompt_color_branch yellow
set __fish_git_prompt_color_upstream_ahead green
set __fish_git_prompt_color_upstream_behind red

# Status Chars
set __fish_git_prompt_char_dirtystate '⚡'
set __fish_git_prompt_char_stagedstate '→'
set __fish_git_prompt_char_untrackedfiles '☡'
set __fish_git_prompt_char_stashstate '↩'
#set __fish_git_prompt_char_upstream_ahead '+'
#set __fish_git_prompt_char_upstream_behind '-'
set __fish_git_prompt_show_informative_status 'yes'

function fish_prompt
  and set retc green; or set retc red
  tty|grep -q tty; and set tty tty; or set tty pts

  set_color $retc
  if [ $tty = tty ]
    echo -n .-
  else
    echo -n '┬─'
  end
  set_color -o green
  echo -n [
  if [ $USER = root ]
    set_color -o red
  else
    set_color -o yellow
  end
  echo -n $USER
  set_color -o white
  echo -n @
  if [ -z "$SSH_CLIENT" ]
    set_color -o blue
  else
    set_color -o cyan
  end
  echo -n (hostname)
  set_color -o white
  #echo -n :(prompt_pwd)
  #echo -n :(pwd|sed "s=$HOME=~=")
  set_color -o green
  echo -n ']'

#
# Battery-State
#
  set_color normal
  set_color $retc
  if [ $tty = tty ]
    echo -n '-'
  else
    echo -n '─'
  end

  set_color -o green
  echo -n '['
  set_color normal
  set_color $retc
 _get_battery_state
  set_color -o green
  echo -n ]

  set_color normal
  set_color $retc
  if [ $tty = tty ]
    echo -n '-'
  else
    echo -n '─'
  end

#
# Battery-State-End
#

  set_color -o green
  echo -n '['
  set_color normal
  set_color $retc
  echo -n (date +%X)
  set_color -o green
  echo -n ]

  # Check if acpi exists
  if not set -q __fish_nim_prompt_has_acpi
    if type acpi > /dev/null
      set -g __fish_nim_prompt_has_acpi ''
    else
      set -g __fish_nim_prompt_has_acpi '' # empty string
    end
  end

  if test "$__fish_nim_prompt_has_acpi"
    if [ (acpi -a 2> /dev/null | grep off) ]
      echo -n '─['
      set_color -o red
      echo -n (acpi -b|cut -d' ' -f 4-)
      set_color -o green
      echo -n ']'
    end
  end
  echo
  set_color normal
  for job in (jobs)
    set_color $retc
    if [ $tty = tty ]
      echo -n '; '
    else
      echo -n '│ '
    end
    set_color brown
    echo $job
  end
  set_color normal
  set_color $retc
  if [ $tty = tty ]
    echo -n (pwd|sed "s=$HOME=~=") "'->"
  else
    echo -n '╰─>['(pwd|sed "s=$HOME=~=")']'
  end
  set_color -o red
  echo -n '$ '
  set_color normal
end

function _get_battery_state
  set -l batArray (acpi --battery |  sed "s/ /\n/g")

  if contains 'Battery' $batArray  and contains 'Discharging,' $batArray
     set batteryChar "⏚"
  end

  if contains 'Battery' $batArray  and contains 'Charging,' $batArray
     set batteryChar "⌁"
  end

  if contains 'Battery' $batArray
     set batPercent (echo "$batArray[4]" | rev | cut -c 3- | rev)
     set_color $budspencer_colors[7]
     if test $batPercent -lt 10
       echo -n $batteryChar$batPercent'%'
     end
     if test $batPercent -lt 30
       set_color $budspencer_colors[5]
       echo -n $batteryChar$batPercent'%'
     end
     if test $batPercent -gt 29
       set_color $budspencer_colors[12]
       echo -n $batteryChar$batPercent'%'
     end
  end
end