# frozen_string_literal: true

module GnListResolver
  # Collects statistics about list resolving process
  class Stats
    attr_accessor :stats

    def initialize
      @stats = { status: :init, total_records: 0, ingested_records: 0,
                 resolved_records: 0, ingestion_span: nil,
                 resolution_span: nil, ingestion_start: nil,
                 resolution_start: nil, resolution_stop: nil,
                 last_batches_time: [], matches: Hash.new(0),
                 errors: [] }
    end
  end
end
