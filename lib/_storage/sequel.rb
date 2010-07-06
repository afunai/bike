# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

require 'rubygems'
require 'sequel'
require 'yaml'
require 'ya2yaml'

class Runo::Storage::Sequel < Runo::Storage

  def self.db
    if Runo['storage']['Sequel'] && Runo['storage']['Sequel']['uri']
      @db ||= ::Sequel.connect Runo['storage']['Sequel']['uri']
      self.load_skel unless @db.table_exists? :runo_main
    end
    @db
  end

  def self.load_skel
    @db.create_table(:runo_main) {
      String :full_name
      String :ext
      String :owner
      String :body
      File   :binary_body
      primary_key :full_name
    } unless @db.table_exists? :runo_main
    Runo::Storage::File.traverse('/', Runo['skin_dir']) {|entry|
      @db[:runo_main].insert(
        :full_name   => entry[:full_name],
        :ext         => entry[:ext],
        :owner       => entry[:val]['_owner'],
        :body        => entry[:val].ya2yaml(:syck_compatible => true),
        :binary_body => (entry[:ext] == 'yaml') ? nil : entry[:val].to_sequel_blob
      ) unless @db[:runo_main][:full_name => entry[:full_name]]
    }
  end

  def self.available?
    self.db
  end

  def initialize(sd)
    super
    @dataset = Runo::Storage::Sequel.db[:runo_main]
    @dirname = @sd[:full_name]
  end

  def val(id = nil)
    if id
      load id
    else
      # this could be HUGE.
      _select_all({}).inject({}) {|v, id|
        v[id] = load id
        v
      }
    end
  end

  def build(v)
    clear
    v.each {|id, v| store(id, v) } if v
    self
  end

  def clear
    @dataset.grep(:full_name, _full_name('%')).delete
    self
  end

  def store(id, v, ext = nil)
    save(id, v, ext)
  end

  def delete(id)
    @dataset.filter(_conds id).delete &&
    @dataset.grep(:full_name, _full_name("#{id}-%")).and(~:ext => 'yaml').delete &&
    id
  end

  def move(old_id, new_id)
    rename(old_id, new_id) && new_id
  end

  private

  def _select_by_id(conds)
    @dataset.filter(_conds conds[:id]).collect {|v| _id v[:full_name] }
  end

  def _select_by_d(conds)
    @dataset.
      grep(:full_name, _full_name("#{conds[:d]}%")).
      and(:ext => 'yaml').
      collect {|v| _id v[:full_name] }
  end

  def _select_all(conds)
    @dataset.
      grep(:full_name, _full_name('%')).
      and(:ext => 'yaml').
      collect {|v| _id v[:full_name] }
  end

# TODO: overrride _sort() & _page() (they can be done in _select_*)

  def _conds(id)
    (id == :all) ? {} : {:full_name => _full_name(id)}
  end

  def _full_name(id)
    "#{@dirname}-#{id}"
  end

  def _id(full_name)
    full_name.sub("#{@dirname}-", '')
  end

  def load(id)
# TODO: cache in _select_*
    v = @dataset[:full_name => _full_name(id)]
    (v[:ext] == 'yaml' ? YAML.load(v[:body]) : v[:binary_body]) if v
  end

  def save(id, v, ext)
    Runo::Storage::Sequel.db.transaction {
      if new_id?(id, v)
        old_id = id
        id = new_id v
      end

      full_name = _full_name id

      if ext
        ext = 'y' if ext == 'yaml'
        val = {
          :full_name   => full_name,
          :ext         => ext,
          :binary_body => v.to_sequel_blob,
        }
      else
        val = {
          :full_name => full_name,
          :ext       => 'yaml',
          :owner     => v['_owner'],
          :body      => v.ya2yaml(:syck_compatible => true),
        }
      end

      if old_id
        return if @dataset[:full_name => full_name] # duplicate id
        move(old_id, id) unless old_id == :new_id
      end
      if @dataset[:full_name => full_name]
        @dataset[:full_name => full_name] = val
      else
        @dataset.insert val
      end
      id
    }
  end

  def rename(old_id, new_id)
    @dataset.grep(:full_name, _full_name("#{old_id}%")).each {|v|
      @dataset[:full_name => v[:full_name]] = v.merge(
        :full_name => v[:full_name].sub(_full_name(old_id), _full_name(new_id))
      )
    }
  end

end
