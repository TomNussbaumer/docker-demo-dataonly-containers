# Docker Demo: Data-Only Containers

One of the prime design principles of modern distributed and scalable systems are [immutable servers](https://highops.com/insights/immutable-infrastructure-what-is-it/) which simply means to **strictly separate data and software**.

In relation to Docker that means:

  1. Never ever use `docker commit` to generate new images from running containers
  2. Use Docker Volumes to initialize and persist your data
  
## Docker Volumes

Docker Volumes are a little bit strange, because the Docker CLI (commandline interface) has no commands to manage their lifecylce.

Docker Volumes can be generated in two ways:

  1. in a Dockerfile with keyword 'VOLUME'
  2. as parameter of `docker create` or `docker run`

### Creating Docker Volumes in a Dockerfile 
  
Example of a Dockerfile creating a Docker Volume:

```
FROM scratch
ADD some-data /mydata
VOLUME /mydata
```

Let's build an image from this Dockerfile (supposing you have stored the above example in file Dockerfile and changed the ADD line to add some real files):

```
docker build --rm -t demo/mydata-image .
```

Since we are using `FROM scratch` the generated image contains nothing but the files we have added to it. Due to this minimalism we cannot even use `docker run` (there is no command in the image to be run), but we can only use `docker create` to generate a container from it like this:

```
docker create --name 'mydata-container' demo/mydata-image xyz
```

Well, it doesn't look like something happened, but in the background a new Docker Volume was generated and bound to the container. When you call `docker inspect mydata-container` you will see the new volume listed as entry in Mounts and as entry in Volumes. During the creation of a new volume everything that is in the image below the given path (in this case: /mydata) is copied to the new volume to seed it with files.

The following commands show how to use the new volume:

```shell
# lists the content of the volume
docker run --rm --volumes-from mydata-container busybox ls -ltr /mydata

# writes a new file to the volume
docker run --rm --volumes-from mydata-container busybox sh -c 'echo "blablabla" > /mydata/$(date +%s).dat'

# lists content again
docker run --rm --volumes-from mydata-container busybox ls -ltr /mydata
```

As long as you don't remove the origin container (in this case: mydata-container) you can access the volume by referencing the origin container. If you delete the origin container, the data volume is still there (for the location see the output of `docker inspect`), but you cannot access it anymore from containers directly.

Docker volumes are only deleted when you specify -v when deleting the origin container.

IMHO that's the most stupid design decision made by Docker. Data volumes should be first class entities by their own, with CLI support and whatever. If you are not aware of the creation of Volumes (because they can be hidden in the Dockerfile) these Volumes pile up endlessly wasting more and more of your disk space.


### Creating Docker Volumes during docker create or docker run 

Using VOLUME in a Dockerfile isn't always a good idea, unless the users of the image are completely aware what is happening.

You can also generate new Docker Volumes when calling `docker create` or `docker run`.

If you remove the line starting with `VOLUME` from the above example and build a new image from it, the following command will also generate a new volume:

```shell
docker create -v /mydata --name 'mydata-container' demo/mydata-image xyz
```

From here on everything is exactly the same as in the last section.


### File Permissions

Until now we have used `FROM scratch` in the Dockerfile which is the purest form of a Data-Only Image, but which isn't that useful, because all files on the Docker Volumes will belong to root. 

To overcome this restriction we can embed a minimalistic linux distribution like busybox in the image so we can use keyword RUN in the Dockerfile like this: 

```
FROM busybox
ADD some-data /mydata

## change owner to uid=1000 with guid=1000
RUN chown -R 1000:1000 /mydata
VOLUME /mydata
```

Of course you can do much more this way than just using `chown`. You can, for example, fetch some data from a remote site and/or process the data in any way you like.

**UPDATE:**

The smallest image (125 Bytes) which can be used with `docker run` is [tianon/true](https://hub.docker.com/r/tianon/true/). It just contains a binary named true which exits with 0:

```shell
docker run --rm tianon/true /true
```

see also: [tianon/true on Github](https://github.com/tianon/dockerfiles/tree/master/true)

This may become useful if you want to use "pure" data image, but your ochestration tool won't let you. 125 Bytes overhead seems perfect. But again: busybox also weights just 2.5 MB. If you use it in more than one images, it's shared among all of them. So the overhead is also minimal.
