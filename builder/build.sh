#!/bin/bash
set -e
set -x
set -u
name=bamboo
version=${_BAMBOO_VERSION:-"1.0.0"}
description="Bamboo is a DNS based HAProxy auto configuration and auto service discovery for Mesos Marathon."
url="https://github.com/QuBitProducts/bamboo"
arch="all"
section="misc"
license="Apache Software License 2.0"
package_version=${_BAMBOO_PKGVERSION:-"-1"}
origdir="$(pwd)"
workspace="builder"
pkgtype=${_PKGTYPE:-"rpm"}
builddir="build"
installdir="opt"
outputdir="output"
function cleanup() {
    cd ${origdir}/${workspace}
    rm -rf ${name}*.{deb,rpm}
    rm -rf ${builddir}
}

function bootstrap() {
    cd ${origdir}/${workspace}

    # configuration directory
    mkdir -p ${builddir}/${name}/${installdir}/bamboo

    pushd ${builddir}
}

function build() {

    # Prepare binary at /opt/bamboo/bamboo
    cp ${origdir}/bamboo ${name}/${installdir}/bamboo
    chmod 755 ${name}/${installdir}/bamboo

    # Link default confiugration
    mkdir -p ${name}/etc/bamboo
    cp -rp ${origdir}/config/* ${name}/etc/bamboo/.

    # Distribute UI webapp
    mkdir -p ${name}/${installdir}/bamboo/webapp
    cp -rp ${origdir}/webapp/dist ${name}/${installdir}/bamboo/webapp/dist
    cp -rp ${origdir}/webapp/fonts ${name}/${installdir}/bamboo/webapp/fonts
    cp ${origdir}/webapp/index.html ${name}/${installdir}/bamboo/webapp/index.html

    # Systemd
    mkdir -p ${name}/lib/systemd/system/
    cp ${origdir}/builder/bamboo-server.service ${name}/lib/systemd/system/

    # Versioning
    echo ${version} > ${name}/${installdir}/bamboo/VERSION
    pushd ${name}
}

function mkdeb() {
  # rubygem: fpm
  fpm -t ${pkgtype} \
    -n ${name} \
    -v ${version}${package_version} \
    --description "${description}" \
    --url="${url}" \
    -a ${arch} \
    --category ${section} \
    --vendor "Qubit" \
    --after-install ../../build.after-install \
    --after-remove  ../../build.after-remove \
    --before-remove ../../build.before-remove \
    -m "${USER}@${HOSTNAME}" \
    --license "${license}" \
    --prefix=/ \
    -s dir \
    -- .
  mkdir -p ${origdir}/${outputdir}
  mv ${name}*.${pkgtype} ${origdir}/${outputdir}/
  popd
}

function main() {
    cleanup
    bootstrap
    build
    mkdeb
}

main
