simplestream server
===================

This project is a derivitive work from two related projects:
   https://github.com/Avature/lxd-image-server
    and
   https://github.com/cr1st1p/docker-simplestreams-server

The lxd-image-server tool creates json files to satisfiy the simplestream server
format.  Ngnix server creates the web site that serves up the changes.  finally upload-server allows users to upload images to the container server.

The latter, docker-simplestreams-server contained some python code to upload files, and a docker container builder.  Since this is an LxD/LxC ecosystem, this project converts the docker container to an LxD container.

The full solution allows for the creation of an LXC container that runs all the code needed, and provides a local simplestream LXD/incus server that can store
images for local distrobution, or public distrobution

QUICKSTART
==========

this repo provides a script that generates the LXC container that supports the simplestream server.  The user is expected to have setup and installed lxd and will host this container.

    - clone this repo
    - cd to the repo dir

    $ ./createContainer.sh

this will create a container called "simplestream" that will host the entire solution:

   - ngnix - provides web server
   - lxd-simple-server - creates simplestream format web files
   - upload-server - provides image management functions


Once the container is running,  the server needs to be exported to the host.  Since this is a "personal" preference, it is not performed in createContainer.sh

   {host}$ lxc config device add simplestream www-server proxy connect="tcp:127.0.0.1:8443" listen="tcp:0.0.0.0:8443"

This will map {host}:8443 to the simplestream server.  And allow the client(s) to configure the server to retrieve images.  It is *NOT* meant to allow the clients to upload files.  Instead a "trusted" process can upload files using the upload-server that is not exported (discussed below)

    {client system}$ lxc remote add private {host}:8443 --protocol=simplestream

This will add the private: store and allow the user to enumerate/use images from this server

    {client system}$ lxc image list private:


UPLOADING Images
================

This service is not meant to replace the LXD server that is built into LXD.  Therefore, there are two mechanisms for uploading images to the server:

Method 1 - Use LxD administrator facility
-----------------------------------------
TBD - connect a "supervisor" client to the LxD server directly (not simplestream), and use `lxc image copy` to transfer files to the server.

Method 2 - Use internal (ssh-proxied) web page to update the server
-------------------------------------------------------------------

using this method, the ssh server on the container is exposed to the outside world.  This allows authorized ssh users to connect to the server and update images with curl.  This is basically what is suggested and implemented in the docker-simplestream-server project, however there are some things in this
project to make it simpler.

TBD - instructions on how to upload
