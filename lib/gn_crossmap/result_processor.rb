module GnCrossmap
  # Processes data received from the GN Resolver
  class ResultProcessor
    attr_reader :input, :writer

    def initialize(writer, stats)
      @stats = stats
      @writer = writer
      @input = {}
    end

    def process(result, original_data)
      @original_data = original_data
      result.each do |d|
        d.results.empty? ? write_empty_result(d) : write_result(d)
      end
    end

    private

    def rubyfy(result)
      JSON.parse(result, symbolize_names: true)
    end

    def write_empty_result(datum)
      @stats.stats[:matches][GnCrossmap::MATCH_TYPE_EMPTY] += 1
      @stats.stats[:resolved_records] += 1
      res = @original_data[datum.supplied_id]
      res += [GnCrossmap::MATCH_TYPE_EMPTY, datum.suppliedInput, nil,
              nil,
              nil, # @input[datum[:supplied_id]][:rank] - rank is not supported yet
              nil,
              nil, nil, nil]
      @writer.write(res)
    end

    def write_result(datum)
      collect_stats(datum)
      datum.results.each do |result|
        @writer.write(compile_result(datum, result))
      end
    end

    def collect_stats(datum)
      match_type_min = datum.results.min_by { |d| d.matchType.score }
      match_type_value = if match_type_min.nil? then GnCrossmap::MATCH_TYPE_EMPTY
                         else match_type_min.matchType.value
                         end
      # stats_matches = @stats.stats[:matches].fetch(match_type_value, 0) + 1
      @stats.stats[:matches][match_type_value] += 1
      @stats.stats[:resolved_records] += 1
    end

    def compile_result(datum, result)
      @original_data[datum.suppliedId] + new_data(datum, result)
    end

    def new_data(datum, result)
      [result.matchType.value, datum.suppliedInput, result.name.name, result.canonicalName.name,
       @input[datum.suppliedId][:rank], matched_rank(result),
       # synonym is not supported until
       # https://github.com/GlobalNamesArchitecture/gnresolver/issues/76
       nil,
       # TODO: add `current_name_string` field
       result.name.name,
       nil, # TODO: result[:edit_distance] can be either 0 or 1, and is derived from `matchType`
       nil, # TODO: result[:score] is not supported, yet
       result.taxonId]
    end

    def matched_rank(result)
      result.classification.pathRanks.split("|").last
    end
  end
end
