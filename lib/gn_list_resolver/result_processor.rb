# frozen_string_literal: true

module GnListResolver
  # Processes data received from the GN Resolver
  class ResultProcessor
    attr_reader :input, :writer

    def initialize(writer, stats, with_classification = false)
      @with_classification = with_classification
      @parser = ScientificNameParser.new
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

    def write_empty_result(datum)
      @stats.stats[:matches][MATCH_TYPE_EMPTY] += 1
      @stats.stats[:resolved_records] += 1
      res = compile_empty_result(datum)
      @writer.write(res)
    end

    def compile_empty_result(datum)
      res = @original_data[datum.supplied_id]
      res += [MATCH_TYPES[MATCH_TYPE_EMPTY], 0, datum.supplied_input,
              nil, nil, nil, nil,
              @input[datum.supplied_id][:rank],
              nil, nil, nil, nil, nil]
      res <<  nil if @with_classification
      res
    end

    def write_result(datum)
      collect_stats(datum)
      match_size = datum.results.size
      datum.results.each do |result|
        @writer.write(compile_result(datum, result, match_size))
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

    def compile_result(datum, result, match_size)
      @original_data[datum.supplied_id] + prepare_data(datum,
                                                       result, match_size)
    end

    # rubocop:disable Metrics/AbcSize

    def prepare_data(datum, result, match_size)
      res = [MATCH_TYPES[result.match_type.kind.to_sym], match_size,
             datum.supplied_input, result.name.value,
             canonical(datum.supplied_input), result_canonical(result),
             result.match_type.edit_distance, @input[datum.supplied_id][:rank],
             matched_rank(result), result.synonym, current_name(result),
             result.score.value ? result.score.value.round(3) : nil,
             result.taxon_id]
      res << classification(result) if @with_classification
      res
    end

    # rubocop:enable all

    def current_name(result)
      if result.accepted_name.nil?
        result.name.value
      else
        result.accepted_name.name.value
      end
    end

    def result_canonical(result)
      return nil unless result.canonical_name
      result.canonical_name.value
    end

    def canonical(name_string)
      parsed = @parser.parse(name_string)[:scientificName]
      return nil if parsed[:canonical].nil? || parsed[:hybrid]
      parsed[:canonical]
    rescue StandardError
      @parser = ScientificNameParser.new
      nil
    end

    def matched_rank(result)
      return nil unless result.classification.path_ranks
      result.classification.path_ranks.split("|").last
    end

    # rubocop:disable Metrics/AbcSize

    def classification(result)
      return nil if result.classification.path.to_s.strip == ""
      path = result.classification.path.split("|")
      ranks_data = result.classification.path_ranks
      ranks = ranks_data ? ranks_data.split("|") : []
      if path.size == ranks.size
        path = path.zip(ranks).map { |e| "#{e[0]}(#{e[1]})" }
      end
      path.join(", ")
    end

    # rubocop:enable all
  end
end
