# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Runo::Set::Dynamic

	private

	def _g_view_ym(arg)
		return unless permit? :read

		uris = _uri_ym arg
		return unless uris && uris.size > 1

		year_tmpl = month_tmpl = nil
		div = my[:tmpl_view_ym] || <<'_tmpl'
<div class="view_ym">
	<span class="y">
		$(.y) |
		<span class="m">$()</span>
		<br/>
	</span>
</div>
_tmpl
		div = Runo::Parser.gsub_block(div, 'y') {|open, inner, close|
			inner = Runo::Parser.gsub_block(inner, 'm') {|*t|
				month_tmpl = t.join
				'$(.months)'
			}
			year_tmpl = open + inner + close
			'$(.years)'
		}
		years = uris.inject({}) {|y, u|
			year = u[/(\d{4})\d\d\/$/, 1]
			y[year] ||= []
			y[year] << u
			y
		}
		p = (my[:order] =~ /^-/) ? 'p=last/' : ''
		div.gsub('$(.years)') {
			years.keys.sort.collect {|year|
				year_tmpl.gsub('$(.y)', year).gsub('$(.months)') {
					years[year].collect {|uri|
						d = uri[/(\d{6})\//, 1]
						y = d[/^\d{4}/]
						m = d[/\d\d$/]
						month_tmpl.gsub(/\$\((?:\.(ym|m))?\)/) {
							label = ($1 == 'ym') ? _label_ym(y, m) : _label_m(m)
							(arg[:conds][:d] == d) ?
								"<span class=\"current\">#{label}</span>" :
								"<a href=\"#{my[:path]}/#{uri}#{p}\">#{label}</a>"
						}
					}.join
				}
			}.join
		}
	end

	def _uri_ym(arg)
		@storage.__send__(:_sibs_d, :d => '000000').collect {|ym|
			Runo::Path.path_of :d => ym
		}
	end

	def _label_ym(y, m)
		_('%{year}/%{month}') % {
			:year  => y,
			:month => _label_m(m)
		}
	end

	def _label_m(m)
		_ Date::ABBR_MONTHNAMES[m.to_i]
	end

end
