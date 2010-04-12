# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa

	Dir['./sofa/*.rb'].sort.each {|file| require file }
	Dir['./sofa/*/*.rb'].sort.each {|file| require file }

	module REX
		ID_SHORT = /[a-z][a-z0-9\_\-]*/
		ID       = /^(\d{8})_(\d{4,}|#{ID_SHORT})/
		ID_NEW   = /^_\d/
		COND     = /^(.+?)=(.+)$/
		COND_D   = /^(19\d\d|2\d\d\d|9999)\d{0,4}$/
		PATH_ID  = /\/((?:19|2\d)\d{6})\/(\d+)/
		TID      = /\d{10}\.\d+/
	end

	def self.[](name)
		@config ||= YAML.load_file './sofa.yaml'
		@config[name]
	end

	def self.current
		Thread.current
	end

	def self.session
		self.current[:session] || ($fake_session ||= {})
	end

	def self.transaction
		self.session[:transaction] ||= {}
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
		tid    = Sofa::Path.tid_of path

		Sofa.current[:env]     = env
		Sofa.current[:req]     = req
		Sofa.current[:session] = env['rack.session']

		if Sofa.transaction[tid].is_a? Sofa::Field
			base = Sofa.transaction[tid].item(Sofa::Path.steps_of path)
		else
			base = Sofa::Path.base_of path
		end
		return response_not_found unless base

		base[:tid] = tid
		Sofa.current[:base] = base

		begin
			if params[:action] == :logout
				logout(base,params)
			elsif method == 'get'
				get(base,params)
			elsif params[:action] == :login
				login(base,params)
			elsif params[:action] == :confirm
				confirm(base,params)
			else
				post(base,params)
			end
		rescue Sofa::Error::Forbidden
			if params[:action] && Sofa.client == 'nobody'
				params[:dest_action] = (method == 'post') ? :index : params[:action]
				params[:action] = :login
			end
			begin
				response_unprocessable_entity :body => _get(base,params)
			rescue Sofa::Error::Forbidden
				response_forbidden
			end
		end
	end

	private

	def login(base,params)
		user = Sofa::Set::Static::Folder.root.item('_users','main',params['id'].to_s)
		if user && params['pw'].to_s.crypt(user.val('password')) == user.val('password')
			Sofa.client = params['id']
		else
			Sofa.client = nil
			raise Sofa::Error::Forbidden
		end
		path   = Sofa::Path.path_of params[:conds]
		action = (params['dest_action'] =~ /\A\w+\z/) ? params['dest_action'] : 'index'
		response_see_other(
			:location => "#{base[:path]}/#{path}#{action}.html"
		)
	end

	def logout(base,params)
		Sofa.client = nil
		path = Sofa::Path.path_of params[:conds]
		response_see_other(
			:location => "#{base[:path]}/#{path}index.html"
		)
	end

	def get(base,params)
		if base.is_a? Sofa::File
			response_ok(
				:headers => {
					'Content-Type'   => base.val['type'],
					'Content-Length' => base.body.size.to_s,
				},
				:body    => base.body
			)
		else
			response_ok :body => _get(base,params)
		end
	end

	def confirm(base,params)
		Sofa.transaction[base[:tid]] ||= base

		base.update params
		if base.commit :temp
			id_step = result_step(base,params)
			action = "confirm_#{params[:sub_action]}"
			response_see_other(
				:location => "/#{base[:tid]}/#{id_step}#{action}.html"
			)
		else
			params = {:action => :update}
			params[:conds] = {:id => base.errors.keys}
			return response_unprocessable_entity(:body => _get(base,params))
		end
	end

	def post(base,params)
		Sofa.transaction[base[:tid]] ||= base

		base.update params
		if params[:status]
			if base[:folder].commit :persistent
				Sofa.transaction[base[:tid]] = :updated
				action = base.workflow.next_action params
				id_step = result_step(base,params) if base[:parent] == base[:folder] && action != :done
				response_see_other(
					:location => "/#{base[:tid]}#{base[:path]}/#{id_step}#{action}.html"
				)
			else
				params = {:action => :update}
				params[:conds] = {:id => base.errors.keys}
				response_unprocessable_entity :body => _get(base,params)
			end
		else
			id_step = Sofa::Path.path_of(:id => base.send(:pending_items).keys)
			base.commit :temp
			response_see_other(
				:location => "/#{base[:tid]}/#{id_step}update.html"
			)
		end
	end

	def result_step(base,params)
		if base.result
			id = base.result.values.collect {|item| item[:id] }
		else
			id = params.keys.select {|id|
				id.is_a?(::String) && (id[Sofa::REX::ID] || id[Sofa::REX::ID_NEW])
			}
		end
		Sofa::Path.path_of(:id => id)
	end

	def _get(f,params)
		params[:action] ||= f.default_action
		until f.is_a? Sofa::Set::Static::Folder
			params = {
				:action     => (f.default_action == :read) ? :read : nil,
				:sub_action => f.send(:summary?,params) ? nil : :detail,
				f[:id]      => params,
			}
			params[:conds] = {:id => f[:id]} if f[:parent].is_a? Sofa::Set::Dynamic
			f = f[:parent]
		end if f.is_a? Sofa::Set::Dynamic

		f.get params
	end

	def params_from_request(req)
		params = {
			:action     => Sofa::Path.action_of(req.path_info),
			:sub_action => Sofa::Path.sub_action_of(req.path_info),
		}
		params.merge!(rebuild_params req.params)

		params[:conds] ||= {}
		params[:conds].merge!(Sofa::Path.conds_of req.path_info)

		params
	end

	def rebuild_params(src)
		src.each_key.sort.reverse.inject({}) {|params,key|
			name,special = key.split('.',2)
			steps = name.split '-'

			if special
				special_id,special_val = special.split('-',2)
			else
				item_id = steps.pop
			end

			hash = steps.inject(params) {|v,k| v[k] ||= {} }
			val  = src[key]

			if special_id == 'action'
				action,sub_action = (special_val || val).split('_',2)
				hash[:action] = action.intern
				hash[:sub_action] = sub_action.intern if sub_action
			elsif special_id == 'status'
				hash[:status] = (special_val || val).intern
			elsif special_id == 'conds'
				hash[:conds] ||= {}
				hash[:conds][special_val.intern] = val
			elsif hash[item_id].is_a? ::Hash
				hash[item_id][:self] = val
			else
				hash[item_id] = val
			end

			params
		}
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
				'Content-Length' => body.size.to_s,
				'Location'       => location,
			},
			body
		]
	end

	def response_forbidden(result = {})
		[
			403,
			{},
			result[:body] || 'Forbidden'
		]
	end

	def response_not_found(result = {})
		[
			404,
			{},
			'Not Found'
		]
	end

	def response_unprocessable_entity(result = {})
		[
			422,
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

end
