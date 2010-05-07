# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Sofa::I18n

	class Msg < String
		def %(*args)
			if args.first.is_a? ::Hash
				'boo'
			else
				super
			end
		end
	end

	def self.lang
		Thread.current[:lang] || []
	end

	def self.lang=(http_accept_language)
		Thread.current[:msg] = nil
		tokens = http_accept_language.split(/,/)
		Thread.current[:lang] = tokens.sort_by {|t| # rfc3282
			[
				(t =~ /q=([\d\.]+)/) ? $1.to_f : 1.0,
				-tokens.index(t)
			]
		}.reverse.collect {|i|
			range = i[/[a-z]{1,8}(-[a-z]{1,8})?/i] # rfc2616
			range ? range.downcase : nil
		}
	end

	def self.po_dir
		Thread.current[:po_dir] ||= './locale'
	end

	def self.po_dir=(po_dir)
		Thread.current[:po_dir] = po_dir
	end

	def self.msg
		@@msg ||= {}
		@@msg[self.lang] ||= self.find_msg
		Thread.current[:msg] ||= @@msg[self.lang]
	end

	def self.find_msg(lang = self.lang)
		lang.each {|range|
			[
				range,
				range.sub(/-.*/,''),
			].uniq.each {|r|
				po_file = ::File.join(self.po_dir,r,'index.po')
				return open(po_file) {|f| self.parse_msg f } if ::File.readable? po_file
			}
		}
		{}
	end

	def self.parse_msg(f)
		msg   = {}
		msgid = nil
		f.each_line {|line|
			if line =~ /^.*\#/
				next
			elsif line =~ %r{msgid\s*"(.*?[^\\])"}
				msgid = $1
			elsif line =~ %r{msgstr\[(\d+)\]\s*"(.*?[^\\])"}
				msg[msgid] = [] unless msg[msgid].is_a? ::Array
				msg[msgid][$1.to_i] = $2
			elsif line =~ %r{msgstr\s*"(.*?[^\\])"}
				msg[msgid] = $1
			end
		}
		msg
	end

	def _(msgid)
		if msg = Sofa::I18n.msg
			msg[msgid] || msgid
		else
			msgid
		end
	end

	def n_(msgid,msgid_plural = nil,n = nil)
	end

end
