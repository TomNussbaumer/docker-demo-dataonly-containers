#------------------------------------------------------------------------------
# 'FROM scratch' is the purest from of a Docker container. It starts completely
# empty. 
#
# NOTE: Since there are no regular binaries in it, you cannot run a container
#       from this image. You can only use 'docker create', but this is enough
#       to export it's volume to be used with --volumes-from elsewhere 
#
# The files in the exported volume belong to root (uid:gid=0:0). If you need
# some extra functionality like mapping the files to a special uid:gid 
# combination you can use 'FROM busybox' or some other mini-distro.  
#------------------------------------------------------------------------------
FROM scratch
ADD mydata /mydata

## if you use "FROM busybox" or similiar, you can change uid:gid like this:
# RUN chown -R 1000:1000 /mydata 

VOLUME /mydata