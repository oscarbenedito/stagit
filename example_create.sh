#!/bin/sh
# - Makes index for repositories in a single directory.
# - Makes static pages for each repository directory.
#
# NOTE, things to do manually (once) before running this script:
# - copy style.css, logo.svg and favicon.ico to $assetdir.
# - modify the at the start of the script with your own.
# - modify the categories in the for loop with your own.
#
# - write clone URL, for example "git://git.codemadness.org/dir" to the "url"
#   file for each repo.
# - write owner of repo to the "owner" file.
# - write description in "description" file.
# - write category in "category" file, if there is no category, the repository
#   will be unlisted on stagit.
#
# Usage:
# - sh example_create.sh

# paths must be absolute
reposdir="/srv/git"
webdir="/srv/git/html"
cachefile=".stagit-build-cache"
assetdir="/usr/local/share/doc/stagit"

is_public_and_listed() {
    if [ ! -f "$1/git-daemon-export-ok" ] || [ ! -f "$1/category" ]; then
        return 1
    fi
    return 0
}

make_repo_web() {
    reponame="$(basename "$1" ".git")"
    printf "[%s] stagit HTML pages... " "$reponame"

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

# clean webdir
rm -rf "$webdir"
mkdir -p "$webdir" || exit 1

# set assets if not already there
ln -s "$assetdir/style.css" "$webdir/style.css" 2> /dev/null
ln -s "$assetdir/logo.svg" "$webdir/logo.svg" 2> /dev/null
ln -s "$assetdir/favicon.ico" "$webdir/favicon.ico" 2> /dev/null

# make files per repo
for repo in "$reposdir/"*.git/; do
    repo="${repo%/}"
    is_public_and_listed "$repo" || continue

    make_repo_web "$repo"
done

make_stagit_index
