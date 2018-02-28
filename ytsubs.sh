#!/bin/bash
func="$1"
ytdir="$HOME/.ytsubs"
domain="https://www.youtube.com"
subs="$ytdir/ytsubs.lst"
current="$ytdir/current.lst"
viewed="$ytdir/viewed.lst"

function main(){
  checkFiles
  if [ "$func" = "update" ]
  then
    update
  elif [ "$func" = "upgrade" ]
  then
    upgrade
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
  cat "$subs"|while read sub
  do
    getRecent "$sub"
  done
}

function getRecent(){
  url="$1"
  title="$(getChannel "$url")"
  echo "Scanning $url"
  wget -qO- "$url"|\
    grep "yt-lockup-title"|\
    head -n 2|\
    while read line;
    do
      echo -n "$title|" 
      echo "$line"|\
        sed 's/title="/\ntitle="/g;s/href="/\nhref="/g'|\
        grep -e '^title' -e '^href'|\
        cut -d\" -f2|\
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

function upgrade(){
  echo "Downloading Newest Version..."
  wget "https://raw.githubusercontent.com/metalx1000/Youtube-Subs/master/ytsubs.sh" -O "$0"
}

main
