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
		Sofa::Parser.gsub_scalar('$(foo img 32*32 1..100000 jpg,gif,png crop)') {|id,m|
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
		assert_equal(
			true,
			@f[:crop],
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

	def test_large_thumbnail
		@f[:width] = @f[:height] = 640
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
		assert_not_equal(
			0,
			@f.instance_variable_get(:@thumbnail).to_s.size,
			'Img#_thumbnail should make a thumbnail larger than the original img'
		)
	end

	def test_get
		Sofa.client = 'root'

		@f[:parent] = Sofa::Set::Static::Folder.root.item('t_img','main')
		Sofa.current[:base] = @f[:parent]
		tid = @f[:parent][:tid]

		@f.load({})
		assert_equal(
			<<'_html'.chomp,
<span class="img" style="width: 32px; height: 32px;"></span>
_html
			@f.get,
			'Img#get should return default span when the val is empty'
		)

		@f.load(
			'basename' => 'baz.jpg',
			'type'     => 'image/jpeg',
			'size'     => 12
		)
		assert_equal(
			<<'_html'.chomp,
<span class="img">
	<a href="/t_img/main/foo/baz.jpg"><img src="/t_img/main/foo/baz_small.jpg" alt="baz.jpg" /></a>
</span>
_html
			@f.get,
			'Img#get should return proper string'
		)
		assert_equal(
			<<"_html".chomp,
<span class="img">
	<a href="/t_img/#{tid}/foo/baz.jpg"><img src="/t_img/#{tid}/foo/baz_small.jpg" alt="baz.jpg" /></a>
</span>
<span class="file">
	<input type="file" name="foo" size="" class="img" />
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
	<a href="/t_img/main/foo/&lt;baz&gt;.jpg"><img src="/t_img/main/foo/&lt;baz&gt;_small.jpg" alt="&lt;baz&gt;.jpg" /></a>
</span>
_html
			@f.get,
			'Img#get should escape the special characters in file information'
		)
	end

	def test_call_body
		Sofa.client = 'root'
		sd = Sofa::Set::Static::Folder.root.item('t_img','main')
		sd.storage.clear

		# post a multipart request
		input = <<"_eos".gsub(/\r?\n/,"\r\n").sub('@img',@img)
---foobarbaz
Content-Disposition: form-data; name="_1-foo"; filename="foo.jpg"
Content-Type: image/jpeg
Content-Transfer-Encoding: binary

@img
---foobarbaz
Content-Disposition: form-data; name="_token"

#{Sofa.token}
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
				:input => ".status-public=create&_token=#{Sofa.token}",
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
			'Sofa#call to a img item should return the mime type of the file'
		)
		assert_equal(
			@img.size,
			res.body.size,
			'Sofa#call to a img item should return the binary body of the file'
		)

		res = Rack::MockRequest.new(Sofa.new).get(
			"http://example.com/t_img/#{new_id}/foo/foo_small.jpg"
		)
		assert_equal(
			'image/jpeg',
			res.headers['Content-Type'],
			"Sofa#call to 'file-small.*' should return the thumbnail of the file"
		)
		@file.rewind
		assert_equal(
			@f.send(:_thumbnail,@file).size,
			res.body.size,
			"Sofa#call to 'file-small.*' should return the thumbnail of the file"
		)

		# delete
		Rack::MockRequest.new(Sofa.new).post(
			'http://example.com/t_img/update.html',
			{
				:input => "#{new_id}.action=delete&.status-public=delete&_token=#{Sofa.token}",
			}
		)
		res = Rack::MockRequest.new(Sofa.new).get(
			"http://example.com/t_img/#{new_id}/foo/foo.jpg"
		)
		assert_equal(
			404,
			res.status,
			'Sofa#call should delete child files as well'
		)
		res = Rack::MockRequest.new(Sofa.new).get(
			"http://example.com/t_img/#{new_id}/foo/foo_small.jpg"
		)
		assert_equal(
			404,
			res.status,
			'Sofa#call should delete child files as well'
		)
	end

	def test_errors
		File.open('t/skin/t_img/index.html') {|f|
			@img  = f.read
			@file = Tempfile.open('tc_img')
			@file << @img
		}
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
			['wrong file type: should be jpg/gif/png'],
			@f.errors,
			"Img#errors should regard quick_magick errors as 'wrong file type'"
		)

		File.open('t/skin/t_img/test.jpg') {|f|
			@img  = f.read
			@file = Tempfile.open('tc_img')
			@file << @img
		}
		@f.update(
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
			[],
			@f.errors,
			"Img#errors should raise no errors for good imgs"
		)
	end

end
