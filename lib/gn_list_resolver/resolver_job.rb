# frozen_string_literal: true

module GnListResolver
  # Remote resolution for parallel jobs
  class ResolverJob
    GRAPHQL = GnGraphQL.new
    QUERY = GRAPHQL.client.parse(GRAPHQL.query)
    def initialize(names, batch_data, data_source_id)
      @names = names
      @batch_data = batch_data
      @data_source_id = data_source_id
      @stats = Stats.new
    end

    def run
      res = remote_resolve(@names)
      [res, @batch_data, @stats]
    end

    private

    def variables(names)
      { dataSourceIds: [@data_source_id],
        names: names.
          map { |name| { value: name[:name], suppliedId: name[:id] } } }
    end

    def remote_resolve(names)
      batch_start = Time.now
      res = GRAPHQL.client.query(QUERY, variables: variables(names))
      stats_add_batch_time(batch_start)
      res.data.name_resolver.responses
    end

    def stats_add_batch_time(batch_start)
      @stats.stats[:current_speed] = @names.size / (Time.now - batch_start)
      @stats.stats[:resolution][:completed_records] = @names.size
    end
  end
end
