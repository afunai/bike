# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Sofa::I18n

	class Msgstr < String
		def %(*args)
			if args.first.is_a? ::Hash
				self.gsub(/%\{(\w+)\}/) { args.first[$1.intern].to_s }
			else
				::String.new(self.gsub(/%\{(\w+)\}/,'%s')) % args
			end
		end
	end

	module REX
		COMMENT           = %r{^.*\#}
		MSGID             = %r{msgid\s*"(.*?[^\\])"}
		MSGSTR            = %r{msgstr\s*"(.*?[^\\])"}
		MSGSTR_PLURAL     = %r{msgstr\[(\d+)\]\s*"(.*?[^\\])"}
		PLURAL_EXPRESSION = %r{
			^"Plural-Forms:.*plural=
			((?:
				n(?=\s*(?:[\+\-\%]|==|!=|>|<|>=|<=))|
				[\d\s\+\-\%\(\)\?\:]+|
				==|!=|>|<|>=|<=|&&|\|\|)+).*"
		}xi
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
				when REX::PLURAL_EXPRESSION
					msg[:plural] = instance_eval "Proc.new {|n| #{$1} }"
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
		m.delete :plural
		Thread.current[:msg] = self.msg.merge m
	end

	def _(msgid)
		Sofa::I18n.msg[msgid] || msgid
	end

	def n_(msgid,msgid_plural,n)
		msgstrs = Sofa::I18n.msg[msgid] || [msgid,msgid_plural]
		case v = Sofa::I18n.msg[:plural] ? Sofa::I18n.msg[:plural].call(n) : (n != 1)
			when true
				msgstrs[1]
			when false
				msgstrs[0]
			else
				msgstrs[v.to_i]
		end
	end

end
