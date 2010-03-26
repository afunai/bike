# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Set::Dynamic < Sofa::Field

	include Sofa::Set

	attr_reader :storage,:workflow

	def initialize(meta = {})
		@meta        = meta
		@storage     = Sofa::Storage.instance self
		@workflow    = Sofa::Workflow.instance self
		@meta        = @workflow.class.const_get(:DEFAULT_META).merge @meta
		@item_object = {}

		my[:item] ||= {
			'default' => {:item => {}}
		}
		my[:item].each {|type,meta|
			meta[:item].merge! @workflow.default_sub_items
		}

		my[:p_size] = meta[:max] if meta[:max]
	end

	def meta_tid
		unless @meta[:tid]
			t = Time.now
			@meta[:tid] = t.strftime('%m%d%H%M%S.') + t.usec.to_s
		end
		@meta[:tid]
	end

	def meta_dir
		my[:folder][:dir] if my[:folder]
	end

	def meta_path
		(my[:name] == 'main') ? my[:dir] : "#{my[:dir]}/#{my[:name].sub(/^main-?/,'').gsub('-','/')}"
	end

	def meta_base_path
		Sofa.base ? Sofa.base[:path] : my[:path]
	end

	def get(arg = {})
		if !arg[:conds].is_a?(::Hash) || arg[:conds].empty?
			arg[:conds] = my[:conds].is_a?(::Hash) ? my[:conds].dup : {}
		end
		super
	end

	def _get_by_tmpl(arg,tmpl = '')
		(arg[:action] == :read || self != Sofa.base) ? super : <<_html
<form id="#{my[:name]}" method="post" action="/#{my[:tid]}#{my[:base_path]}/update.html">
#{super}</form>
_html
	end

	def commit(type = :temp)
		items = pending_items
		if @storage.is_a? Sofa::Storage::Temp
			items.each {|id,item|
				action = item.action
				item.commit(type) && _commit(action,id,item)
			}
		else
			items.each {|id,item|
				action = item.action || :update
				result = item.commit(:temp)
				if result && type == :persistent
					_commit(action,id,item) && item.commit(:persistent)
				end
			}
		end
		if pending_items.empty?
			@result = (@action == :update) ? items : @action
			@action = nil
			self
		end
	end

	private

	def _val
		@storage.val
	end

	def _get(arg)
		(@workflow._get(arg) || super) unless @workflow._hide? arg
	end

	def _get_by_self_reference(arg)
		super unless @workflow._hide?(arg)
	end

	def _g_login(arg)
		path = Sofa::Path.path_of arg[:conds]
		action = arg[:dest_action]
		_g_message(arg).to_s + <<_html
<form id="#{my[:name]}" method="post" action="#{my[:base_path]}/#{path}login.html">
	<input type="hidden" name="dest_action" value="#{action}" />
	<label for="id">id</label><input type="text" id="id" name="id" size="10" value="" />
	<label for="pw">pw</label><input type="password" id="pw" name="pw" size="10" value="" />
	<input type="submit" value="login" />
</form>
_html
	end

	def _g_done(arg)
		'done.'
	end

	def _g_message(arg)
		if message = Sofa.message[my[:tid]]
			Sofa.message.delete my[:tid]
			message.keys.collect {|type|
				lis = message[type].collect {|m| "\t<li>#{Rack::Utils.escape_html m}</li>\n" }
				<<_html
	<ul class="message #{type}">
	#{lis}</ul>
_html
			}.join
		end
	end

	def _g_submit(arg)
		@workflow._g_submit arg
	end

	def _g_action_create(arg)
		(_get_by_action_tmpl(arg) || <<_html) if permit_get?(:action => :create)
<div><a href="#{_g_uri_create arg}">create</a></div>
_html
	end

	def _g_uri_create(arg)
		"#{my[:path]}/create.html"
	end

	def _g_navi(arg)
		arg[:navi] ||= @storage.navi(arg[:conds] || {})
		return unless (arg[:orig_action] == :read) && (arg[:navi][:prev] || arg[:navi][:next])

		div = my[:tmpl_navi] || '<div>$(.navi_prev) | $(.navi_p)$(.navi_next)</div>'
		div.gsub(/\$\(\.(navi_prev|navi_next|navi_p|uri_prev|uri_next)\)/) {
			__send__("_g_#{$1}",arg)
		}
	end

	def _g_navi_prev(arg)
		button = my[:tmpl_navi_prev] || 'prev'
		(uri = _g_uri_prev(arg)) ? "<a href=\"#{my[:path]}/#{uri}\">#{button}</a>" : button
	end

	def _g_navi_next(arg)
		button = my[:tmpl_navi_next] || 'next'
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

	def _g_view_ym(arg)
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
		div = Sofa::Parser.gsub_block(div,'y') {|open,inner,close|
			inner = Sofa::Parser.gsub_block(inner,'m') {|*t|
				month_tmpl = t.join
				'$(.months)'
			}
			year_tmpl = open + inner + close
			'$(.years)'
		}
		years = uris.inject({}) {|y,u|
			year = u[/(\d{4})\d\d\/$/,1]
			y[year] ||= []
			y[year] << u
			y
		}
		div.gsub('$(.years)') {
			years.keys.sort.collect {|year|
				year_tmpl.gsub('$(.y)',year).gsub('$(.months)') {
					years[year].collect {|uri|
						d = uri[/(\d{6})\//,1]
						y = d[/^\d{4}/]
						m = d[/\d\d$/]
						month_tmpl.gsub(/\$\((?:\.(ym|m))?\)/) {
							label = ($1 == 'ym') ? _label_ym(y,m) : _label_m(m)
							(arg[:conds][:d] == d) ?
								"<span class=\"current\">#{label}</span>" :
								"<a href=\"#{my[:path]}/#{uri}\">#{label}</a>"
						}
					}.join
				}
			}.join
		}
	end

	def _uri_ym(arg)
		@storage.__send__(:_sibs_d,:d => '000000').collect {|ym|
			Sofa::Path.path_of :d => ym
		}
	end

# TODO: move to Sofa::I18n
def _label_ym(y,m)
	'%1$s/%2$s' % [y,_label_m(m)]
end

def _label_m(m)
	m
end

	def _post(action,v = nil)
		@workflow.before_post(action,v)
		case action
			when :create,:update
				@storage.build({}) if action == :create

				v.each_key.sort_by {|id| id.to_s }.each {|id|
					next unless id.is_a? ::String
					v[id][:action] ||= id[Sofa::REX::ID_NEW] ? :create : :update
					item_instance(id).post(v[id][:action],v[id])
				}
			when :load,:load_default
				@storage.build v
		end
		@workflow.after_post
	end

	def _commit(action,id,item)
		case action
			when :create
				return if item.empty?
				new_id = @storage.store(:new_id,item.val)
				item[:id] = new_id
				@item_object.delete id
			when :update
				@storage.store(item[:id],item.val)
				if item[:id] != id || item.empty?
					@storage.delete(id)
					@item_object.delete id
				end
			when :delete
				@storage.delete(id)
				@item_object.delete id
		end
	end

	def collect_item(conds = {},&block)
		@storage.select(conds).collect {|id|
			item = item_instance id
			block ? block.call(item) : item
		}
	end

	def item_instance(id,type = 'default')
		unless @item_object[id]
			item_meta = my[:item][type] || my[:item]['default']
			@item_object[id] = Sofa::Field.instance(
				item_meta.merge(
					:id     => id,
					:parent => self,
					:klass  => 'set-static'
				)
			)
			if id[Sofa::REX::ID_NEW]
				@item_object[id].load_default
			else
				@item_object[id].load(@storage.val id)
			end
		end
		@item_object[id]
	end

end
