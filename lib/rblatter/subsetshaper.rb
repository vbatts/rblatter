#!/usr/bin/env ruby
# Copyright (c) 2008-2012, Edd Barrett <vext01@gmail.com>
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 
# RBlatter
# $Id: subsetshaper.rb,v 1.3 2012/12/17 20:28:04 edd Exp $
#
# Adds and subtracts texmf subset file lists in order to make new subsets.

require "rblatter/subsetconf"
require "rblatter/tlpdbindex"
require "rblatter/plistdeduper"
require "rblatter/spinner"
require "set"
require "rblatter/pkgscanner"
require "rblatter/pkgfilter"
require "date"

class SubsetShaper
  DEFAULT_TMPOUT = "tmp"

	# Create a new subset shaper and index the tlpdb database
	def initialize(options = nil)
		@options = options || {}
		@subsetConfigs = []
		@pkgFilter = PkgFilter.new @options
		@pkgScanner = PkgScanner.new @options
		@pass = 1
		@spinner = Spinner.new @options

		@includeFiles = Set.new
		@excludeFiles = Set.new
		@finalFiles = Set.new

		@includeMaps = Set.new
		@excludeMaps = Set.new
		@finalMaps = Set.new

		@includeFormats = Set.new
		@excludeFormats = Set.new
		@finalFormats = Set.new

		@dirList = Set.new	# need to add dirs in plist
		@subsetConfigs = []
		@again = true # Will need another pass?
		eqns = EqnParser.new @options[:eqn]
		eqns.configs.each do |eqn|
			@subsetConfigs << eqn
		end

    @tmpout = @options[:tmpout] || DEFAULT_TMPOUT
    @outdir = @options[:outdir]

		if File.exists? @tmpout then
			puts "*error: '#{@tmpout}' exists"
			puts "It can probably be deleted"
			exit 1
		end

		Dir.mkdir @tmpout

		run
	end

	private
	# Start parsing and expanding subsets
	def run
		if File.exists? @outdir then
			$stderr.puts "*error: #{@outdir} exists"
			$stderr.puts "Remove/move, just do something!"
			exit 1
		end

		writeInitialContents
		expandContents
		performEquation

		Dir.mkdir @outdir
		writePlist
		writeHints
		clean
	end

	# Create and populate subset outputs with toplevel depends
	def writeInitialContents 

		puts "setting up subsets..." unless @options[:quiet]

		@subsetConfigs.each do |subset|

			# Create file
			outFile = "#{@tmpout}/" + subset.uniq.to_s + "-" +
				subset.subsetName + "_1"
			if File.exists? outFile then
				File.delete outFile
			end

			# Do initial population
			outHandle = File.new outFile, "w+"
			contents = @pkgScanner.getContents subset.subsetName
			contents = 
				@pkgFilter.filterContents contents, subset
			outHandle.write contents
			outHandle.close
		end
	end

	# Expand dependencies in a subset output file
	def expandContents

		puts "expanding subsets..." unless @options[:quiet]

		@subsetConfigs.each do |subset|

			name = subset.subsetName
			puts "expanding #{name}" unless @options[:quiet]
			@pass = 1

			@again = true 
			while @again == true 

				@again = false

				print "pass #{@pass}: \n" unless @options[:quiet]

				@spinner.rewind

				# Open files
				inHandle = File.new(
					"#{@tmpout}/" + subset.uniq.to_s + 
					"-" + name + "_#{@pass}", "r")

				outHandle = File.new(
					"#{@tmpout}/" + subset.uniq.to_s +
					 "-" + name + "_#{@pass.next}",
					 "w+")

				inHandle.each do |line|
					expLine = expandLine line, subset
					outHandle.write expLine
				end

				@pass = @pass.next
				inHandle.close
				outHandle.close

				print "\b" unless @options[:quiet]

				PListDeduper.new("#{@tmpout}/" + 
					subset.uniq.to_s +
					"-" + name + "_#{@pass}", @options)
			end #while

			puts "#{@pass} passes" unless @options[:quiet]

			File.rename("#{@tmpout}/#{subset.uniq.to_s}" +
				    "-#{name}_#{@pass}",
				"#{@tmpout}/#{subset.uniq.to_s}-" +
				"#{name}_final")

		end #.each
	end

	# Calculate the final packing list
	def performEquation
		puts "performing equation..." unless @options[:quiet]

		@spinner.freq = 4
		@spinner.rewind

		for conf in @subsetConfigs do
			handle = File.new "#{@tmpout}/" + conf.uniq.to_s +
			 "-" + conf.subsetName + "_final", "r"

			inc = conf.inclusive

			if inc then
				@includeMaps.merge conf.mapHints
				@includeFormats.merge conf.formatHints
			else
				@excludeMaps.merge conf.mapHints
				@excludeFormats.merge conf.formatHints
			end

			handle.each do |line|
				if inc then
					@includeFiles << line
				else
					@excludeFiles << line
				end
				@spinner.spin	
			end

			handle.close
		end

		print "\b" unless @options[:quiet]

		@finalFiles = @includeFiles.subtract @excludeFiles
		@finalMaps = @includeMaps.subtract @excludeMaps
		@finalFormats = @includeFormats.subtract @excludeFormats

		unless @options[:quiet] then
			puts "includeFiles = #{@includeFiles.size}"
			puts "excludeFiles = #{@excludeFiles.size}"
			puts "includeMaps = #{@includeMaps.size}"
			puts "--"
			puts "excludeMaps = #{@excludeMaps.size}"
			puts "includeFormats = #{@includeFormats.size}"
			puts "excludeFormats = #{@excludeFormats.size}"
			puts "=="
			puts "final = #{@finalFiles.size}"
			puts "finalMaps = #{@finalMaps.size}"
			puts "finalFormats = #{@finalFormats.size}"
		end

	end

	# add directories and their parent directories
	def addDir(basefile)
		dir = File.dirname(basefile)

		# recurse - add parent dirs also
		if (dir != ".") then
			@dirList << dir
			addDir(dir)
		end
	end

	# Write packing list to the output directory
	def writePlist
		File.open("#{@outdir}/PLIST", "w") do |plist|
			@finalFiles.each do |line|
				line = line.chomp

				ok = true
				if @options[:missing_files] == false then
					filetlm = @options[:tlmaster] + "/" + line
					if (File.exist?(filetlm.chomp) == false)  then
						ok = false
						puts "*warning: missing file ignored: " + filetlm
					end
				end

				if ok then
          # the .to_s is for in case the variable is nil
					plist.write @options[:fileprefix].to_s + line + "\n"
					if @options[:add_dirs] then
						addDir(line)
					end
				end
			end

			# add directory entries to satisfy openbsd pkgtools
			if @options[:add_dirs] then
				@dirList.each do |file|
          # the .to_s is for in case the variable is nil
					plist.write @options[:fileprefix].to_s + file + "/\n"
				end
			end
		end
	end

	# Write the HINTS file to the output directory
	def writeHints()
		time = Time.now.to_s
		hdr = "=" * 72
		shdr = "-" * 10

		File.open("#{@outdir}/HINTS", "w") do |hints|
			hints.puts "Rblatter-#{$RBLATTER_V}"
			hints.puts time
			hints.puts @options[:eqn]
			hints.puts hdr
			hints.puts ""

			hints.puts "SUMMARY"
			hints.puts shdr
			hints.puts ""
			hints.puts "includeFiles = #{@includeFiles.size}"
			hints.puts "excludeFiles = #{@excludeFiles.size}"
			hints.puts "includeMaps = #{@includeMaps.size}"
			hints.puts ""

			hints.puts "excludeMaps = #{@excludeMaps.size}"
			hints.puts "includeFormats = " + 
				"#{@includeFormats.size}"
			hints.puts "excludeFormats = " +
				"#{@excludeFormats.size}"
			hints.puts ""

			hints.puts "final = #{@finalFiles.size}"
			hints.puts "finalMaps = #{@finalMaps.size}"
			hints.puts "finalFormats = #{@finalFormats.size}"
			hints.puts ""

			hints.puts "MAP HINTS"
			hints.puts shdr
			hints.puts ""
			
			@finalMaps.each {|map| hints.puts map }

			if @finalMaps.size == 0 then
				hints.puts "(No map hints)"
			end

			hints.puts ""
			hints.puts "FORMAT HINTS"
			hints.puts shdr
			hints.puts ""

			@finalFormats.each {|fmt| hints.puts fmt }

			if @finalFormats.size == 0 then
				hints.puts "(No format hints)"
			end

		end
	end

	# Clean up the temp directory
	def clean()
		tmpdir = Dir.open(@tmpout) do |dir|
			dir.each do |file|
				if file != "." and file != ".." then
					File.unlink(@tmpout + "/" + file)
				end
			end
		end

		Dir.rmdir @tmpout
	end

	# Expand a depend line
	def expandLine(line, subset)
		# If a depend expand
		buf = ""
		if line =~ /^depend (.*)/ then

			if(subset.alreadyExpanded? $1) == false then
				buf = @pkgScanner.getContents $1
				buf = @pkgFilter.filterContents buf, subset
				@spinner.spin	

				# Will need another pass
				@again = true
				subset.flagExpanded $1
			end
		else
			buf = line
		end

		buf
	end
end
