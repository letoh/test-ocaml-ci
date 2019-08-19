#!/bin/bash -ex

OPAMVER=${OPAM_VERSION:-2.0.5}
OPAMBIN=${HOME}/bin/opam-${OPAMVER}

SWITCH=${OCAML_VERSION:-4.08.1}

# wget https://github.com/ocaml/opam/releases/download/1.2.2/opam-1.2.2-x86_64-Linux

install_syspkg () {
  sudo apt-get update -q
  sudo apt-get install -y bubblewrap libusb-1.0-0-dev
}

install_opam () {
    if [ "${TRAVIS}" = 'true' ]
    then
	ARCH=${TRAVIS_ARCH:-x86_64}
	[ "${ARCH}" = 'amd64' ] && ARCH=x86_64
	OS=${TRAVIS_OS_NAME:-linux}
    else
	ARCH=${ARCH:-x86_64}
	OS=${OS:-linux}
    fi

    OPAMURL=https://github.com/ocaml/opam/releases/download
    OPAMURL=${OPAMURL}/${OPAMVER}/opam-${OPAMVER}-${ARCH}-${OS}

    mkdir -p $(dirname ${OPAMBIN})
    [ -x "${OPAMBIN}" ] || \
    wget -O ${OPAMBIN} ${OPAMURL}
    chmod +x ${OPAMBIN}
}

config_opam () {
    export OPAMYES=1
    case "${OPAMVER}" in
	1.*)
	    export OPAMROOT=${HOME}/.opam-1
	    OPAMINITARGS=--compiler=${SWITCH}
	    ;;
	*)
	    export OPAMROOT=${HOME}/.opam-2
	    OPAMINITARGS=--bare
	    ;;
    esac
}

install_ocaml () {
    # check if ${OPAMROOT} is corrupted
    if ${OPAMBIN} config env >/dev/null
    then
	eval $(${OPAMBIN} config env)
	${OPAMBIN} config list
	${OPAMBIN} switch list
    else
	rm -rf ${OPAMROOT}
    fi

    ${OPAMBIN} init ${OPAMINITARGS} || (rm -rf ${OPAMROOT} && ${OPAMBIN} init ${OPAMINITARGS})
    ${OPAMBIN} switch install ${SWITCH} || \
	${OPAMBIN} switch set ${SWITCH}
    eval $(${OPAMBIN} config env)
    ${OPAMBIN} upgrade
}

perform_build () {
    ${OPAMBIN} install dune lwt lwt_ppx
    dune build --verbose
    make run
    make test
}

restore_packages () {
    [ -d "${HOME}/syspkg" ] || return 0
    # for debian family
    [ -d /var/cache/apt/archives ] || return 0
    cp -a ${HOME}/syspkg/*.deb /var/cache/apt/archives || true
}

cache_packages () {
    # for debian family
    [ -d /var/cache/apt/archives ] || return 0
    mkdir -p ${HOME}/syspkg
    ( cd /var/cache/apt/archives
      cp -a bubblewrap*.deb libusb*.deb ${HOME}/syspkg
    )
}

case "$1" in
    before_install) restore_packages ;;
    install)        install_syspkg; install_opam ;;
    before_script)  echo do dummy $1 ;;
    script)         config_opam; install_ocaml; perform_build ;;
    before_cache)   cache_packages ;;
    after_success)  echo do dummy $1 ;;
    after_failure)  echo do dummy $1 ;;
    before_deploy)  echo do dummy $1 ;;
    deploy)         echo do dummy $1 ;;
    after_deploy)   echo do dummy $1 ;;
    after_script)   echo do dummy $1 ;;
esac

