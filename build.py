#!/usr/bin/env python3
import subprocess
import os
import os.path
import argparse
from threading import Thread, Lock
from sys import exit

DEBUG = False
LOGDIR = "logs"

PRINT_LOCK = Lock()

tag = "g0dscookie/postfix"

prefix = "g0dscookie"
service = "postfix"
tag = "{}/{}".format(prefix, service)

versions = {
    "3.3.0": {
        "latest": True,
    },
}

def check_version(version):
    if not version in versions:
        raise Exception("Unknown {} version {}".format(service, version))

def get_config(ver, cfg):
    check_version
    tmp = versions[ver][cfg]
    if type(tmp) is str:
        return get_config(tmp, cfg)
    elif type(tmp) is dict:
        return get_config(tmp["base"], cfg) + tmp["my"]
    else:
        return tmp

def build_tags(ver, latest):
    tags = []
    if latest:
        tags.extend(("-t", "{}:latest".format(tag)))
    tags.extend((
        "-t", "{}:{}".format(tag, ver[0]),
        "-t", "{}:{}.{}".format(tag, ver[0], ver[1]),
        "-t", "{}:{}.{}.{}".format(tag, ver[0], ver[1], ver[2]),
    ))
    return tags

def build_args(postfix_ver, makeopts="-j1", cflags="-O2"):
    return [
        "--build-arg", "MAJOR={}".format(postfix_ver[0]),
        "--build-arg", "MINOR={}".format(postfix_ver[1]),
        "--build-arg", "PATCH={}".format(postfix_ver[2]),
        "--build-arg", "MAKEOPTS={}".format(makeopts),
        "--build-arg", "CFLAGS={}".format(cflags),
    ]

def docker_build(ver):
    PRINT_LOCK.acquire()
    print("Building {}-{}...".format(tag, ver))

    makeopts = os.getenv("MAKEOPTS", "-j1")
    cflags = os.getenv("CFLAGS", "-O2")

    tags = build_tags(ver.split("."), versions[ver]["latest"])
    bargs = build_args(ver.split("."),
                            makeopts=makeopts,
                            cflags=cflags)

    if not os.path.isdir(LOGDIR):
        os.mkdir(LOGDIR)

    if DEBUG:
        print("MAKEOPTS:        {}".format(makeopts))
        print("CFLAGS:          {}".format(cflags))
        print("")
    PRINT_LOCK.release()

    stdout = open(os.path.join(LOGDIR, "{}-{}.log".format(service, ver)), mode="w")
    stderr = open(os.path.join(LOGDIR, "{}-{}.err".format(service, ver)), mode="w")
    subprocess.call(["docker", "build"] + tags + bargs + ["."], stdout=stdout, stderr=stderr)
    stdout.close()
    stderr.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="{} build script".format(tag))
    parser.add_argument("--version", default="all", type=str, help="Set the version to build (Defaults to %(default)s")
    parser.add_argument("-d", "--debug", action='store_true', help="Enable debug output.")
    parser.add_argument("-l", "--logdir", metavar="LOGDIR", default="logs", type=str, help="Set the log directory (Defaults to %(default)s")

    args = parser.parse_args()
    DEBUG = args.debug
    LOGDIR = args.logdir

    if args.version == "all":
        threads = []
        for ver in versions:
            t = Thread(target=docker_build, args=(ver,))
            t.start()
            threads.append(t)
        for t in threads:
            t.join()
    elif args.version == "latest":
        for ver in versions:
            if versions[ver]["latest"]:
                docker_build(ver)
                exit(0)
        raise Exception('No "latest" version specified!')
    else:
        docker_build(args.version)