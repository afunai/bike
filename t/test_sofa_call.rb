# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'rubygems'
require 'rack'

class TC_Sofa_Call < Test::Unit::TestCase

	def setup
		@sofa = Sofa.new
	end

	def teardown
	end

	def test_get
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/'
		)
		assert_match(
			/<html/,
			res.body,
			'Sofa#call() should return the folder.get if the base field is a SD'
		)
	end

	def test_get_non_exist
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/non/exist/'
		)
		assert_equal(
			404,
			res.status,
			'Sofa#call() should return 404 if the given path is non-existent'
		)
	end

	def test_get_partial
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/20091120_0001/name/'
		)
		assert_equal(
			'FZ',
			res.body,
			'Sofa#call() should return the base.get unless the base field is a SD'
		)
	end

	def test_post_simple_create
		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/update.html',
			{
				:input => "_1-name=fz&_1-comment=hi.&.status-public=create"
			}
		)
		assert_equal(
			303,
			res.status,
			'Sofa#call with post method should return status 303'
		)
		assert_match(
			/id=\d+_\d+/,
			res.headers['Location'],
			'Sofa#call with post method should return a proper location'
		)

		new_id = res.headers['Location'][/id=(\d+_\d+)/,1]
		assert_equal(
			{'name' => 'fz','comment' => 'hi.'},
			Sofa::Set::Static::Folder.root.item('t_store','main',new_id).val,
			'Sofa#call with post method should store the item in the storage'
		)
	end

	def test_post_with_attachment
		Sofa::Set::Static::Folder.root.item('t_attachment','main').storage.clear

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_attachment/main/update.html',
			{
				:input => "_012-files-_1-file=wow.jpg&_012-files.status-public=create"
			}
		)
		assert_match(
			'update.html',
			res.headers['Location'],
			'Sofa#call without the root status should always return :update'
		)
		assert_equal(
			{},
			Sofa::Set::Static::Folder.root.item('t_attachment','main').val,
			'Sofa#call without the root status should not update the persistent storage'
		)

		tid = res.headers['Location'][%r{\/(\d+)},1]
		assert_instance_of(
			Sofa::Set::Dynamic,
			Sofa.transaction[tid],
			'the suspended SD should be kept in Sofa.transaction'
		)
		assert_equal(
			['_012'],
			Sofa.transaction[tid].send(:pending_items).keys,
			'the suspended SD should not be committed yet'
		)

		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/#{tid}/update.html",
			{
				:input => "_012-comment=hello.&.status-public=create"
			}
		)
		assert_no_match(
			/update\.html/,
			res.headers['Location'],
			'Sofa#call with the root status should commit the transaction'
		)
		assert_not_equal(
			{},
			Sofa::Set::Static::Folder.root.item('t_attachment','main').val,
			'Sofa#call without the root status should not update the persistent storage'
		)

		new_id = res.headers['Location'][/id=#{Sofa::REX::ID}/,1]
	end

end
