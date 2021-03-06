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
# $Id: plistdeduper.rb,v 1.3 2012/12/17 20:28:04 edd Exp $
#
# De-duplicate Packing Lists

require "set"

class PListDeduper

	def initialize(file, options)
    @options = options || {}

		puts "removing duplicates from #{file}" unless @options[:quiet]

		File.rename file, "#{file}.dups" 

		@readHandle = File.open "#{file}.dups" 
		@writeHandle = File.open file, "w+" 

		@list = Set.new

		dedupe

		@readHandle.close
		@writeHandle.close
	end

	private
	def dedupe()

		for line in @readHandle  do
			@list << line
		end

		for line in @list  do
			@writeHandle.write line 
		end

	end
end
