# frozen_string_literal: true

# Namespace module for resolving lists with GN sources
module GnListResolver
  INPUT_MODE = "r:utf-8"
  OUTPUT_MODE = "w:utf-8"
  MATCH_TYPE_EMPTY = :EmptyMatch
  RESOLVER_URL = ENV["GN_RESOLVER_URL"] ||
                     "http://index.globalnames.org/api/graphql"

  MATCH_TYPES = {
      EmptyMatch: "No match",
      UuidLookup: "Uuid lookup",
      ExactMatch: "Exact match",
      ExactCanonicalMatch: "Exact canonical match",
      FuzzyCanonicalMatch: "Fuzzy canonical match",
      ExactPartialMatch: "Exact partial match",
      FuzzyPartialMatch: "Fuzzy partial match",
      ExactAbbreviatedMatch: "Exact abbreviated match",
      FuzzyAbbreviatedMatch: "Fuzzy abbreviated match",
      ExactPartialAbbreviatedMatch: "Exact partial abbreviated match",
      FuzzyPartialAbbreviatedMatch: "Fuzzy partial abbreviated match",
      Unknown: "Unknown"
  }.freeze
end
