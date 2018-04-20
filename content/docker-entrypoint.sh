#!/usr/bin/env bash

set -Eeuo pipefail

FILES=(
    "dynamicmaps.cf"
    "main.cf.default"
    "main.cf.proto"
    "makedefs.out"
    "master.cf.proto"
    "postfix-files"
)
DIRS=(
    "dynamicmaps.cf.d"
    "postfix-files.d"
)

function _cp() {
    local src="$1" dst="$2"
    mv "${dst}" "${dst}.bak-$(date +"%Y-%m-%d-%H-%M-%S")"
    cp -Rf "${src}" "${dst}"
}

function copy_file() {
    local file="$1" srcprefix="${2:-}" dstprefix="${3:-}"
    if [[ -e "${dstprefix}${file}" ]]; then
        if ! diff "${dstprefix}${file}" "${srcprefix}${file}" >/dev/null; then
            _cp "${srcprefix}${file}" "${dstprefix}${file}"
        fi
    else
        cp "${srcprefix}${file}" "${dstprefix}${file}"
    fi
}

function copy_dir() {
    local dir="$1" srcprefix="${2:-}" dstprefix="${3:-}"
    if [[ -d "${dstprefix}${dir}" ]]; then
        [[ -d "${dstprefix}${dir}" ]] && echo "${dstprefix}${dir} exists"
        if ! diff -r "${dstprefix}${dir}" "${srcprefix}${dir}" >/dev/null; then
            _cp "${srcprefix}${dir}" "${dstprefix}${dir}"
        else
            local file
            for file in ${srcprefix}${dir}/*; do
                [[ "${file}" == "${srcprefix}${dir}/*" ]] && break
                if [[ -d "${file}" ]]; then
                    copy_dir "${file/${srcprefix//\//\\/}/}" "${srcprefix}" "${dstprefix}"
                else
                    copy_file "${file/${srcprefix//\//\\/}/}" "${srcprefix}" "${dstprefix}"
                fi
            done
            unset file
        fi
    else
        cp -R "${srcprefix}${dir}" "${dstprefix}${dir}"
    fi
}

if [[ "${INIT_CONF:-false}" == "true" ]]; then
    for f in ${FILES[@]}; do
        copy_file "${f}" "/conf.def/" "/conf/"
    done

    for d in ${DIRS[@]}; do
        copy_dir "${d}" "/conf.def/" "/conf/"
    done
fi

exec $@