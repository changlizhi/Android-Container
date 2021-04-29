#!/bin/bash
# Author: Tong Xing
# Stevens Institute of Technology 2020
# This script will help user dump the docker and recode the image by using criu-het
# It will generate a directroy contains all snapshot images in current pwd.
#set -x
set -e
CID=$1
CHECKPOINT_NAME=$2
TARGET=$3

help()
{
    cat <<- EOF
Desc: Recode is for process dumped images and recode it
Usage: ./recode.sh <Container ID> <Checkpoint Name> <Target ISA>
      - Container ID is the Container ID
      - The checkpoint name generated by docker 
      - The Target ISA (aarch64/x86-64) 
Example: ./recode.sh "Container ID" check_point_name aarch64
Author: Tong Xing,Yi Xiao
Stevens Institute of Technology 2020
EOF
    exit 0
}
while [ -n "$1" ];do
        case $1 in
                -h) help;; # function help is called
                --) shift;break;; # end of options
                -*) echo "error: no such option $1."; exit 1;;
                *) break;;
esac
done
if [ $# != 3 ]
then
    help
fi

IMAGE_ID=$(docker ps  -a --no-trunc | grep $CID |  awk '{print $2}' | sed -n '1p')
PID=$(docker ps  -a --no-trunc | grep $CID |  awk '{print $1}')
BIN_PATH=$(docker image inspect $IMAGE_ID | grep UpperDir)
BIN_PATH=${BIN_PATH%\"*}
BIN_PATH=${BIN_PATH#*\"*\"*\"}



mkdir /var/lib/docker/containers/$PID/checkpoints/$CHECKPOINT_NAME/simple

cp /var/lib/docker/containers/$PID/checkpoints/$CHECKPOINT_NAME/descriptors.json /var/lib/docker/containers/$PID/checkpoints/$CHECKPOINT_NAME/simple

cd /var/lib/docker/containers/$PID/checkpoints/$CHECKPOINT_NAME/; crit recode -t $TARGET -o simple -r $BIN_PATH

cd -

mv /var/lib/docker/containers/$PID/checkpoints/$CHECKPOINT_NAME/simple /tmp/$CHECKPOINT_NAME

for i in /tmp/$CHECKPOINT_NAME/core-*
do
	crit decode -i $i -o $i.dec 
	sed -i 's#"seccomp_mode": "filter",# #' $i.dec
	sed -i 's#"lsm_profile": "docker-default",# #' $i.dec
	crit encode -i $i.dec -o $i
	rm $i.dec
done



