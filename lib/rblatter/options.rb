
require "optparse"

USAGE = <<-EOM
Copyright (c) 2008-2010, Edd Barrett <vext01@gmail.com>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

RBlatter
$Id: rblatter,v 1.2 2011/03/08 00:09:42 edd Exp $

== Synopsis
RBlatter is a ruby script which allows you to add and subtract TeXmf
subsets using the TeX Live TLPDB information. 

== Usage
rblatter [-h] [-v] -o dir -t texliverootdir eqn

EQN: subset equation
	eg. +scheme-full,doc,run,src:+scheme-medium,run:-scheme-tetex,bin
  	Means:
		take scheme-full's docfiles, runfiles and srcfiles.
	add to this scheme-medium's runfiles.
	subtract from these scheme-tetex's binfiles

Available file types are 'run', 'src', 'bin' and 'doc'.
EOM

def parse_args(args)
  options = {
      :arch           => "x86_64",
      :missing_files  => true,
      :add_dirs       => false,
      :quiet          => true,
  }
  opts = OptionParser.new do |opts|
    opts.banner = USAGE
    opts.on("--arch ARCH","-a","Specify the architecture to use for platform" +
            "specific files. Should specify always. " +
            "Defaults to [#{options[:arch]}]") do |o|
      options[:arch] = o
    end
    opts.on("--dirs","-d","add directories to conatin files to packing list." +
            " used for openbsd packing lists ") do |o|
      options[:add_dirs] = true
    end
    opts.on("--no-missing-files","-n","do not put missing files in PLIST" +
            "(requires full texmf)") do |o|
      options[:missing_files] = false
    end
    opts.on("--outdir OUTDIR","-o","output directory") do |o|
      options[:outdir] = o
    end
    opts.on("--prefix PREFIX","-p") do |o|
      options[:fileprefix] = o
    end
    opts.on("--tlmaster TLMASTER","-t","root of texlive directory") do |o|
      options[:tlmaster] = o
    end
    opts.on("--verbose", "-v","do not show progress information.") do |o|
      options[:quiet] = false
    end
  end

  # destructively parse the args
  opts.parse!(args)

  # Yoink equation as whats left of command line
  options[:eqn] = args.shift

  # Checks
  abort("*error: no --tlmaster | -t defined\n#{opts}") unless defined?(options[:tlmaster])
  abort("*error: no --outdir | -o  defined\n#{opts}") unless defined?(options[:outdir])
  abort("*error: no subset equation specified.\n#{opts}") if options[:eqn].nil?

  return options
end
