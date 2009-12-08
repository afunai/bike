require 'rubygems'

class Sofa

	require 'sofa/_field'
	Dir['./sofa/*.rb'].sort.each {|file| require file }

	module REX
		ID      = /^\d{8}_\d{4,}/
		ID_NEW  = /^_\d/
		COND    = /^(.+?)=(.+)$/
		COND_D  = /^(19\d\d|2\d\d\d)\d{0,4}$/
		PATH_ID = /\/((?:19|2\d)\d{6})\/(\d+)/
	end

	def self.[](name)
		@config ||= YAML.load_file './sofa.yaml'
		@config[name]
	end

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

	def self.base
		self.current[:base]
	end

	def call(env)
		req    = Rack::Request.new env
		method = req.request_method.downcase
		params = params_from_request req
		path   = req.path_info
		base   = base_of path
		return response_not_found unless base

		Sofa.current[:env]     = env
		Sofa.current[:req]     = req
		Sofa.current[:session] = env['rack.session']
		Sofa.current[:base]    = base
Sofa.client = 'root'

		if method == 'get'
			until base.is_a? Sofa::Set::Static::Folder
				params = {base[:id] => params}
				params[:conds] = {:id => base[:id]} if base[:parent].is_a? Sofa::Set::Dynamic
				base = base[:parent]
			end if base.is_a? Sofa::Set::Dynamic

			response_ok :body => base.get(params)
		else
			base.update params
			base[:folder].commit :persistent

			if base.is_a? Sofa::Set::Dynamic
				if base.result
					ids = base.result.values.collect {|item|
						item[:id] if item[:id][Sofa::REX::ID]
					}.compact
					id_step = "id=#{ids.join ','}/" unless ids.empty?
					action = params[:status] ? base.workflow.next_action(params) : :update
					response_see_other(
						:location => base[:path] + "/#{id_step}#{action}.html"
					)
				else
					# base.errors
				end
			else
			end
		end
	end

	private

	def params_from_request(req)
		params = rebuild_params req.params

		params[:conds] ||= {}
		params[:conds].merge!(conds_of req.path_info)
		params[:action] = action_of req.path_info

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
			elsif item_id == 'status'
				hash[:status] = (special || val).intern
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
		_dirname(path).gsub(REX::PATH_ID,'').split('/').select {|step_or_cond|
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
		dir   = _dirname path.gsub(REX::PATH_ID,'')
		conds = $& ? {:id => sprintf('%.8d_%.4d',$1,$2)} : {}

		dir.split('/').inject(conds) {|conds,step_or_cond|
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
