# frozen_string_literal: true

files_path = File.expand_path("../files", __dir__)

def io(file, mode = "r:utf-8")
  fd = IO.sysopen(file, mode)
  IO.new(fd, mode: mode)
end

FILES = {
  all_caps: "#{files_path}/all-caps.csv",
  all_fields: "#{files_path}/all-fields-semicolon.csv",
  all_fields_tiny: "#{files_path}/all-fields-tiny.csv",
  csv_relaxed: "#{files_path}/csv-relaxed.csv",
  fix_headers: "#{files_path}/fix-headers.csv",
  no_taxonid: "#{files_path}/no-taxonid.csv",
  no_name: "#{files_path}/no-name.csv",
  sciname: "#{files_path}/simple-comma.csv",
  sciname_auth: "#{files_path}/authorship-tab.csv",
  sciname_rank: "#{files_path}/taxon-rank-tab.csv",
  spaces_in_fields: "#{files_path}/spaces-in-fields.csv",
  with_errors: "#{files_path}/with-errors.csv",
  output: "/tmp/output.csv"
}.freeze
