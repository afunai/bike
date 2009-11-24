# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Complex < Test::Unit::TestCase

	class ::Sofa::Set::Dynamic
		def _get_modify(arg)
			_get_by_tmpl({:action => :modify},my[:tmpl]) + '[modify]'
		end
		def _get_vegetable(arg)
			"'potato'"
		end
	end

	class ::Sofa::Workflow::Pipco < ::Sofa::Workflow
		PERM = {
			:create    => 'oo--',
			:read      => 'oooo',
			:update    => 'ooo-',
			:delete    => 'o-o-',
			:modify    => 'ooo-',
			:vegetable => 'oooo',
		}
	end

	class ::Sofa::Tomago < ::Sofa::Field
		def get(arg)
			"'#{val}'(#{arg.sort.join ','})"
		end
	end

	def setup
		# Set::Dynamic of Set::Static of (Scalar and (Set::Dynamic of Set::Static of Scalar))
		@sd = Sofa::Set::Dynamic.new(
			:id        => 'main',
			:klass     => 'set-dynamic',
			:workflow  => 'pipco',
			:group     => ['roy','don'],
			:tmpl      => <<'_tmpl',
<ul id="@(name)" class="sofa-pipco">
$()</ul>
_tmpl
			:item_html => <<'_html'
	<li id="@(name)">
		name:(tomago 32 :'nobody'): comment:(tomago 64 :'hi.')
		<ul id="files" class="sofa-pipco">
			<li id="@(name)">file:(tomago :'foo.jpg')</li>
		</ul>
		$(files.vegetable)
	</li>
_html
		)
		@sd.load(
			'20091123_0001' => {
				'_owner'  => 'carl',
				'name'    => 'CZ',
				'comment' => 'oops',
				'files'   => {
					'20091123_0001' => {'file' => 'carl1.jpg'},
					'20091123_0002' => {'file' => 'carl2.jpg'},
				},
			},
			'20091123_0002' => {
				'_owner'  => 'roy',
				'name'    => 'RE',
				'comment' => 'wee',
				'files'   => {
					'20091123_0001' => {'file' => 'roy.png'},
				},
			}
		)
	end

	def teardown
		Sofa.client = nil
	end

	def test_get_default
		assert_equal(
			<<'_html',
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action,read): 'oops'(action,read)
		<ul id="main-20091123_0001-files" class="sofa-pipco">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action,read)</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action,read)</li>
		</ul>
		'potato'
	</li>
	<li id="main-20091123_0002">
		'RE'(action,read): 'wee'(action,read)
		<ul id="main-20091123_0002-files" class="sofa-pipco">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action,read)</li>
		</ul>
		'potato'
	</li>
</ul>
_html
			@sd.get,
			'Set#get should work recursively as a part of the complex'
		)
	end

	def test_get_with_arg
		Sofa.client = 'root'
puts			@sd.get(:action => :modify)
return
		assert_equal(
			<<'_html',
_html
			@sd.get(:action => :update),
			'Set#get should work recursively as a part of the complex'
		)
	end

end
