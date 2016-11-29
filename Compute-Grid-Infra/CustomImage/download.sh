# accepts a blob uri (MUST HAVE https:// at the beginning) and a key

[[ -z "$HOME" || ! -d "$HOME" ]] && { echo 'fixing $HOME'; HOME=/root; }
export HOME

install_bloxfer()
{
	apt-get -y update
	apt-get -y install python3-pip libssl-dev libffi-dev npm
	pip3 install --upgrade pip
	pip3 install blobxfer --upgrade
	blobxfer --version
	ln -s /usr/bin/nodejs /usr/bin/node
	npm install -g azure-cli
	azure config mode arm
}

echo $1
echo $2

sa_domain=$(echo "$1" | cut -f3 -d/)
sa_name=$(echo $sa_domain | cut -f1 -d.)
container_name=$(echo "$1" | cut -f4 -d/)
# because blob name can contains / and ., the blobname is in fact the last part after the container name
blob_name=$(echo ${1#*$container_name/})

# file_name is the part after the last /
d=$(echo ${blob_name%/*})
file_name=$(echo ${blob_name#$d/*})

echo "sa_name=$sa_name"
echo "container_name=$container_name"
echo "blob_name=$blob_name"
echo "file_name=$file_name"
echo "$container_name,$blob_name" > /mnt/config.txt

BLOB_MARKER="/mnt/$blob_name"
echo $BLOB_MARKER
if [ -e "$BLOB_MARKER" ]; then
    echo "We're already copied, exiting..."
    exit 0
fi

install_bloxfer

attempts=0
response=1
while [ $response -ne 0 -a $attempts -lt 5 ]
do
  blobxfer $sa_name $container_name /mnt/ --remoteresource $blob_name --storageaccountkey $2 --download --no-computefilemd5
  response=$?
  attempts=$((attempts+1))
done




