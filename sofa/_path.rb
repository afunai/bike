# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Sofa::Path

	module_function

	def tid_of(path)
		path[Sofa::REX::TID]
	end

	def steps_of(path)
		_dirname(path).gsub(Sofa::REX::PATH_ID,'').split('/').select {|step_or_cond|
			step_or_cond != '' &&
			step_or_cond !~ Regexp.union(Sofa::REX::COND,Sofa::REX::COND_D,Sofa::REX::TID)
		}
	end

	def base_of(path)
		base = Sofa::Set::Static::Folder.root.item(steps_of path)
		if base.is_a? Sofa::Set::Static::Folder
			base.item 'main'
		else
			base
		end
	end

	def conds_of(path)
		dir   = _dirname path.gsub(Sofa::REX::PATH_ID,'')
		conds = $& ? {:id => sprintf('%.8d_%.4d',$1,$2)} : {}

		dir.split('/').inject(conds) {|conds,step_or_cond|
			if step_or_cond =~ Sofa::REX::COND
				conds[$1.intern] = $2
			elsif step_or_cond =~ Sofa::REX::COND_D
				conds[:d] = $&
			end
			conds
		}
	end

	def action_of(path)
		a = _basename(path).to_s[/^[a-z]+/]
		a.intern if a && a != 'index'
	end

	def sub_action_of(path)
		a = _basename(path).to_s[/_([a-z]+)/,1]
		a.intern if a
	end

	def path_of(conds)
		conds = {} unless conds.is_a? ::Hash
		(
			(conds.keys - [:order,:p,:id]) |
			([:order,:p,:id] & conds.keys)
		).collect {|cid|
			if cid == :id
				ids = Array(conds[:id]).collect {|id|
					(id =~ /_(#{Sofa::REX::ID_SHORT})$/) ? $1 : (id if Sofa::REX::ID)
				}.compact
				if (ids.size == 1) && (ids.first =~ Sofa::REX::ID)
					'%s/%d/' % [$1,$2.to_i]
				elsif ids.size > 0
					"id=#{ids.join ','}/"
				end
			elsif cid == :d
				conds[:id] ? '' : "#{conds[:d]}/"
			else
				"#{cid}=#{Array(conds[cid]).join ','}/"
			end
		}.join.sub(%r{/p=1/$},'/')
	end

	def _dirname(path) # returns '/foo/bar/' for '/foo/bar/'
		path[%r{^.*/}] || ''
	end

	def _basename(path) # returns nil for '/foo/bar/'
		path[%r{[^/]+$}]
	end

end

