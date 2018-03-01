#!/bin/bash
func="$1"
ytdir="$HOME/.ytsubs"
domain="https://www.youtube.com"
subs="$ytdir/ytsubs.lst"
current="$ytdir/current.lst"
viewed="$ytdir/viewed.lst"
today="$(date +%s)"
let maxage=1

function main(){
  checkFiles
  if [ "$func" = "update" ]
  then
    update
    removeOld
  elif [ "$func" = "upgrade" ]
  then
    upgrade
  else
    output| sed -n "1,22p";read -p "Press Enter to Continue..."
    output| sed -n "20,42p";read -p "Press Enter to Continue..."
    output| sed -n "40,62p";read -p "Press Enter to Continue..."
    output| sed -n "60,82p";read -p "Press Enter to Continue..."
    output| sed -n "80,102p";read -p "Press Enter to Continue..."
    output| sed -n "100,122p";read -p "Press Enter to Continue..."
    output| sed -n "120,142p";read -p "Press Enter to Continue..."
    output| sed -n "140,162p";read -p "Press Enter to Continue..."
    output| sed -n "160,162p";read -p "Press Enter to Continue..."
    output| sed -n "180,202p";read -p "Press Enter to Continue..."
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
  rm "$current"
  cat "$subs"|sort -u|while read sub
  do
    getRecent "$sub"
  done
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
    done|tee -a "$current" 
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
  wget "https://raw.githubusercontent.com/metalx1000/Youtube-Subs/master/ytsubs.sh" -O "$0"
}

function output(){
  cut -d\| -f1 "$current"|sort -u|while read line
  do
    echo ""
    echo -e "\e[7m$line\e[0m"
    grep "^$line" "$current"|cut -d\| -f2,3|while read vid
    do
      title="$(echo "$vid"|cut -d\| -f1)"
      link="$(echo "$vid"|cut -d\| -f2)"
      echo -e "\e[1m$title\e[0m"
      echo "$link"
    done
  done
}

main
