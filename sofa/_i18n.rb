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

	module REX
		COMMENT           = %r{^.*\#}
		MSGID             = %r{msgid\s*"(.*?[^\\])"}
		MSGSTR            = %r{msgstr\s*"(.*?[^\\])"}
		MSGSTR_PLURAL     = %r{msgstr\[(\d+)\]\s*"(.*?[^\\])"}
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
			case line
				when REX::COMMENT
					next
				when REX::MSGID
					msgid = $1
				when REX::MSGSTR_PLURAL
					msg[msgid] = [] unless msg[msgid].is_a? ::Array
					msg[msgid][$1.to_i] = $2
				when REX::MSGSTR
					msg[msgid] = $1
			end
		}
		msg
	end

	def self.merge_msg!(m)
		Thread.current[:msg] = self.msg.merge m
	end

	def _(msgid)
		Sofa::I18n.msg[msgid] || msgid
	end

	def n_(msgid,msgid_plural = nil,n = nil)
	end

end
