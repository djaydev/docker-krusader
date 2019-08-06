# docker-Krusader

Krusader is an advanced twin panel (commander style) file manager similar to Midnight or Total Commander.  It supports extensive archive handling, mounted filesystem support, advanced search, viewer/editor, directory synchronisation, file content comparisons, batch renaming, etc.

Project: <https://krusader.org/>

Base image used: jlesage/baseimage-gui:alpine-3.9

```docker run -d \
    --name=krusader \
    -p 5800:5800 \
    -p 5900:5900 \
    -v /docker/appdata/krusader:/config:rw \
    -v /home/user:/host/home:rw \
    -v /mnt/share1:/host/share1:rw \
    djaydev/krusader
```

Where:

- `/docker/appdata/krusader`: This is where the application stores its configuration, log and any files needing persistency.
- `Port 5800`: for WebGUI
- `Port 5900`: for VNC client connection
- `/home/user or /mnt/share1`: add directories you want Krusader to access.

Browse to <http://your-host-ip:5800> to access the Krusader GUI.

## Environment Variables

Some environment variables can be set to customize the behavior of the container and its application. The following list give more details about them available at <https://github.com/jlesage/docker-baseimage-gui#environment-variables>
