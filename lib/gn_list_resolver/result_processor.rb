# frozen_string_literal: true

module GnListResolver
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
      @stats.stats[:matches][MATCH_TYPE_EMPTY] += 1
      @stats.stats[:resolved_records] += 1
      res = @original_data[datum.supplied_id]
      res += [MATCH_TYPES[MATCH_TYPE_EMPTY], datum.supplied_input, nil,
              nil,
              @input[datum.supplied_id][:rank],
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
      match_type_min = datum.results.min_by { |d| d.match_type.score }
      match_type_value = if match_type_min.nil?
                           MATCH_TYPE_EMPTY
                         else
                           match_type_min.match_type.kind.to_sym
                         end
      @stats.stats[:matches][match_type_value] += 1
      @stats.stats[:resolved_records] += 1
    end

    def compile_result(datum, result)
      @original_data[datum.supplied_id] + prepare_data(datum, result)
    end

    # rubocop:disable Metrics/AbcSize

    def prepare_data(datum, result)
      [MATCH_TYPES[result.match_type.kind.to_sym],
       datum.supplied_input, result.name.name,
       result.canonical_name.name, @input[datum.supplied_id][:rank],
       matched_rank(result),
       result.synonym,
       result.name.name, # TODO: should be `current_name_string` field
       result.match_type.edit_distance,
       result.score.value ? result.score.value.round(3) : nil,
       result.taxon_id]
    end

    # rubocop:enable all

    def matched_rank(result)
      result.classification.path_ranks.split("|").last
    end
  end
end
