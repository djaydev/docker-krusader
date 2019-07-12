# docker-virt-manager
Virt-Manager docker container w/ WebGUI and VNC access

Virt-Manager latest version from github

Base image used: jlesage/baseimage-gui:alpine-3.9

```
docker run -d \
    --name=virt-manager \
    -p 5800:5800 \
    -p 5900:5900 \
    -v /docker/appdata/virt-manager:/config:rw \
    -v /dev/urandom:/dev/urandom:ro \
    djaydev/docker-virt-manager
```

Where:
- `/docker/appdata/virt-manager`: This is where the application stores its configuration, log and any files needing persistency.
- `Port 5900`: for VNC client connection
- `/dev/urandom`: not sure but didn't work on my server until added

Browse to http://your-host-ip:5800 to access the Virt-Manager GUI.

### Environment Variables
Some environment variables can be set to customize the behavior of the container and its application. The following list give more details about them available at https://github.com/jlesage/docker-baseimage-gui#environment-variables
