MYTMPDIR="$(mktemp -d)"
trap 'rm -rf -- "$MYTMPDIR"' EXIT
set -e

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}


IMAGE=$1
REMOTE=$2/upload
DOWNLOAD=$3

if [ "$2" == "" ]; then
   echo Usage: ./upload.sh {alias} {simplestream_server} {download}
   echo 
   echo Example: ./upload.sh ubuntu/bionic http://localhost:8000
   echo  This will get the local:ubuntu/bionic image and post it
   echo  to the simplestreams server
   echo
   echo if you want to download from an upstream server to local:
   echo first, then use the last argument to specify the upstream
   echo server.
   echo
   echo Example: ./upload.sh ubuntu/bionic http://localhost:8000 images:
   echo  This will copy the image to the local store, then perform
   echo  the upload
   echo
   exit 1
fi
cd $MYTMPDIR

if [ "$DOWNLOAD" != "" ]; then
   lxc image copy ${DOWNLOAD}${IMAGE} local: --copy-aliases --public
fi
lxc image export ${IMAGE}

squash=$(ls *squashfs)
meta=$(ls meta*)

tar xf $meta metadata.yaml
eval $(parse_yaml metadata.yaml)


box=default

# you MUST obey the date format
upload_date=$(date '+%Y%m%d_%H:%M')

dir="$properties_os/$properties_release/$properties_architecture/$properties_variant/$properties_serial"
echo $dir

ls -l
echo curl "-Fupload=@$meta;filename=$dir/lxd.tar.xz" "${REMOTE}/images"
curl "-Fupload=@$meta;filename=$dir/lxd.tar.xz" "${REMOTE}/images"
mv $squash rootfs.squashfs
echo curl "-Fupload=@rootfs.squashfs;filename=$dir/rootfs.squashfs" "${REMOTE}/images"
curl "-Fupload=@rootfs.squashfs;filename=$dir/rootfs.squashfs" "${REMOTE}/images"

# note, trap above will delete the temp directory

echo Success: use "lxd image list {server}" to see the new image
