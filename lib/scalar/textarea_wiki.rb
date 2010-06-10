# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'csv'

class Runo::Textarea::Wiki < Runo::Textarea

	private

	def _g_default(arg)
		wiki @val.to_s
	end

	def wiki(str)
		str.chomp!

		html = ''
		body = ''
		type = :p

		Runo::Field.h(str).each_line {|line|
			if line =~ /^---$/
				new_type = :hr
			else
				line =~ /^(.?)/
				case $1
					when '!'
						new_type = :heading
					when ','
						new_type = :table
					when '*'
						new_type = :ul
					when '+'
						new_type = :ol
					when ' ', "\t"
						new_type = :pre
					when ''
						new_type = :blank
					else
						new_type = :p
				end
			end
			if new_type != type
				html += __send__("element_#{type}", body.to_s)
				body = ''
			end
			body += line
			type = new_type
		}
		html += __send__("element_#{type}", body) if body != ''

		html
	end

	def element_hr(body)
		body.gsub!(/\n*\Z/, '')
		body.gsub!(/^---$/, "<hr />\n")
	
		<<_html
#{body}
_html
	end

	def element_heading(body)
		<<_html
<h3>#{body}</h3>
_html
	end

	def element_table(body)
		table = CSV.parse(body.gsub!(/^,/, ''))

		table.each_with_index {|row, y|
			row.each_index {|x|
				if (row[x] == :same_as_above)
					row[x] = nil
					next
				end

				span = 1
				((y + 1) .. (table.size - 1)).each {|y_below|
					if (table[y_below][x] == row[x])
						table[y_below][x] = :same_as_above
						span += 1
					else
						break
					end
				}
				rowspan = (span > 1) ? " rowspan=\"#{span}\"" : ''

				row[x] = "<td valign=\"top\"#{rowspan}>#{inline(row[x])}</td>"
			}
		}

		rows = table.collect {|row|
			"\t<tr>" + row.join('') + '</tr>'
		}.join("\n")

		<<_html
<table class="wiki">
#{rows}
</table>
_html
	end

	def element_list(body, ul_ol)
		items = []
		lines = []
		type  = nil
		(body + "\n\n").each_line {|line|
			line.sub!(/^(\*|\+)/, '')

			unless line =~ /^(\*|\+)/ || lines.empty?
				item = inline(lines.shift.to_s.chomp)
				unless lines.empty?
					lines = lines.join
					item += (lines =~ /\A\*/) ? element_ul(lines) : element_ol(lines)
				end
				items << "<li>#{item}</li>\n" if item != ''
				lines = []
			end

			lines << line
		}

		<<_html
<#{ul_ol} class="wiki">
#{items}</#{ul_ol}>
_html
	end

	def element_ul(body)
		element_list(body, 'ul')
	end

	def element_ol(body)
		element_list(body, 'ol')
	end

	def element_pre(body)
		body.gsub!(/\n*\Z/, '')

		<<_html
<pre class="wiki">#{body}
</pre>
_html
	end

	def element_p(body)
		body.gsub!(/\n*\Z/, '')
		body.gsub!(/\n/, "<br />\n")
		body.gsub!(/^/, "\t")

		<<_html
<p class="wiki">
#{inline(body)}
</p>
_html
	end

	def element_blank(body)
		body.gsub!(/\n/, "<br />\n")
	end

	def inline(body)
		body.gsub!(/\*(.+?)\*/, '<strong class="wiki">\1</strong>')
		body.gsub!(/\=\=(.+?)\=\=/, '<s class="wiki">\1</s>')
		body
	end

end
