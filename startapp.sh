#!/bin/sh
export HOME=/config
exec dbus-launch dbus-run-session -- krusader &
sed -i 's/<body>/<body><style>body { background-color: dimgrey; }<\/style>\n/' /opt/novnc/index.html
