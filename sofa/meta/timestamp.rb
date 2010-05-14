# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Meta::Timestamp < Sofa::Field

	include Sofa::Meta

	REX_DATE = /\A(\d+).(\d+).(\d+)(?:[T\s](\d+):(\d+)(?::(\d+))?)?\z/

	def initialize(meta = {})
		meta[:can_edit]   = true if meta[:tokens].to_a.include? 'can_edit'
		meta[:can_update] = true if meta[:tokens].to_a.include? 'can_update'
		super
	end

	def errors
		if @date_str.nil?
			[]
		elsif @date_str =~ REX_DATE
			(Time.local($1,$2,$3,$4,$5,$6) rescue nil) ? [] : ['out of range']
		else
			['wrong format']
		end
	end

	private

	def _g_default(arg)
		_date val['published']
	end
	alias :_g_published :_g_default

	def _g_created(arg)
		_date val['created']
	end

	def _g_updated(arg)
		_date val['updated']
	end

	def _date(time)
		time.is_a?(::Time) ? time.strftime(_ '%Y-%m-%dT%H:%M:%S') : 'n/a'
	end

	def _g_create(arg)
		<<_html.chomp if my[:can_edit]
<input type="text" name="#{my[:short_name]}" value="" class="#{_g_class arg}" />
_html
	end

	def _g_update(arg)
		if my[:can_edit]
			v = @date_str
			v ||= val['published'].is_a?(::Time) ? val['published'].strftime('%Y-%m-%d %H:%M:%S') : ''
			<<_html.chomp
<input type="text" name="#{my[:short_name]}" value="#{v}" class="#{_g_class arg}" />#{_g_errors arg}
_html
		elsif my[:can_update] && !find_ancestor {|f| f[:id] =~ Sofa::REX::ID_NEW }
			label = 'update the timestamp'
			<<_html.chomp
<input type="checkbox" id="#{my[:short_name]}" name="#{my[:short_name]}" value="true" class="#{_g_class arg}" />
<label for="#{my[:short_name]}">#{label}</label>#{_g_errors arg}
_html
		end
	end

	def _post(action,v)
		case action
			when :load
				@val = val_cast v
			when :create
				now = Time.now
				@val = {
					'created'   => now,
					'updated'   => now,
					'published' => now,
				}
				if my[:can_edit] && v['published'].is_a?(::Time)
					@val['published'] = v['published']
				else
					nil # do not set @action
				end
			when :update
				@val['updated'] = Time.now
				if my[:can_edit] && v['published'].is_a?(::Time)
					@val['published'] = v['published']
				elsif my[:can_update] && v['published'] == :same_as_updated
					@val['published'] = @val['updated']
				else
					nil # do not set @action
				end
		end
	end

	def val_cast(v)
		if v.is_a? ::Hash
			v
		elsif v == 'true'
			{'published' => :same_as_updated}
		elsif v.is_a?(::String) && !v.empty?
			@date_str = v
			(v =~ REX_DATE && t = (Time.local($1,$2,$3,$4,$5,$6) rescue nil)) ? {'published' => t} : {}
		else
			{}
		end
	end

end
