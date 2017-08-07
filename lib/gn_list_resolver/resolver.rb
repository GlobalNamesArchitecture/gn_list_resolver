# frozen_string_literal: true

module GnListResolver
  # Sends data to GN Resolver and collects results
  class Resolver
    GRAPHQL = GnGraphQL.new
    QUERY = GRAPHQL.client.parse(GRAPHQL.query)
    attr_reader :stats

    def initialize(writer, data_source_id, stats, with_classification = false)
      @stats = stats
      @processor = GnListResolver::ResultProcessor.new(writer, @stats,
                                                       with_classification)
      @ds_id = data_source_id
      @count = 0
      @current_data = {}
      @batch = 1000
    end

    def resolve(data)
      update_stats(data.size)
      block_given? ? process(data, &Proc.new) : process(data)
      wrap_up
      block_given? ? yield(@stats.stats) : @stats.stats
    end

    private

    def process(data)
      cmd = nil
      data.each_slice(@batch) do |slice|
        with_log do
          collect_names(slice)
          remote_resolve(slice)
          cmd = yield(@stats.stats) if block_given?
        end
        break if cmd == "STOP"
      end
    end

    def wrap_up
      @stats.stats[:resolution_stop] = Time.now
      @stats.stats[:status] = :finish
      @processor.writer.close
    end

    def update_stats(records_num)
      @stats.stats[:total_records] = records_num
      @stats.stats[:resolution_start] = Time.now
      @stats.stats[:status] = :resolution
    end

    def with_log
      s = @count + 1
      @count += @batch
      e = [@count, @stats.stats[:total_records]].min
      GnListResolver.log("Resolve #{s}-#{e} out of " \
                         "#{@stats.stats[:total_records]} records at " \
                         "#{RESOLVER_URL}")
      yield
    end

    def collect_names(slice)
      @current_data = {}
      slice.each_with_object([]) do |row, str|
        id = row[:id].strip
        @current_data[id] = row[:original]
        @processor.input[id] = { rank: row[:rank] }
        str << "#{id}|#{row[:name]}"
      end.join("\n")
    end

    def variables(names)
      { dataSourceIds: [@ds_id],
        names: names.
          map { |name| { value: name[:name], suppliedId: name[:id] } } }
    end

    def remote_resolve(names)
      batch_start = Time.now

      res = GRAPHQL.client.query(QUERY, variables: variables(names))
      if res.data
        @processor.process(res.data.name_resolver.responses, @current_data)
      else
        single_remote_resolve(names)
      end
      update_batch_times(batch_start)
    end

    def single_remote_resolve(names)
      names.each do |name|
        res = GRAPHQL.client.query(QUERY, variables: variables([name]))
        if res.data
          @processor.process(res.data.name_resolver, @current_data)
        else
          process_resolver_error(res, name)
        end
      end
    end

    def update_batch_times(batch_start)
      s = @stats.stats
      s[:last_batches_time].shift if s[:last_batches_time].size > 2
      s[:last_batches_time] << Time.now - batch_start
      s[:resolution_span] = Time.now - s[:resolution_start]
    end

    def process_resolver_error(res, name)
      @stats.stats[:matches][:ErrorInMatch] += 1
      @stats.stats[:resolved_records] += 1
      error =
        "Resolver broke on '#{name}': #{res.errors.messages['data'].first}"
      GnListResolver.logger.error(error)
    end
  end
end
