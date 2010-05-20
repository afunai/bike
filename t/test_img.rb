# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

class TC_Img < Test::Unit::TestCase

	def setup
		File.open('t/skin/t_img/test.jpg') {|f|
			@img  = f.read
			@file = Tempfile.open('tc_img')
			@file << @img
		}

		meta = nil
		Sofa::Parser.gsub_scalar('$(foo img 32*32 1..100000 jpg,gif,png)') {|id,m|
			meta = m
			''
		}
		@f = Sofa::Field.instance meta.merge(:id => 'foo')
	end

	def test_meta
		assert_equal(
			1,
			@f[:min],
			'Img#initialize should set :min from the range token'
		)
		assert_equal(
			100000,
			@f[:max],
			'Img#initialize should set :max from the range token'
		)
		assert_equal(
			['jpg','gif','png'],
			@f[:options],
			'Img#initialize should set :options from the csv token'
		)
	end

	def test_val_cast_from_rack
		@f.create(
			:type     => 'image/jpeg',
			:tempfile => @file,
			:head     => <<'_eos',
Content-Disposition: form-data; name="t_img"; filename="baz.jpg"
Content-Type: image/jpeg
_eos
			:filename => 'baz.jpg',
			:name     => 't_img'
		)

		assert_equal(
			{
				'basename' => 'baz.jpg',
				'type'     => 'image/jpeg',
				'size'     => @file.length,
			},
			@f.val,
			'Img#val_cast should re-map a hash from Rack'
		)
		assert_equal(
			@img,
			@f.body,
			'Img#val_cast should store the file body in @body'
		)
		assert_equal(
			@f.send(:_thumbnail,@file),
			@f.thumbnail,
			'Img#val_cast should store the thumbnail in @thumbnail'
		)
	end

	def test_val_cast_load
		@f.load(
			'basename' => 'baz.jpg',
			'type'     => 'image/jpeg',
			'size'     => 123
		)
		assert_equal(
			{
				'basename' => 'baz.jpg',
				'type'     => 'image/jpeg',
				'size'     => 123,
			},
			@f.val,
			'Img#val_cast should load() a hash without :tempfile like Set#load'
		)
	end

	def test_get
		Sofa.client = 'root'

		@f[:parent] = Sofa::Set::Static::Folder.root.item('t_img','main')
		Sofa.current[:base] = @f[:parent]
		tid = @f[:parent][:tid]

		@f.load({})
		assert_nil(
			@f.get,
			'Img#get should return nil when the val is empty'
		)

		@f.load(
			'basename' => 'baz.jpg',
			'type'     => 'image/jpeg',
			'size'     => 12
		)
		assert_equal(
			<<'_html'.chomp,
<span class="img">
	<a href="/t_img/main/foo/baz.jpg"><img href="/t_img/main/foo/baz.small.jpg" /></a>
</span>
_html
			@f.get,
			'Img#get should return proper string'
		)
		assert_equal(
			<<"_html".chomp,
<span class="img">
	<a href="/#{tid}/foo/baz.jpg"><img href="/#{tid}/foo/baz.small.jpg" /></a>
</span>
<span class="file">
	<input type="file" name="foo" class="img" />
</span>
_html
			@f.get(:action => :update),
			'Img#get should return proper string'
		)

		@f.load(
			'basename' => '<baz>.jpg',
			'type'     => 'image/<jpeg>',
			'size'     => 12
		)
		assert_equal(
			<<'_html'.chomp,
<span class="img">
	<a href="/t_img/main/foo/&lt;baz&gt;.jpg"><img href="/t_img/main/foo/&lt;baz&gt;.small.jpg" /></a>
</span>
_html
			@f.get,
			'Img#get should escape the special characters in file information'
		)
	end

	def ptest_call_body
		Sofa.client = 'root'
		sd = Sofa::Set::Static::Folder.root.item('t_img','main')
		sd.storage.clear

		# post a multipart request
		input = <<"_eos".gsub(/\r?\n/,"\r\n")
---foobarbaz
Content-Disposition: form-data; name="_1-foo"; filename="foo.jpg"
Content-Type: image/jpeg

#{@file.read.base64}
---foobarbaz--
_eos
		res = Rack::MockRequest.new(Sofa.new).post(
			'http://example.com/t_img/main/update.html',
			{
				:input           => input,
				'CONTENT_TYPE'   => 'multipart/form-data; boundary=-foobarbaz',
				'CONTENT_LENGTH' => input.length,
			}
		)
		tid = res.headers['Location'][Sofa::REX::TID]

		# commit the base
		res = Rack::MockRequest.new(Sofa.new).post(
			"http://example.com/#{tid}/update.html",
			{
				:input => '.status-public=create',
			}
		)

		res.headers['Location'] =~ Sofa::REX::PATH_ID
		new_id = sprintf('%.8d_%.4d',$1,$2)

		res = Rack::MockRequest.new(Sofa.new).get(
			"http://example.com/t_img/#{new_id}/foo/foo.jpg"
		)
		assert_equal(
			'image/jpeg',
			res.headers['Content-Type'],
			'Sofa#call to a file item should return the mime type of the file'
		)
		assert_equal(
			@file.length.to_s,
			res.headers['Content-Length'],
			'Sofa#call to a file item should return the content length of the file'
		)
		assert_equal(
			@file.read,
			res.body,
			'Sofa#call to a file item should return the binary body of the file'
		)

		# delete
		Rack::MockRequest.new(Sofa.new).post(
			'http://example.com/t_img/update.html',
			{
				:input => '19811202_0001.action=delete&.status-public=delete',
			}
		)
		res = Rack::MockRequest.new(Sofa.new).get(
			'http://example.com/t_img/19811202_0001/foo/foo.jpg'
		)
		assert_equal(
			404,
			res.status,
			'Sofa#call should delete child files as well'
		)
		res = Rack::MockRequest.new(Sofa.new).get(
			'http://example.com/t_img/19811202_0001/foo/foo.small.jpg'
		)
		assert_equal(
			404,
			res.status,
			'Sofa#call should delete child files as well'
		)
	end

	def test_errors
	end

end
