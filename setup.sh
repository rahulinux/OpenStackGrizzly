#!/usr/bin/env bash
# Setup.sh

t(){ type "$1"&>/dev/null;}
function Menu.Show {
   local DIA DIA_ESC; while :; do
      t whiptail && DIA=whiptail && break
      t dialog && DIA=dialog && DIA_ESC=-- && break
      exec date +s"No dialog program found"
   done; declare -A o="$1"; shift
   $DIA --backtitle "${o[backtitle]}" --title "${o[title]}" \
      --menu "${o[text]}" 0 0 0 $DIA_ESC "$@"; }



Selected_Node="$( Menu.Show '([backtitle]="OpenStack Installation"
            [title]="OpenStack Grizzly Install"
            [question]="Please choose:")'       \
												\
						"Controller" "Node"     \
						"Network" "Node"		\
						"Compute" "Node" 3>&2 2>&1 1>&3- )"

case "${Selected_Node}" in 
	
			Controller)
						bash -x controller_node.sh ;;
			Network)
						./network_node.sh ;; 
			Compute)
					    ./compute_node.sh ;;
esac 
