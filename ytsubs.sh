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
  cat "$subs"|while read sub
  do
    getRecent "$sub"
  done
}

function getRecent(){
  url="$1"
  echo "Scanning $url"
  wget -qO- "$url"|\
    grep "yt-lockup-title"|\
    head -n 2|\
    while read line;
    do 
      echo "$line"|\
        sed 's/title="/\ntitle="/g;s/href="/\nhref="/g'|\
        grep -e '^title' -e '^href'|\
        cut -d\" -f2|\
        tr "\n" "|"
        #base64 -w 0

      echo ""
    done > "$current" 
  }


main
