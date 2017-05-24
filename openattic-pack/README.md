# openattic-pack Docker image

This docker image will build openATTIC packages. 

Please choose which distro you want to use for building openATTIC packages.
Currently, only SUSE based distros is available.

## Usage instructions

### Image build

`docker build -t openattic-pack .`

### Running the openattic-pack container

* Clone the bitbucket openattic repo
`git clone https://bitbucket.org/openattic/openattic`

* Assuming openattic repo is located in `/home/oa/openattic`, run the following
command:
```
docker run -t -v /home/oa/openattic:/srv/openattic \
           --net=host --privileged \
	   --security-opt seccomp=unconfined \
           --tmpfs /run/lock  \
	   openattic-pack <distro_specific_parameters>
```

The container will create a tarball with all necessary files of openATTIC,
and then creates the packages based on the distro.
The packages will be places inside the openATTIC repo directory under
`build_packages` directory.


### SUSE based distros container paramenters

* The image openSUSE-Leap-42.2 requires the following parameters when running the container:

1. <OBS_API_URL>
1. <OBS_Project_Name>
1. <OBS_Package_Name>

* Example:

```
docker run -t -v /home/oa/openattic:/srv/openattic \
           --net=host --privileged \
           --security-opt seccomp=unconfined \
           --tmpfs /run/lock  \
           openattic-pack 'https://api.opensuse.org/' 'home:rjdias:branches:filesystems:openATTIC' openattic
```

### Caching packaging dependencies

The packaging process might take a long time because it may need to
download many dependencies for building the packages.
If this is the case, after you run the container for the first time,
you can generate new image based on that container, which will keep
all the dependencies.

To create the new image, run the following command:
```
docker commit <CONTAINER_ID> openattic-pack-cache
```

After creating the new image, you can use it in the same way as the
original image.
