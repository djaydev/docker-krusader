# Pull base build image.
FROM alpine:edge AS builder

# Add testing repo for ssh-askpass
RUN echo "http://dl-3.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
		echo "http://dl-3.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
		echo "http://dl-3.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories

# Install packages.
RUN apk --update --upgrade add \
		build-base cmake extra-cmake-modules qt5-qtbase-dev \
		wget git bash ki18n-dev kio-dev kbookmarks-dev kparts-dev \
		kwindowsystem-dev kiconthemes-dev kxmlgui-dev kdoctools-dev \
		xvfb-run kdesu-dev qt5-qtlocation-dev acl-dev

WORKDIR /tmp

# Download krusader, krename from KDE
RUN git clone git://anongit.kde.org/krename
RUN wget http://kde.mirrors.tds.net/pub/kde/stable/krusader/2.7.1/krusader-2.7.1.tar.xz
RUN tar -xvf krusader-2.7.1.tar.xz
RUN mkdir krusader-2.7.1/build
RUN mkdir krename/build

# Compile krusader
RUN cd krusader-2.7.1/build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_C_FLAGS="-O2 -fPIC" -DCMAKE_CXX_FLAGS="-O2 -fPIC" ..
RUN sed -i 's/#include <time.h>/#include <time.h>\n#include <sys\/types.h>/' /tmp/krusader-2.7.1/krusader/DiskUsage/filelightParts/fileTree.h
RUN sed -i 's/#include <time.h>/#include <time.h>\n#include <sys\/types.h>/' /tmp/krusader-2.7.1/krusader/FileSystem/krpermhandler.h
RUN sed -i 's/#include <pwd.h>/#include <pwd.h>\n#include <sys\/types.h>/' /tmp/krusader-2.7.1/krusader/FileSystem/krpermhandler.cpp
RUN cd krusader-2.7.1/build && make -j$(nproc) && make install

# Compile krename
RUN cd krename/build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_C_FLAGS="-O2 -fPIC" -DCMAKE_CXX_FLAGS="-O2 -fPIC" ..
RUN cd krename/build && make -j$(nproc) && make install

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.9

# Add testing repo for ssh-askpass, add community repo for some python packages
RUN echo "http://dl-3.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
		echo "http://dl-3.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
		echo "http://dl-3.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories

# Install packages.
RUN apk upgrade --update-cache --available && \
 		apk add \
		bash kate keditbookmarks konsole mesa-dri-swrast \
		p7zip unrar unzip findutils ntfs-3g \
		dbus-x11 breeze-icons adwaita-icon-theme \
		&& rm -rf /var/cache/apk/* /tmp/* /tmp/.[!.]*

ENV LANG=C.UTF-8

# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default.

RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.29-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

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
RUN chmod +x /startapp.sh

# Copy Krusader from base build image.
COPY --from=builder /usr/local /usr/

# Set the name of the application.
ENV APP_NAME="Krusader"
