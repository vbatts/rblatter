# Rblatter

RBlatter is a ruby script which allows you to add and subtract TeXmf
subsets using the TeX Live TLPDB information. 

## Installation

This utility is likely run in place during packaging of TeX Live,
but can now be handle as a gem too.

To install as a gem, run:

  rake build

and the gem package should be in the ./pkg directory

## Usage

Ideally, you will have the tarballs of the texlive bits 
(texlive-20130530-texmf.tar.xz and texlive-20130530-extra.tar.xz)
and just run:

  ./mk_plist.sh

For usage of the rblatter command, read the mk_plist.sh and see the --help

