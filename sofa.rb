require 'rubygems'
require 'sinatra'

get %r{(/.*/)(.*).(html)} do
	<<_html	
<h1>Hello cruel world!</h1>
#{params[:captures].join ','}
_html
end

__END__

class Map
	def initialize(params)
		params[:html] = load_html(dir) if params[:dir]
		@meta,@tmpl = parse_html(params[:html])
# cache meta & tmpl
		load_items(@meta)
	end
	def get(arg = {})
	end
end

---

class Item
	attr :items
	def initialize(dir,parent = nil)
		@tmpl = ...
	end
	def select(list_id,conds = {})
		selectors = Selector.new(conds)
		...
		@items[list_id] = vals.collect {|v| Item.new(dir,self).load(v) }
	end
	def result
		result = {}
		@items.each {|id,item|
			result[id] = item.result # item can be scalar or list of item
		}
		@tmpl.gsub(...) {|id| result[id] }
	end
end

def get
	chdir {
		tmpl = parse(tmpl_file)
		item_files = selector.select()
		items = item_files.collect {|i|
			vals = YAML.load(i)
			tmpl.add_item(vals)
		}
	}
	tmpl.result
end

<body>
	<div class="sofa-item" sofa-id="blog">
		<h2>title:(text 16 0..32)</h2>
		<p>body*:(wiki 76*10 1..1024)</p>
		<p>region*:(select "west coast","east coast","southern island","northern area")></p>
		<div class="sofa-item">
			image':(img 160*120)
		</div>
	</div>
	<a class="sofa-paging" sofa-id="blog-next">next</a>
	<a class="sofa-paging" sofa-id="blog-prev">prev</a>
</body>

static:
/foo/bar/index.html
/foo/bar/002.html
/foo/bar/003.html
/foo/bar/files/001_of_0001.jpg

dynamic:
/sofa.rb/foo/bar/index.html
/sofa.rb/foo/bar/create.html
/sofa.rb/foo/bar/081026_001/update.html
