require 'rubygems'
require 'sinatra/base'

class Sofa < Sinatra::Base

	require 'sofa/_field'
	Dir['./sofa/*.rb'].sort.each {|file| require file }

ROOT_DIR = './t/data' # TODO
STORAGE  = {
	'default' => 'File',
	'File'    => {
		'data_dir' => './t/data',
	},
	'Mysql'   => {
		'dbname' => 'sofa',
		'user'   => 'foo',
		'pw'     => 'bar',
	}
}

	REX_COND   = /^(.+?)=(.+)$/
	REX_COND_D = /^(19\d\d|2\d\d\d)/

	def self.current
		Thread.current
	end

	def self.session
		self.current[:session] || (@@fake_session ||= {})
	end

	def self.client
		self.session[:client] ||= 'nobody'
	end

	def self.client=(id)
		self.session[:client] = id
	end

get %r{/(.*/)(.*).(html)} do
	path,action,ext = *params[:captures]
	folder = Sofa::Set::Static::Folder.root.item path.split('/')
	folder.get
end

	private

def params_from_request(req)
	params = rebuild_params(req.params)

	params[:conditions] = conditions_from_path(req.path_info) + params[:conditions].to_a
	params.delete(:conditions) if params[:conditions].empty?

	action = action_from_path(req.path_info)
	params[:action],params[:sub_action] = action.split('.',2) if action
	params
end

	def steps_from_path(path)
		path.split('/').select {|step_or_cond|
			step_or_cond != '' && step_or_cond !~ REX_COND && step_or_cond !~ REX_COND_D
		}
	end

def conds_from_path(path)
	path.split('/').inject({}) {|conds,step_or_cond|
		if step_or_cond =~ REX_COND
			conds[$1.intern] = $2
		elsif step_or_cond =~ REX_COND_D
			conds[:d] = $1
		end
		conds
	}
end

def action_from_path(path)
	filename = path.split('/',-1).last[/([^\.]+)\./,1]
	filename.gsub('_','.') if filename && filename != 'index'
end

def path_from_steps(steps)
	steps.join('/') + (steps.empty? ? '' : '/')
end

	def rebuild_params(src)
		src.each_key.sort.reverse.inject({}) {|params,key|
			name,special = key.split('.',2)
			steps = name.split '-'

			if special
				item_id,special = special.split('-',2)
			else
				item_id = steps.pop
			end

			hash = steps.inject(params) {|v,k| v[k] ||= {} }
			val  = src[key]

			if item_id == 'action'
				hash[:action] = (special || val).intern
			elsif item_id == 'conds'
				hash[:conds] ||= {}
				hash[:conds][special.intern] = val
			elsif hash[item_id].is_a? ::Hash
				hash[item_id][:self] = val
			else
				hash[item_id] = val
			end

			params
		}
	end

end
