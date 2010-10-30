# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Bike::Set::Static::Folder < Bike::Set::Static

  def self.root
    self.new(:id => '')
  end

  def initialize(meta = {})
    meta[:dir]  = meta[:parent] ? ::File.join(meta[:parent][:dir], meta[:id]) : meta[:id]
    @meta = meta
    @meta.merge! load_html
    @meta.merge! load_yaml

    @meta[:tmpl].values.each {|tmpl|
      tmpl.sub!(/<head>([\s\n]*)/i) { "#{$&}<base href=\"@(href)\" />#{$1}" }
    }

    @item_object = {}
  end

  def meta_dir
    @meta[:dir]
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

  def load_html
    files = ::Dir[::File.join Bike['skin_dir'], my[:dir], '*.{html,xml}'].sort

    if model_file = files.find {|f| ['form', 'index'].include? ::File.basename(f, '.*') }
      html   = ::File.read model_file
      action = ::File.basename(model_file, '.*').intern
      meta   = {:html => html}
      meta.merge! Bike::Parser.parse_html(html, action)

      files.delete model_file
      files.each {|f|
        html   = ::File.read f
        action = ::File.basename(f, '.*').intern
        merge_tmpl(
          meta,
          Bike::Parser.parse_html(html, action)
        )
      }

      meta
    elsif my[:parent]
      {
        :label => my[:parent][:label],
        :item  => my[:parent][:item],
        :tmpl  => my[:parent][:tmpl],
      }
    else
      {
        :item => {},
        :tmpl => {},
      }
    end
  end

  def load_yaml
    yaml_file = ::File.join(Bike['skin_dir'], my[:dir], 'index.yaml')
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

