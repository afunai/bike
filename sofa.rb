# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'rubygems'

class Sofa

	Dir['./sofa/*.rb'].sort.each {|file| require file }

	module REX
		ID      = /^(\d{8})_(\d{4,}|[a-z][a-z0-9\_\-]*)/
		ID_NEW  = /^_\d/
		COND    = /^(.+?)=(.+)$/
		COND_D  = /^(19\d\d|2\d\d\d)\d{0,4}$/
		PATH_ID = /\/((?:19|2\d)\d{6})\/(\d+)/
		TID     = /\d{10}\.\d+/
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

		base = Sofa.transaction[tid] || Sofa::Path.base_of(path)
		return response_not_found unless base

base[:tid] = tid
		Sofa.current[:base] = base
Sofa.client = 'root'

		if method == 'get'
			get(base,params)
		else
			post(base,params)
		end
	end

	private

	def get(base,params)
		until base.is_a? Sofa::Set::Static::Folder
			params = {base[:id] => params}
			params[:conds] = {:id => base[:id]} if base[:parent].is_a? Sofa::Set::Dynamic
			base = base[:parent]
		end if base.is_a? Sofa::Set::Dynamic

		response_ok :body => base.get(params)
	end

	def post(base,params)
		base.update params
		if params[:status]
			base[:folder].commit :persistent
			if base.result
				ids = base.result.values.collect {|item|
					item[:id] if item[:id][Sofa::REX::ID]
				}.compact
				id_step = "id=#{ids.join ','}/" unless ids.empty? || base[:parent] != base[:folder]
				action = base.workflow.next_action params
				response_see_other(
					:location => base[:path] + "/#{id_step}#{action}.html"
				)
			else
				# base.errors
			end
		else
			Sofa.transaction[base[:tid]] ||= base
			items = base.instance_eval {
				@item_object.values.select {|item| item.pending? }
			}
			base.commit :temp

			item_ids = items.collect {|item| item[:id] }
			id_step  = "id=#{item_ids.join ','}/" unless item_ids.empty?
			response_see_other(
				:location => base[:path] + "/#{base[:tid]}/#{id_step}update.html"
			)
		end
	end

	def params_from_request(req)
		params = rebuild_params req.params

		params[:conds] ||= {}
		params[:conds].merge!(Sofa::Path.conds_of req.path_info)
		params[:action] = Sofa::Path.action_of req.path_info

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
				hash[:action] = (special_val || val).intern
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
