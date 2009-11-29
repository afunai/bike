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
