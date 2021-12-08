stagit
======

Personal fork of static git page generator. It generates static HTML pages for a
git repository.

This fork uses [md4c](https://github.com/mity/md4c) to convert the README
markdown into HTML and then shows it in an about page for each repository, this
adds a new dependency. On top of that, the assets have been changed, creating a
personal theme. The scripts have also been changed to fit my needs.


Usage
-----

Make files per repository:

	$ mkdir -p htmlroot/htmlrepo1 && cd htmlroot/htmlrepo1
	$ stagit path/to/gitrepo1
	repeat for other repositories
	$ ...

Make index file for repositories:

	$ cd htmlroot
	$ stagit-index path/to/gitrepo1 \
	               path/to/gitrepo2 \
	               path/to/gitrepo3 > index.html


Build and install
-----------------

	$ make
	# make install


Dependencies
------------

- C compiler (C99).
- libc (tested with OpenBSD, FreeBSD, NetBSD, Linux: glibc and musl).
- libgit2 (v0.22+).
- POSIX make (optional).
- [md4c](https://github.com/mity/md4c) (v0.4.4+).


Documentation
-------------

See man pages: stagit(1) and stagit-index(1).


Building a static binary
------------------------

It may be useful to build static binaries, for example to run in a chroot.

It can be done like this at the time of writing (v0.24):

	cd libgit2-src

	# change the options in the CMake file: CMakeLists.txt
	BUILD_SHARED_LIBS to OFF (static)
	CURL to OFF              (not needed)
	USE_SSH OFF              (not needed)
	THREADSAFE OFF           (not needed)
	USE_OPENSSL OFF          (not needed, use builtin)

	mkdir -p build && cd build
	cmake ../
	make
	make install


Extract owner field from git config
-----------------------------------

A way to extract the gitweb owner for example in the format:

	[gitweb]
		owner = Name here

Script:

	#!/bin/sh
	awk '/^[ 	]*owner[ 	]=/ {
		sub(/^[^=]*=[ 	]*/, "");
		print $0;
	}'


Set clone URL for a directory of repos
--------------------------------------

	#!/bin/sh
	cd "$dir"
	for i in *; do
		test -d "$i" && echo "git://git.codemadness.org/$i" > "$i/url"
	done


Update files on git push
------------------------

Using a post-receive hook the static files can be automatically updated. Keep in
mind git push -f can change the history and the commits may need to be
recreated. This is because stagit checks if a commit file already exists. It
also has a cache (-c) option which can conflict with the new history. See
stagit(1).

git post-receive hook (repo/.git/hooks/post-receive):

	#!/bin/sh
	# detect git push -f
	force=0
	while read -r old new ref; do
		hasrevs=$(git rev-list "$old" "^$new" | sed 1q)
		if test -n "$hasrevs"; then
			force=1
			break
		fi
	done

	# remove commits and .cache on git push -f
	#if test "$force" = "1"; then
	# ...
	#fi

	# see example_create.sh for normal creation of the files.


Create .tar.gz archives by tag
------------------------------

	#!/bin/sh
	name="stagit"
	mkdir -p archives
	git tag -l | while read -r t; do
		f="archives/${name}-$(echo "${t}" | tr '/' '_').tar.gz"
		test -f "${f}" && continue
		git archive \
			--format tar.gz \
			--prefix "${t}/" \
			-o "${f}" \
			-- \
			"${t}"
	done


Features
--------

- Log of all commits from HEAD.
- Log and diffstat per commit.
- Show file tree with linkable line numbers.
- Show references: local branches and tags.
- Detect README and LICENSE file from HEAD and link it as a webpage.
- Detect submodules (.gitmodules file) from HEAD and link it as a webpage.
- Atom feed of the commit log (atom.xml).
- Atom feed of the tags/refs (tags.xml).
- Make index page for multiple repositories with stagit-index.
- After generating the pages (relatively slow) serving the files is very fast,
  simple and requires little resources (because the content is static), only a
  HTTP file server is required.
- Usable with text-browsers such as dillo, links, lynx and w3m.


Cons
----

- Not suitable for large repositories (2000+ commits), because diffstats are
  an expensive operation, the cache (-c flag) is a workaround for this in some
  cases.
- Not suitable for large repositories with many files, because all files are
  written for each execution of stagit. This is because stagit shows the lines
  of textfiles and there is no "cache" for file metadata (this would add more
  complexity to the code).
- Not suitable for repositories with many branches, a quite linear history is
  assumed (from HEAD).

  In these cases it is better to just use cgit or possibly change stagit to run
  as a CGI program.

- Relatively slow to run the first time (about 3 seconds for sbase, 1500+
  commits), incremental updates are faster.
- Does not support some of the dynamic features cgit has (this is by design,
  just use git locally), like:
  - Snapshot tarballs per commit.
  - File tree per commit.
  - History log of branches diverged from HEAD.
  - Stats (git shortlog -s).
