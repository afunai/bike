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
		if @date_str && @date_str !~ REX_DATE
			['wrong format']
		else
			[]
		end
	end

	private

	def _post(action,v)
		case action
			when :load
				@val = val_cast v
			when :create
				now = Time.now
				@val = {
					'create'  => now,
					'update'  => now,
					'publish' => now,
				}
				if my[:can_edit] && v['publish'].is_a?(::Time)
					@val['publish'] = v['publish']
				else
					nil # do not set @action
				end
			when :update
				@val['update'] = Time.now
				if my[:can_edit] && v['publish'].is_a?(::Time)
					@val['publish'] = v['publish']
				elsif my[:can_update] && v['publish'] == :same_as_update
					@val['publish'] = @val['update']
				else
					nil # do not set @action
				end
		end
	end

	def val_cast(v)
		if v.is_a? ::Hash
			v
		elsif v == 'true'
			{'publish' => :same_as_update}
		elsif v.is_a? ::String
			@date_str = v
			(v =~ REX_DATE) ? {'publish' => Time.local($1,$2,$3,$4,$5,$6)} : {}
		else
			{}
		end
	end

end
