require 'rubygems'

class Sofa

	require 'sofa/_field'
	Dir['./sofa/*.rb'].sort.each {|file| require file }

	module REX
		ID     = /^\d{8}_\d{4,}/
		ID_NEW = /^_\d/
		COND   = /^(.+?)=(.+)$/
		COND_D = /^(19\d\d|2\d\d\d)\d{0,4}$/
	end

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

	def call(env)
		req    = Rack::Request.new env
		method = req.request_method.downcase
		path   = req.path_info
		params = params_from_request req
		action = action_of path
		base   = base_of path

		return [404,{},'Not Found'] unless base

		Sofa.current[:env]     = env
		Sofa.current[:req]     = req
		Sofa.current[:session] = env['rack.session']

		if method == 'get'
			base = base[:folder] if base.is_a? Sofa::Set::Dynamic
			response_ok(:body => base.get(params))
		else
			base.update params
			if base.is_a? Sofa::Set::Dynamic
				if base.valid?
					base.commit
					base.workflow.next(action)
				else
				end
			else
			end
		end
	end

	private

	def params_from_request(req)
		params = rebuild_params req.params

		base = base_of req.path_info
		params_of_base = base[:name].split('-').inject(params) {|p,s| p[s] ||= {} }
		params_of_base[:conds] ||= {}
		params_of_base[:conds].merge!(conds_of req.path_info)
		params_of_base[:action] = action_of req.path_info

		params
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

	def steps_of(path)
		_dirname(path).split('/').select {|step_or_cond|
			step_or_cond != '' && step_or_cond !~ REX::COND && step_or_cond !~ REX::COND_D
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
		_dirname(path).split('/').inject({}) {|conds,step_or_cond|
			if step_or_cond =~ REX::COND
				conds[$1.intern] = $2
			elsif step_or_cond =~ REX::COND_D
				conds[:d] = $&
			end
			conds
		}
	end

	def action_of(path)
		basename = _basename path
		basename && basename !~ /^index/ ? basename.split('.').first.intern : nil
	end

	def _dirname(path) # returns '/foo/bar/' for '/foo/bar/'
		path[%r{^.*/}] || ''
	end

	def _basename(path) # returns nil for '/foo/bar/'
		path[%r{[^/]+$}]
	end

	def response_ok(result = {})
		[
			200,
			(
				result[:headers] ||
				{
					'Content-Type'   => 'text/html',
					'Content-Length' => result[:body].size.to_s,
				}
			),
			result[:body],
		]
	end

	def response_no_content(result = {})
		[
			204,
			(result[:headers] || {}),
			[]
		]
	end

	def response_see_other(result = {})
location = 'http://localhost:9292' + result[:location]
		body = <<_html
<a href="#{location}">updated</a>
_html
		[
			303,
			{
				'Content-Type'   => 'text/html',
				'content-Length' => body.size.to_s,
				'Location'       => location,
			},
			body
		]
	end

	def response_forbidden(result = {})
		[
			403,
			{},
			'Forbidden'
		]
	end

	def response_not_found(result = {})
		[
			404,
			{},
			'Not Found'
		]
	end

end
