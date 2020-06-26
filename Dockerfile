# Pull base build image.
FROM alpine:3.12 AS builder

# Install packages.
RUN apk add \
    build-base cmake extra-cmake-modules qt5-qtbase-dev xvfb-run\
    git bash ki18n-dev kio-dev kbookmarks-dev kparts-dev kdesu-dev \
    kwindowsystem-dev kiconthemes-dev kxmlgui-dev kdoctools-dev libc6-compat \
    kdeplasma-addons-dev plasma-desktop-dev qt5-qtlocation-dev acl-dev

WORKDIR /tmp

# Download krusader, krename from KDE
RUN git clone git://anongit.kde.org/krename
RUN git clone git://anongit.kde.org/krusader
RUN mkdir krusader/build
RUN mkdir krename/build

# Compile krusader
RUN cd krusader/build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_C_FLAGS="-O2 -fPIC" ..
RUN sed -i 's/#include <time.h>/#include <time.h>\n#include <sys\/types.h>/' /tmp/krusader/krusader/DiskUsage/filelightParts/fileTree.h
RUN sed -i 's/#include <time.h>/#include <time.h>\n#include <sys\/types.h>/' /tmp/krusader/krusader/FileSystem/krpermhandler.h
RUN sed -i 's/#include <pwd.h>/#include <pwd.h>\n#include <sys\/types.h>/' /tmp/krusader/krusader/FileSystem/krpermhandler.cpp
RUN cd krusader/build && make -j$(nproc) && make install

# Compile krename
RUN cd krename/build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_C_FLAGS="-O2 -fPIC" ..
RUN cd krename/build && make -j$(nproc) && make install

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.12

# Install packages.
RUN apk add \
    bash kate keditbookmarks konsole kompare \
    p7zip unrar zip xz findutils ntfs-3g libacl taglib \
    dbus-x11 breeze-icons exiv2 kjs diffutils libc6-compat && \
    # some breeze icon names differ
    ln -s /usr/share/icons/breeze/mimetypes/22/audio-x-mpeg.svg /usr/share/icons/breeze/mimetypes/22/audio-mpeg.svg && \
    ln -s /usr/share/icons/breeze/mimetypes/22/application-x-raw-disk-image.svg /usr/share/icons/breeze/mimetypes/22/application-raw-disk-image.svg && \
    ln -s /usr/share/icons/breeze/mimetypes/22/application-x-gzip.svg /usr/share/icons/breeze/mimetypes/22/application-gzip.svg && \
    ln -s /usr/share/icons/breeze/mimetypes/22/video-x-generic.svg /usr/share/icons/breeze/mimetypes/22/video-quicktime.svg && \
    ln -s /usr/share/icons/breeze/mimetypes/22/libreoffice-presentation.svg /usr/share/icons/breeze/mimetypes/22/application-vnd.openxmlformats-officedocument.presentationml.presentation.svg && \
    ln -s /usr/share/icons/breeze/mimetypes/22/application-x-zerosize.svg /usr/share/icons/breeze/mimetypes/22/inode-socket.svg && \
    rm -rf /var/cache/apk/* /tmp/* /tmp/.[!.]* /usr/share/icons/breeze-dark /usr/share/icons/breeze/breeze-icons.rcc

# Adjust the openbox config.
RUN \
    # Maximize only the main/initial window.
    sed-patch 's/<application type="normal">/<application type="normal" title="Krusader">/' \
      /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="Krusader">/a \    <layer>below</layer>' \
      /etc/xdg/openbox/rc.xml

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/binhex/docker-templates/master/binhex/images/krusader-icon.png && \
    install_app_icon.sh "$APP_ICON_URL" \
    && rm -rf /var/cache/apk/*

# Copy the start script.
COPY startapp.sh /startapp.sh

# Copy Krusader from base build image.
COPY --from=builder /usr/local /usr/
RUN ln -s /usr/lib64/plugins/* /usr/lib/qt5/plugins/

# Change web background color
RUN echo "sed-patch 's/<body>/<body><style>body { background-color: dimgrey; }<\/style>\n/' /opt/novnc/index.html" >> /etc/cont-init.d/10-web-index.sh

# Set the name of the application.
ENV APP_NAME="Krusader"
