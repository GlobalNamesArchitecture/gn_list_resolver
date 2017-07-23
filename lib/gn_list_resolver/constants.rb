# frozen_string_literal: true

# Namespace module for resolving lists with GN sources
module GnListResolver
  INPUT_MODE = "r:utf-8"
  OUTPUT_MODE = "w:utf-8"
  MATCH_TYPE_EMPTY = "EmptyMatch"
  RESOLVER_URL = ENV["GN_RESOLVER_URL"] ||
                 "http://index-api.globalnames.org/api/graphql"
end
