# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Bike::Set::Static::Folder < Bike::Set::Static

  def self.root
    self.new(:id => '')
  end

  def initialize(meta = {})
    meta[:dir]  = meta[:parent] ? ::File.join(meta[:parent][:dir], meta[:id]) : meta[:id]
    meta[:html] = load_html(meta[:dir], meta[:parent])
    super

    ::Dir.glob(::File.join(Bike['skin_dir'], my[:html_dir].to_s, '*.html')).each {|f|
      action = ::File.basename(f, '.*').intern
      merge_tmpl(@meta, Bike::Parser.parse_html(::File.read(f), action)) if action != :index
    }
    ::Dir.glob(::File.join(Bike['skin_dir'], my[:html_dir].to_s, '*.xml')).each {|f|
      action = ::File.basename(f, '.*').intern
      merge_tmpl(@meta, Bike::Parser.parse_xml(::File.read(f), action)) if action != :index
    }

    @meta[:tmpl].values.each {|tmpl|
      tmpl.sub!(/<head>([\s\n]*)/i) {
        "#{$&}<base href=\"@(href)\" />#{$1}"
      }
    } if @meta[:tmpl]

    @meta.merge! load_yaml(my[:dir], my[:parent])
  end

  def meta_dir
    @meta[:dir]
  end

  def meta_html_dir
    if ::File.readable? ::File.join(Bike['skin_dir'], my[:dir], 'index.html')
      my[:dir]
    elsif my[:parent]
      my[:parent][:html_dir]
    end
  end

  private

  def _get(arg)
    if arg['main'] && action_tmpl = action_tmpl(arg['main'])
      _get_by_tmpl(arg, action_tmpl)
    else
      super
    end
  end

  def collect_item(conds = {}, &block)
    if conds[:id] =~ Bike::REX::ID && sd = item('main')
      return sd.instance_eval { collect_item(conds, &block) }
    elsif (
      conds[:id] =~ /\A\w+\z/ &&
      ::File.directory?(::File.join(Bike['skin_dir'], my[:dir], conds[:id]))
    )
      my[:item][conds[:id]] = {:klass  => 'set-static-folder'}
    end
    super
  end

  def load_html(dir, parent, action = :index)
    html_file = ::File.join Bike['skin_dir'], dir, "#{action}.html"
    if ::File.exists? html_file
      ::File.read html_file
    elsif parent
      parent[:html]
    end
  end

  def load_yaml(dir, parent)
    yaml_file = ::File.join(Bike['skin_dir'], dir, 'index.yaml')
    meta = ::File.exists?(yaml_file) ? YAML.load_file(yaml_file) : {}
    meta.keys.inject({}) {|m, k|
      m[k.intern] = meta[k]
      m
    }
  end

  def merge_tmpl(meta, action_meta)
    meta[:tmpl].merge! action_meta[:tmpl]
    meta[:item].each {|id, val|
      merge_tmpl(val, action_meta[:item][id]) if action_meta[:item][id]
    } if action_meta[:item]
    meta
  end

end

