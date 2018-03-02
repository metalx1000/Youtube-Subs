#!/bin/bash
func="$1"
ytdir="$HOME/.ytsubs"
domain="https://www.youtube.com"
subs="$ytdir/ytsubs.lst"
current="$ytdir/current.lst"
tmp="/tmp/yt.tmp"
viewed="$ytdir/viewed.lst"
today="$(date +%s)"
pager=20 #number of lines moved when paging through output
let maxage=1

rm "$tmp"

function main(){
  checkFiles
  if [ "$func" = "update" ]
  then
    update
    clean
    removeOld
  elif [ "$func" = "upgrade" ]
  then
    upgrade
  elif [ "$func" = "list" ]
  then
    list
  elif [ "$func" = "help" ]
  then
    help
  else
    let x=1;
    let y=$pager;
    let l="$(output|wc -l)"
    while [ $x -lt $l ]
    do
      output| sed -n "${x},${y}p"|while read line
      do
        echo "$line"
        sleep .05;
      done
      read -rsn1 -p "Press Enter to Continue..." c
     if [ "$c" = "q" ]
     then
       echo ""
       echo "Good-Bye..."
       exit 0
     elif [ "$c" = "m" ]
     then
       tmux-url-select.pl
     fi 
      printf '\r'
      let x+=$pager;
      let y+=$pager;
    done
  fi

}

function checkFiles(){
  if [ ! -d $ytdir ]
  then
    mkdir -p $ytdir
  fi

  if [ ! -f $subs ]
  then
    echo "https://www.youtube.com/user/metalx1000/videos" > $subs
    echo "https://www.youtube.com/user/BryanLunduke/videos" >> $subs
  fi
}

function update(){
  echo "Updating"
  #rm "$current"
  cat "$subs"|sort -u|while read sub
  do
    getRecent "$sub"
  done
  cp "$tmp" "$current"
}

function getRecent(){
  url="$1"
  channel="$(getChannel "$url")"
  echo "Scanning $url"
  wget -qO- "$url"|\
    grep "yt-lockup-title"|\
    head -n 2|\
    while read line;
    do
      echo -n "$channel|" 
      echo "$line"|\
        sed 's/title="/\ntitle="/g;s/href="/\nhref="/g'|\
        grep -e '^title' -e '^href'|\
        cut -d\" -f2|\
        tr "|" ":"|\
        tr "\n" "|"|\
        sed 's/\/watch?/https:\/\/www.youtube.com\/watch?/'
        #base64 -w 0

      echo ""
    done|tee -a "$tmp"
  }


function getChannel(){
  url="$1"
  wget -qO- "$url"|\
    grep "channel-title"|\
    sed 's/title=/\ntitle=/g'|\
    grep '^title' |\
    cut -d\" -f2
}

function removeOld(){
  cat "$current"|while read line
  do
    title="$(echo "$line"|cut -d\| -f2)"
    url="$(echo "$line"|cut -d\| -f3)"
    date="$(getPubDate "$url")"
    date="$(date --date="$date" +%s)"
    let age="$(echo "($today-$date)/60/60/24"|bc)"
    if [ $age -gt $maxage ]
    then
      echo "Removing $title"
      sed -i "/$title/d" "$current"
    fi

  done
}

function getPubDate(){
  url="$1"
  wget -qO- "$url"|\
    grep 'watch-time-text'|\
    sed 's/Published on /\nPublished on /g'|\
    grep '^Published on '|\
    cut -d\< -f1|\
    sed 's/Published on //g'
}

function upgrade(){
  echo "Downloading Newest Version..."
  wget "https://raw.githubusercontent.com/metalx1000/Youtube-Subs/master/ytsubs.sh" -O "$0";exit
}

function output(){
  cut -d\| -f1 "$current"|sort -u|sed '/^$/d'|while read line
  do
    echo ""
    echo -e "\e[7m$line\e[0m"
    grep "^$line" "$current"|grep 'https'|cut -d\| -f2,3|while read vid
    do
      title="$(echo "$vid"|cut -d\| -f1)"
      link="$(echo "$vid"|cut -d\| -f2)"
      echo -e "\e[1m$title\e[0m"
      echo -e "\e[94m$link\e[0m"
      
    done

  done
}

function clean(){
  echo "===========Clean Up=============="
  awk  -F\| 'BEGIN {OFS="|"} {gsub(/\//,"-",$2); print}' "$current"|sponge "$current"
  awk  -F\| 'BEGIN {OFS="|"} {gsub(/&quot;/,"\"",$2); print}' "$current"|sponge "$current"
  awk  -F\| 'BEGIN {OFS="|"} {gsub(/&#39;/,"`",$2); print}' "$current"|sponge "$current"
  awk  -F\| 'BEGIN {OFS="|"} {gsub(/*/,"=",$2); print}' "$current"|sponge "$current"
}

function list(){
  $EDITOR "$subs"
}

function help(){
  echo "Usage: $0 option"
  echo "===Options=="
  echo "help"
  echo "update - Update Current Video List"
  echo "upgrade - Upgrade $0 to Newest Version"
  echo "list - Edit Sub list"
}

main
