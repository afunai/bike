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
		my[:item].each {|type,item_meta|
			item_meta[:item] = @workflow.default_sub_items.merge item_meta[:item]
		}

		my[:p_size] = meta[:max] if meta[:max]
		my[:confirm] = :optional if meta[:tokens].to_a.include?('may_confirm')
		my[:confirm] = :mandatory if meta[:tokens].to_a.include?('should_confirm')
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

	def commit(type = :temp)
		items = pending_items
		items.each {|id,item|
			item.commit(:temp) || next
			case type
				when :temp
					store(id,item) if @storage.is_a? Sofa::Storage::Temp
				when :persistent
					store(id,item)
					item.commit :persistent
			end
		}
		if valid?
			@result = (@action == :update) ? items : @action
			@action = nil if type == :persistent
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

	def _get_by_tmpl(arg,tmpl = '')
		if arg[:action] == :read || self != Sofa.base
			super
		else
			base_path = Sofa.transaction[my[:tid]].is_a?(Sofa::Field) ? nil : my[:base_path]
			action = "#{base_path}/#{my[:tid]}/update.html"
			<<_html
<form id="#{my[:name]}" method="post" enctype="multipart/form-data" action="#{action}">
#{super}</form>
_html
		end
	end

	def _get_by_self_reference(arg)
		super unless @workflow._hide?(arg)
	end

	def _g_login(arg)
		path = Sofa::Path.path_of arg[:conds]
		action = arg[:dest_action]
		<<_html
<form id="#{my[:name]}" method="post" action="#{my[:base_path]}/#{path}login.html">
	<input type="hidden" name="dest_action" value="#{action}" />
	<label for="id">id</label><input type="text" id="id" name="id" size="10" value="" />
	<label for="pw">pw</label><input type="password" id="pw" name="pw" size="10" value="" />
	<input type="submit" value="#{_ 'login'}" />
</form>
_html
	end

	def _g_done(arg)
		_ 'done.'
	end

	def _g_message(arg)
		return unless self == Sofa.base

		if arg[:dest_action]
			message = {:alert => _('please login.')}
		elsif arg[:orig_action] == :confirm
			message = {:notice => _('please confirm.')}
		elsif !self.valid? && arg[:orig_action] != :create
			message = {:error => _('malformed input.')}
		elsif Sofa.transaction[my[:tid]].is_a? ::Hash
			message = {
				:notice => Sofa.transaction[my[:tid]].keys.collect {|item_result|
					n = Sofa.transaction[my[:tid]][item_result]
					_('%{result} %{n} %{item}.') % {
						:result => {
							:create => _('created'),
							:update => _('updated'),
							:delete => _('deleted'),
						}[item_result],
						:n      => n,
						:item   => n_(
							(my[:item].size == 1 && my[:item]['default'][:label]) || my[:item_label],
							'',
							n
						)
					}
				}
			} unless Sofa.transaction[my[:tid]].empty?
			Sofa.transaction.delete my[:tid]
		end

		message.keys.collect {|type|
			lis = message[type].collect {|m| "\t<li>#{Rack::Utils.escape_html m}</li>\n" }
			<<_html
<ul class="message #{type}">
#{lis}</ul>
_html
		}.join if message
	end

	def _g_submit(arg)
		@workflow._g_submit arg
	end

	def _g_action_create(arg)
		label = _('create new %{item}...') % {
			:item => _((my[:item].size == 1 && my[:item]['default'][:label]) || my[:item_label])
		}
		(_get_by_action_tmpl(arg) || <<_html) if permit_get?(:action => :create)
<div><a href="#{_g_uri_create arg}">#{label}</a></div>
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

	def _label_ym(y,m)
		_('%{year}/%{month}') % {
			:year  => y,
			:month => _label_m(m)
		}
	end

	def _label_m(m)
		_ Date::ABBR_MONTHNAMES[m.to_i]
	end

	def permit_get?(arg)
		permit?(arg[:action]) || collect_item(arg[:conds] || {}).all? {|item|
			item[:id][Sofa::REX::ID_NEW] ?
				item.permit?(:create) :
				item.send(:permit_get?,:action => arg[:action])
		}
	end

	def _post(action,v = nil)
		@workflow.before_post(action,v)

		if action == :create
			@storage.build({})
			@item_object.clear
		end

		case action
			when :create,:update
				v.each_key.sort_by {|id| id.to_s }.each {|id|
					next unless id.is_a? ::String

					v[id][:action] ||= id[Sofa::REX::ID_NEW] ? :create : :update
					item_instance(id).post(v[id][:action],v[id])
				}
			when :load,:load_default
				@storage.build v
		end

		@workflow.after_post
		!pending_items.empty? || action == :delete
	end

	def store(id,item)
		case item.action
			when :create
				return if id[Sofa::REX::ID] || item.empty?
				new_id = @storage.store(:new_id,item.val)
				item[:id] = new_id
				@item_object.delete id
				@item_object[item[:id]] = item
			when :update,nil
				new_id = @storage.store(item[:id],item.val)
				if new_id != item[:id]
					@item_object[new_id] = @item_object.delete item[:id]
					item[:id] = new_id
				end
			when :delete
				@storage.delete id
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
