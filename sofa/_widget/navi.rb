# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class Sofa::Set::Dynamic

	private

	def _g_navi(arg)
		arg[:navi] ||= @storage.navi(arg[:conds] || {})
		return unless (arg[:orig_action] == :read) && (arg[:navi][:prev] || arg[:navi][:next])

		div = my[:tmpl_navi] || '<div class="navi">$(.navi_prev) | $(.navi_p)$(.navi_next)</div>'
		div.gsub(/\$\(\.(navi_prev|navi_next|navi_p|uri_prev|uri_next)\)/) {
			__send__("_g_#{$1}",arg)
		}
	end

	def _g_navi_prev(arg)
		button = my[:tmpl_navi_prev] || _('prev')
		(uri = _g_uri_prev(arg)) ? "<a href=\"#{my[:path]}/#{uri}\">#{button}</a>" : button
	end

	def _g_navi_next(arg)
		button = my[:tmpl_navi_next] || _('next')
		(uri = _g_uri_next(arg)) ? "<a href=\"#{my[:path]}/#{uri}\">#{button}</a>" : button
	end

	def _g_navi_p(arg)
		uris = _uri_p(arg)
		return unless uris && uris.size > 1

		item_tmpl = nil
		div = my[:tmpl_navi_p] || '<span class="item">$() </span> | '
		div = Sofa::Parser.gsub_block(div,'item') {|open,inner,close|
			item_tmpl = open + inner + close
			'$(.items)'
		}
		div.gsub('$(.items)') {
			uris.collect {|uri|
				p = uri[/p=(\d+)/,1] || '1'
				if arg[:conds][:p] == p
					item_tmpl.gsub('$()',p)
				else
					item_tmpl.gsub('$()',"<a href=\"#{my[:path]}/#{uri}\">#{p}</a>")
				end
			}.join
		}
	end

	def _g_uri_prev(arg)
		arg[:navi] ||= @storage.navi(arg[:conds] || {})
		Sofa::Path.path_of(arg[:navi][:prev]) if arg[:navi][:prev]
	end

	def _g_uri_next(arg)
		arg[:navi] ||= @storage.navi(arg[:conds] || {})
		Sofa::Path.path_of(arg[:navi][:next]) if arg[:navi][:next]
	end

	def _uri_p(arg)
		arg[:navi] ||= @storage.navi(arg[:conds] || {})
		if arg[:navi][:sibs] && arg[:navi][:sibs].keys.first == :p
			base_conds = arg[:conds].dup
			base_conds.delete :p
			conds = arg[:navi][:sibs].values.first
			if p = arg[:conds][:p]
				range = ['1',conds.last] + ((p.to_i - 5)..(p.to_i + 5)).to_a.collect {|i| i.to_s }
				conds = conds & range
			end
			conds.collect {|cond|
				Sofa::Path.path_of base_conds.merge(:p => cond)
			}
		end
	end

end
