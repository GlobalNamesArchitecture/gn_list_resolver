# frozen_string_literal: true

module GnListResolver
  # GraphQL client for gnindex API
  class GnGraphQL
    attr_reader :client, :query

    def initialize
      http = GraphQL::Client::HTTP.new(RESOLVER_URL)
      schema = GraphQL::Client.load_schema(http)
      @client = GraphQL::Client.new(schema: schema, execute: http)
      @query = <<~GRAPHQL_QUERY
        query($names: [name!]!, $dataSourceIds: [Int!]) {
          nameResolver(names: $names, dataSourceIds: $dataSourceIds,
                       advancedResolution: true) {
            responses {
              total suppliedId suppliedInput
              results {
                name { value }
                canonicalName { value }
                resultsPerDataSource {
                  results {
                    acceptedName { name { value } }
                    synonym
                    matchType { kind score verbatimEditDistance }
                    taxonId
                    classification { path pathRanks }
                    score { value parsingQuality }
                  }
                }
              }
            }
          }
        }
      GRAPHQL_QUERY
    end
  end
end
