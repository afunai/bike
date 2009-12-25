# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class Sofa::Storage

	def self.instance(sd)
		if folder = sd[:folder]
			klass = Sofa['STORAGE']['default'].capitalize
			if klass == 'File' && folder != sd[:parent]
				Temp.new sd
			else
				self.const_get(klass).new sd
			end
		else
			Temp.new sd
		end
	end

	def self.available?
		false
	end

	attr_reader :sd

	def initialize(sd)
		@sd = sd
	end

	def select(conds = {})
		item_ids = _select(conds)
		item_ids = _sort(item_ids,conds)
		item_ids = _page(item_ids,conds)
	end

	def build(v)
		self
	end

	def clear
		self
	end

	def store(id,v)
		id
	end

	def delete(id)
		id
	end

	def navi(conds)
		lower_cid = navi_prev = navi_next = navi_sibs = nil

		(([:id,:p,:d] & conds.keys) | conds.keys).each {|cid|
			next unless respond_to?("_sibs_#{cid}",true)
			sibs = __send__("_sibs_#{cid}",conds)

			if i = sibs.index(conds[cid])
				if !navi_prev && i > 0
					navi_prev = conds.merge(cid => sibs[i - 1])
					navi_prev[lower_cid] = :last if lower_cid
				end
				if !navi_next && i < (sibs.size - 1)
					navi_next = conds.merge(cid => sibs[i + 1])
					navi_next[lower_cid] = 1 if lower_cid
				end
			end
			navi_sibs ||= {cid => sibs} if navi_prev || navi_next

			break if navi_prev && navi_next
			lower_cid = cid
		}

		{
			:prev => navi_prev,
			:next => navi_next,
			:sibs => navi_sibs || {},
		}
	end

	private

	def _select(conds = {})
# TODO: cast / sanitize
		if conds[:id]
			_select_by_id(conds) | (@sd.instance_variable_get(:@item_object).keys & conds[:id].to_a)
		elsif cid = (conds.keys - [:order,:p]).first
			m = "_select_by_#{cid}"
			respond_to?(m,true) ? __send__(m,conds) : []
		else
			_select_all(conds) | @sd.instance_variable_get(:@item_object).keys
		end
	end

	def _sort(item_ids,conds)
		case conds[:order]
			when '-d','-id'
				item_ids.sort.reverse
			else
				item_ids.sort
		end
	end

	def _page(item_ids,conds)
		page = conds[:p].to_i
		page = 1 if page < 1
		size = @sd[:p_size].to_i
		size = 10 if size < 1
		item_ids[(page - 1) * size,size].to_a
	end

	def _sibs_id(conds)
		_select_without(:id,conds)
	end

	def _sibs_p(conds)
		return [] if @sd[:p_size].to_i == 0
		p_count = (_item_count(conds) / @sd[:p_size].to_f).ceil
		(1..p_count).to_a
	end

	def _sibs_d(conds)
		rex_d = /^\d{#{conds[:d].length}}/
		_select.collect {|id| id[rex_d] }.uniq
	end

	def _item_count(conds)
		_select_without(:p,conds).size
	end

	def _select_without(cid,conds)
		c = conds.dup
		c.delete cid
		_select(c)
	end

	def new_id
		d = Time.now.strftime '%Y%m%d'
		if max_in_d = select(:d => d,:order => 'id').last
			d + '_%.4d' % (max_in_d[/\d{4}$/].to_i + 1)
		else
			d + '_0001'
		end
	end

end
