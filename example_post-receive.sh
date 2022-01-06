#!/bin/sh
# generic git post-receive hook.
# change the config options below and call this script in your post-receive
# hook or symlink it.
#
# NOTE, things to do manually (once) before running this script:
# - modify the categories in the for loop with your own.
#
# usage: sh example_post-receive.sh [reponame]
#
# if reponame is not set the basename of the current directory is used,
# this is the directory of the repo when called from the post-receive script.

# NOTE: needs to be set for correct locale (expects UTF-8) otherwise the
#       default is LC_CTYPE="POSIX".
export LC_CTYPE="en_US.UTF-8"

# paths must be absolute
reposdir="/srv/git"
webdir="/srv/git/html"
cachefile=".stagit-build-cache"

is_public_and_listed() {
    if [ ! -f "$1/git-daemon-export-ok" ] || [ ! -f "$1/category" ]; then
        return 1
    fi
    return 0
}

is_forced_update() {
    while read -r old new ref; do
        test "$old" = "0000000000000000000000000000000000000000" && continue
        test "$new" = "0000000000000000000000000000000000000000" && continue

        hasrevs="$(git rev-list "$old" "^$new" | sed 1q)"
        if test -n "$hasrevs"; then
            return 0
        fi
    done
    return 1
}

make_repo_web() {
    reponame="$(basename "$1" ".git")"
    printf "[%s] stagit HTML pages... " "$reponame"

    # if forced update, remove directory and cache file
    is_forced_update && printf "forced update... " && rm -rf "$webdir/$reponame"

    mkdir -p "$webdir/$reponame"
    cd "$webdir/$reponame" || return 1

    # make pages
    stagit -c "$cachefile" -u "https://git.oscarbenedito.com/$reponame/" "$1"

    # symlinks
    [ -f "about.html" ] \
        && ln -sf "about.html" "index.html" \
        || ln -sf "log.html" "index.html"
    ln -sfT "$1" ".git"

    echo "done"
}

make_stagit_index() {
    printf "Generating stagit index... "

    # generate index arguments
    args=""
    for category in "Projects" "Personal setup" "Miscellanea"; do
        args="$args -c \"$category\""
        for repo in "$reposdir/"*.git/; do
            repo="${repo%/}"
            is_public_and_listed "$repo" || continue
            [ "$(cat "$repo/category")" = "$category" ] && args="$args $repo"
        done
    done

    # make index
    echo "$args" | xargs stagit-index > "$webdir/index.html"

    echo "done"
}

if [ "$1" = "" ]; then
    repo="$(pwd)"
else
    repo="$reposdir/$1"
fi

cd "$repo" || exit 1
is_public_and_listed "$repo" || exit 0

make_repo_web "$repo"
make_stagit_index
