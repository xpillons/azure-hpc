# accepts a storage account name and a key
[[ -z "$HOME" || ! -d "$HOME" ]] && { echo 'fixing $HOME'; HOME=/root; } 
export HOME 

export AZURE_STORAGE_ACCOUNT="$1" 
export AZURE_STORAGE_ACCESS_KEY="$2" 

blob_name=$(cut -f2 -d, /mnt/config.txt) 
echo $blob_name

BLOB_MARKER="/mnt/$1/$blob_name"
echo "BLOB_MARKER=$BLOB_MARKER"
if [ -e "$BLOB_MARKER" ]; then
    echo "We're already copied, exiting..."
    exit 0
fi

azure storage container create vhds

attempts=0
response=1
while [ $response -ne 0 -a $attempts -lt 5 ]
do
  blobxfer $1 vhds "/mnt/$blob_name" --remoteresource "$blob_name" --storageaccountkey $2 --upload --autovhd --no-computefilemd5 
  response=$?
  attempts=$((attempts+1))
done
 
 # Create marker file so we know we're done with this blob
mkdir -p "$(dirname "$BLOB_MARKER")" && touch "$BLOB_MARKER"

