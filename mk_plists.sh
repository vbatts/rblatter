#!/bin/sh
#
# Thanks to OpenBSD for this (slightly modified) script
#
# This is how the texlive packing lists were generated.
# Please be aware that a *full* texmf/texmf-dist and texlive.tlpdb from the
# texlive svn are required.
#
# texlive.tlpdb does not come in the dist tarball, so you need to get
# it from svn from the release date. Eg:
# svn co -r {20130530} svn://tug.org/texlive/trunk/Master/tlpkg
# You can then copy tlpkg/texlive.tlpdb to ${TARBALL_ROOT}/tlpkg/texlive.tlpdb

VERSION=20130530

if [ "$1" = "" ]; then
	TMF="$(pwd)/texlive-$VERSION-texmf";
else
	TMF=$1
fi

rm -rf sets
mkdir -p sets

#rm -rf $TMF
#tar xf texlive-$VERSION-texmf.tar.xz
#tar xf texlive-$VERSION-extra.tar.xz

#mv texlive-$VERSION-extra/* $TMF && rmdir texlive-$VERSION-extra
cp $(pwd)/texlive.tlpdb $TMF/tlpkg

echo "\nCalculating PLIST of texlive_texmf-minimal (tetex)..."
./rblatter -d -v -n -t ${TMF} -p share/ -o sets/tetex +scheme-tetex,run
cat sets/tetex/PLIST | sort > sets/tetex/PLIST_final

echo "\nCalculating PLIST of texlive_texmf-full..."
./rblatter -d -v -n -t ${TMF} -p share/ -o sets/full \
	+scheme-full,run:-scheme-tetex,doc,src,run
cat sets/full/PLIST | sort > sets/full/PLIST_final

echo "\nCalculating PLIST of texlive_texmf-docs..."
./rblatter -d -v -n -t ${TMF} -p share/ -o sets/docs +scheme-full,doc
cat sets/docs/PLIST | sort > sets/docs/PLIST_final

echo "\ndone - PLISTS in sets/"
echo "now inspect:"
echo "  - $TMF/texmf-dist/scripts/texlive/* probably un-needed"
echo "  - *.exe obviously a waste of space"
echo "  - search for 'win32' and 'w32' and 'windows'"
echo "  - comment out manual pages and include in _base"
echo "  - bibarts is a DOS program"
echo "  - not all texworks related stuff is needed"
echo "  - move the manuals in the right place"
echo "  - etcetera..."
