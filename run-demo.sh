#!/bin/sh

#set -x
##-----------------------------------------------------------------------------
## if image not available -> build it
##-----------------------------------------------------------------------------
image=$(docker images | grep 'demo/mydata-image')
if [ -z "$image" ]; then
  echo "image not build. creating it now ..."
  docker build --rm -t demo/mydata-image dataonly-image
fi

##-----------------------------------------------------------------------------
## if container not already created -> create it
##-----------------------------------------------------------------------------
container=$(docker ps -a | grep 'mydata-container')
if [ -z "$container" ]; then
  echo "data container not created. creating it now ..."

  ## NOTE: this container cannot be run, because there are no binaries in it
  ##       It is just created to export its data ...
  docker create --name 'mydata-container' demo/mydata-image true
else
  echo "data container found"
fi

##-----------------------------------------------------------------------------
## now mount it ...
##-----------------------------------------------------------------------------
echo "mounting data volume /mydata into temporary container ..."
docker run --rm --volumes-from mydata-container busybox ls -ltr /mydata

echo "mounting it again in another container and write to it ..."
docker run --rm --volumes-from mydata-container busybox sh -c 'echo "blablabla" > /mydata/$(date +%s).dat'

echo "... and again another container ..."
docker run --rm --volumes-from mydata-container busybox ls -ltr /mydata
