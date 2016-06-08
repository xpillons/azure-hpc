#bash 
SA_NAME="account"
SA_KEY="key"
APP_ID=""
TENAND_ID=""
PASSWORD=""

#############################################################################
log()
{
	echo "$1"
}

while getopts :a:k:u:t:p optname; do
  log "Option $optname set with value ${OPTARG}"
  
  case $optname in
    a)  # storage account
		SA_NAME=${OPTARG}
		;;
    k)  # storage key
		SA_KEY=${OPTARG}
		;;
    u)  # user id
		APP_ID=${OPTARG}
		;;
    t)  # tenand id
		TENAND_ID=${OPTARG}
		;;
    p)  # password
		PASSWORD=${OPTARG}
		;;
  esac
done


######################################################################
install_azure_cli()
{
	curl --silent --location https://rpm.nodesource.com/setup_4.x | bash -
	yum -y install nodejs

	[[ -z "$HOME" || ! -d "$HOME" ]] && { echo 'fixing $HOME'; HOME=/root; } 
	export HOME
	
	npm install -g azure-cli
	azure telemetry --disable
}

######################################################################
install_azure_files()
{
	log "install samba and cifs utils"
	yum -y install samba-client samba-common cifs-utils
	mkdir /mnt/azure
	
	log "azure login"
	#azure login -u $APP_ID --service-principal --tenant $TENAND_ID -p $PASSWORD
	log "create azure share"
	azure storage share create --share lsf -a $SA_NAME -k $SA_KEY
	
	log "mount share"
	mount -t cifs //$SA_NAME.file.core.windows.net/lsf /mnt/azure -o vers=3.0,username=$SA_NAME,password=''${SA_KEY}'',dir_mode=0777,file_mode=0777
	echo //$SA_NAME.file.core.windows.net/lsf /mnt/azure cifs vers=3.0,username=$SA_NAME,password=''${SA_KEY}'',dir_mode=0777,file_mode=0777 >> /etc/fstab
}

install_azure_cli
install_azure_files
