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
		basename = _basename path
		basename && basename !~ /^index/ ? basename.split('.').first.intern : nil
	end

	def path_of(conds)
		if conds[:id] =~ Sofa::REX::ID
			'%s/%d/' % [$1,$2.to_i]
		else
			conds.keys.sort_by {|k|
				[:order,:p].include?(k) ? k.to_s : "_#{k}"
			}.collect {|cid|
				"#{cid}=#{Array(conds[cid]).join ','}/"
			}.join
		end
	end

	def _dirname(path) # returns '/foo/bar/' for '/foo/bar/'
		path[%r{^.*/}] || ''
	end

	def _basename(path) # returns nil for '/foo/bar/'
		path[%r{[^/]+$}]
	end

end

