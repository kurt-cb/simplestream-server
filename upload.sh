MYTMPDIR="$(mktemp -d)"
trap 'rm -rf -- "$MYTMPDIR"' EXIT

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

cd $MYTMPDIR
lxc image export $1

squash=$(ls *squashfs)
meta=$(ls meta*)

tar xf $meta metadata.yaml
eval $(parse_yaml metadata.yaml)


box=default
remote=http://localhost:8000/upload
# you MUST obey the date format
upload_date=$(date '+%Y%m%d_%H:%M')

dir="$properties_os/$properties_release/$properties_architecture/$properties_variant/$properties_serial"
echo $dir

ls -l
echo curl "-Fupload=@$meta;filename=$dir/lxd.tar.xz" "$remote/"
curl "-Fupload=@$meta;filename=$dir/lxd.tar.xz" "$remote/"

echo curl "-Fupload=@$squash;filename=$dir/rootfs.squashfs" "$remote/"
curl "-Fupload=@$squash;filename=$dir/rootfs.squashfs" "$remote/"

 
