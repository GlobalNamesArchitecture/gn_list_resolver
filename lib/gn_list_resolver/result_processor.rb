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

    def process(results, original_data)
      @original_data = original_data
      results.each do |result|
        if result.results.empty?
          write_empty_result(result)
        else
          write_result(flatten_result(result))
        end
      end
    end

    private

    def extract_result(result, res, r)
      {
        supplied_id: result.supplied_id,
        supplied_input: result.supplied_input,
        total: result.total,
        name: res.name.value,
        canonical_name:
            res.canonical_name.nil? ? nil : res.canonical_name.value,
        accepted_name: r.accepted_name,
        synonym: r.synonym,
        match_type: r.match_type,
        taxon_id: r.taxon_id,
        classification: r.classification,
        score: r.score
      }
    end

    def flatten_result(result)
      result.results.flat_map do |res|
        res.results_per_data_source.flat_map do |rpds|
          rpds.results.map do |r|
            extract_result(result, res, r)
          end
        end
      end
    end

    def write_empty_result(datum)
      @stats.stats[:matches][MATCH_TYPE_EMPTY] += 1
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
      datum.each { |result| @writer.write(compile_result(result)) }
    end

    def collect_stats(datum)
      match_type_value =
        case datum.size
        when 0 then MATCH_TYPE_EMPTY
        else datum.min_by { |d| d[:match_type].score }[:match_type].kind.to_sym
        end
      @stats.stats[:matches][match_type_value] += 1
    end

    def compile_result(result)
      @original_data[result[:supplied_id]] + prepare_data(result)
    end

    # rubocop:disable Metrics/AbcSize

    def prepare_data(result)
      res = [MATCH_TYPES[result[:match_type].kind.to_sym],
             result[:total],
             result[:supplied_input],
             result[:name],
             canonical(result[:supplied_input]),
             result[:canonical_name],
             result[:match_type].edit_distance,
             @input[result[:supplied_id]][:rank],
             matched_rank(result),
             result[:synonym],
             current_name(result),
             result[:score].value ? result[:score].value.round(3) : nil,
             result[:taxon_id]]
      res << classification(result) if @with_classification
      res
    end

    # rubocop:enable all

    def current_name(result)
      if result[:accepted_name].nil?
        result[:name]
      else
        result[:accepted_name].name.value
      end
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
      return nil unless result[:classification].path_ranks
      result[:classification].path_ranks.split("|").last
    end

    def classification(result)
      return nil if result[:classification].path.to_s.strip == ""
      path = result[:classification].path.split("|")
      ranks_data = result[:classification].path_ranks
      ranks = ranks_data ? ranks_data.split("|") : []
      if path.size == ranks.size
        path = path.zip(ranks).map { |e| "#{e[0]}(#{e[1]})" }
      end
      path.join(", ")
    end

    # rubocop:enable all
  end
end
