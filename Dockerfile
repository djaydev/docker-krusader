# Pull base build image.
FROM alpine:edge AS builder

# Add testing repo for KDE packages
RUN echo "http://dl-3.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "http://dl-3.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    echo "http://dl-3.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories

# Install packages.
RUN apk --update --upgrade add \
    build-base cmake extra-cmake-modules qt5-qtbase-dev xvfb-run\
    git bash ki18n-dev kio-dev kbookmarks-dev kparts-dev kdesu-dev \
    kwindowsystem-dev kiconthemes-dev kxmlgui-dev kdoctools-dev libc6-compat \
    kdeplasma-addons-dev plasma-desktop-dev qt5-qtlocation-dev acl-dev

WORKDIR /tmp

# Download krusader, krename, kompare from KDE
RUN git clone git://anongit.kde.org/krename
RUN git clone git://anongit.kde.org/libkomparediff2
RUN git clone git://anongit.kde.org/kompare
RUN git clone git://anongit.kde.org/krusader
RUN mkdir krusader/build
RUN mkdir krename/build
RUN mkdir libkomparediff2/build
RUN mkdir kompare/build

# Compile krusader
RUN cd krusader/build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_C_FLAGS="-O2 -fPIC" -DCMAKE_CXX_FLAGS="-O2 -fPIC" ..
RUN sed -i 's/#include <time.h>/#include <time.h>\n#include <sys\/types.h>/' /tmp/krusader/krusader/DiskUsage/filelightParts/fileTree.h
RUN sed -i 's/#include <time.h>/#include <time.h>\n#include <sys\/types.h>/' /tmp/krusader/krusader/FileSystem/krpermhandler.h
RUN sed -i 's/#include <pwd.h>/#include <pwd.h>\n#include <sys\/types.h>/' /tmp/krusader/krusader/FileSystem/krpermhandler.cpp
RUN cd krusader/build && make -j$(nproc) && make install

# Compile krename
RUN cd krename/build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_C_FLAGS="-O2 -fPIC" -DCMAKE_CXX_FLAGS="-O2 -fPIC" ..
RUN cd krename/build && make -j$(nproc) && make install

# Compile kompare and it's dependency libkomparediff2
RUN cd libkomparediff2/build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_C_FLAGS="-O2 -fPIC" -DCMAKE_CXX_FLAGS="-O2 -fPIC" ..
RUN cd libkomparediff2/build && make -j$(nproc) && make install
RUN cd kompare/build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_C_FLAGS="-O2 -fPIC" -DCMAKE_CXX_FLAGS="-O2 -fPIC" ..
RUN cd kompare/build && make -j$(nproc) && make install

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.9

# Add testing repo for edge upgrade
RUN echo "http://dl-3.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "http://dl-3.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    echo "http://dl-3.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories

# Install packages.
RUN apk upgrade --update-cache --available && \
    apk add \
    bash kate keditbookmarks konsole mesa-dri-swrast xz \
    p7zip unrar zip unzip findutils ntfs-3g libacl taglib \
    dbus-x11 breeze-icons exiv2 kjs diffutils libc6-compat && \
    apk upgrade --update-cache --available && \
    rm -rf /var/cache/apk/* /tmp/* /tmp/.[!.]* /usr/share/icons/breeze-dark

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
COPY --from=builder /usr/local /usr/local
RUN ln -s /usr/local/lib64/* /usr/lib && ln -s /usr/local/lib64/plugins/kf5/parts/* /usr/lib/qt5/plugins/kf5/parts/

# Change web background color
RUN echo "sed-patch 's/<body>/<body><style>body { background-color: dimgrey; }<\/style>\n/' /opt/novnc/index.html" >> /etc/cont-init.d/10-web-index.sh

# Set the name of the application.
ENV APP_NAME="Krusader"
