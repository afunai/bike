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
