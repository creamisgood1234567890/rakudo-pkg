#!/bin/sh -e
set -xv

. config/versions.sh
export ARCH MAINTAINER RAKUDO_VERSION PKG_REVISION

# Install nfpm
tar xzf nfpm.tar.gz nfpm
mv nfpm /usr/bin

# Fill the config
envsubst < config/nfpm.yaml > config/nfpm.yaml_tmp
mv config/nfpm.yaml_tmp config/nfpm.yaml

# Package
case "$OS" in
    alpine)
        PACKAGER=apk
        INSTALL_CMD='apk add --no-cache --allow-untrusted *.apk'
        ;;
    centos)
        PACKAGER=rpm
        INSTALL_CMD='rpm -Uvh *.rpm'
        ;;
    debian)
        PACKAGER=deb
        INSTALL_CMD='dpkg -i *.deb'
        ;;
    fedora)
        PACKAGER=rpm
        INSTALL_CMD='rpm -Uvh *.rpm'
        ;;
    opensuse)
        PACKAGER=rpm
        INSTALL_CMD='rpm -Uvh *.rpm'
        ;;
    rhel)
        PACKAGER=rpm
        INSTALL_CMD='rpm -Uvh *.rpm'
        ;;
    ubuntu)
        PACKAGER=deb
        INSTALL_CMD='dpkg -i *.deb'
        ;;
    *)
        echo "Sorry, distro not found. Send a PR. :)"
        exit 1
        ;;
esac

mkdir /staging
nfpm pkg -f config/nfpm.yaml --packager $PACKAGER --target /staging/
cd /staging
PKG=`ls -1 *.$PACKAGER`
sha512sum $PKG > $PKG.sha512sum
echo "Packarghe sha512sum:"
cat $PKG.sha512sum

# Test the package
rm -rf /opt/rakudo-pkg
$INSTALL_CMD
. /etc/profile.d/rakudo-pkg.sh
raku -v
zef --version

# Move to workspace
mkdir -p $GITHUB_WORKSPACE/packages
mv /staging/* $GITHUB_WORKSPACE/packages/