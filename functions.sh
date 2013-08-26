# Common Functions 

apt_install () {

apt-get -y install  "$@"

}



updateOS() {

apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade -y

}

EnableForwarding() {

	sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
	sysctl -p
}

CommentAppend() {
        # Comment line and append line below commented line
        local comment="$( echo "$1" | sed 's/\(\/\)/\\\//g' )"  # search this line and comment it
        local append="$( echo "$2" | sed 's/\(\/\)/\\\//g' )"   # Append this line below commented line
        local InputFile="$3"


        sed -i "s/^${comment}/#${comment}/g" $InputFile
		if ! grep  "${append}" $InputFile >/dev/null 2>&1; then
				sed -i "s/#${comment}/& \n${append}/" $InputFile
		fi
}

CreateOpenrc() {
	# this function for creating credential file 
	. ./setup.conf
	if [[ ! -f ~/openrc ]]; then 
	cat <<-EOF >> ~/openrc 
	export OS_TENANT_NAME=${OS_TENANT_NAME-:admin}
	export OS_USERNAME=${OS_USERNAME-:admin}
	export OS_PASSWORD=${OS_PASSWORD-:admin_pass}
	export OS_AUTH_URL="http://${Controller_node_IP_API}:5000/v2.0/"
	EOF
	echo ". ~/openrc" >> ~/.bashrc
	fi
	source ~/.bashrc
}


function AppendIfnotExists() {
while read s
do
        inputFile="$2"
        # if starting content matched then comment them
        local startStr=$( echo "${s}" | cut -d" " -f1 )
        grep  "^#${s}"  $inputFile  >/dev/null 2>&1 || sed -i "s/^$startStr/#$startStr/g" $inputFile
        if ! grep  "^${s}" $inputFile >/dev/null 2>&1; then
                echo "${s}" >> $inputFile
        fi
done <<< "$1"

}





