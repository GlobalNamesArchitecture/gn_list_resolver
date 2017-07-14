require "graphql/client"
require "graphql/client/http"

# GnListResolver::test
module GnListResolver
  # resolver_url = "http://gnresolver.globalnames.org/api/graphql".freeze
  # resolver_url = "http://localhost:8888/api/graphql".freeze
  # resolver_url = "http://localhost:8080/api/graphql".freeze
  resolver_url = "http://172.22.247.28:30436/api/graphql".freeze
  HTTP = GraphQL::Client::HTTP.new(resolver_url)
  SCHEMA = GraphQL::Client.load_schema(HTTP)
  CLIENT = GraphQL::Client.new(schema: SCHEMA, execute: HTTP)
  NAME_RESOLVERS_QUERY = CLIENT.parse <<-'GRAPHQL'
      query($names: [name!]!, $dataSourceIds: [Int!]) {
        nameResolver(names: $names, dataSourceIds: $dataSourceIds) {
          total suppliedId suppliedInput
          results {
            name { name }
            canonicalName { name }
            synonym
            matchType { kind score editDistance }
            taxonId classification { pathRanks }
            score { value parsingQuality }
          }
        }
      }
    GRAPHQL

  # Sends data to GN Resolver and collects results
  class Resolver
    def initialize(writer, data_source_id, resolver_url, stats)
      @stats = stats
      @processor = GnListResolver::ResultProcessor.new(writer, @stats)
      @ds_id = data_source_id
      @count = 0
      @current_data = {}
      @batch = 1000
    end

    def resolve(data)
      update_stats(data.size)
      block_given? ? process(data, &Proc.new) : process(data)
      wrap_up
      yield(@stats.stats) if block_given?
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
                         "#{@resolver_url}")
      yield
    end

    def collect_names(slice)
      @current_data = {}
      slice.each do |row|
        id = row[:id].strip
        @current_data[id] = row[:original]
        @processor.input[id] = { rank: row[:rank] }
      end
    end

    def variables(names)
      {
        dataSourceIds: [@ds_id],
        names: names.map do |name|
          { value: name[:name], suppliedId: name[:id] }
        end
      }
    end

    def remote_resolve(names)
      batch_start = Time.now
      res = CLIENT.query(NAME_RESOLVERS_QUERY, variables: variables(names))
      @processor.process(res.data.nameResolver, @current_data)
      update_batch_times(batch_start)
    end

    def update_batch_times(batch_start)
      s = @stats.stats
      s[:last_batches_time].shift if s[:last_batches_time].size > 2
      s[:last_batches_time] << Time.now - batch_start
      s[:resolution_span] = Time.now - s[:resolution_start]
    end

    def process_resolver_error(err, name)
      @stats.stats[:matches][7] += 1
      @stats.stats[:resolved_records] += 1
      GnListResolver.logger.error("Resolver broke on '#{name}': #{err.message}")
    end
  end
end
