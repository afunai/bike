# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Bike::Meta::Owner < Bike::Field

  include Bike::Meta

  private

  def _post(action, v)
    if action == :load
      @val = val_cast v
    elsif action == :create
      @val = Bike.client
    end
    nil
  end

end
