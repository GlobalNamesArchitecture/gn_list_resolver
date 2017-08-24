# frozen_string_literal: true

describe "features" do
  context "resolving variety of csv files" do
    %i[single_field empty_row all_fields sciname sciname_auth
       sciname_rank csv_relaxed].each do |input|
      context input do
        it "resolves #{input}" do
          opts = { output: "/tmp/#{input}-processed.csv",
                   input: FILES[input],
                   data_source_id: 1,
                   with_classification: [true, false].sample,
                   skip_original: [true, false].sample,
                   debug: true }
          GnListResolver.run(opts)
          expect(File.exist?(opts[:output])).to be true
          expect(uniform_rows?(opts[:output])).to be true
          FileUtils.rm(opts[:output])
        end
      end
    end
  end

  context "dealing with unexpected capitalizations" do
    it "normalizes capitalizations for pre-parsed fields" do
      opts = { output: "/tmp/output.csv",
               input: FILES[:all_caps],
               data_source_id: 1, skip_original: true }
      stats_caps = GnListResolver.run(opts)
      FileUtils.rm(opts[:output])
      opts = { output: "/tmp/output.csv",
               input: FILES[:all_fields],
               data_source_id: 1, skip_original: true }
      stats_nocaps = GnListResolver.run(opts)
      expect(stats_caps.stats[:matches]).to eq stats_nocaps.stats[:matches]
      FileUtils.rm(opts[:output])
    end
  end

  context "matchSize" do
    it "shows how many matches happen" do
      opts = { output: "/tmp/output.csv",
               input: FILES[:sciname],
               data_source_id: 1, skip_original: true }
      GnListResolver.run(opts)
      expect(File.exist?(opts[:output])).to be true
      res = CSV.open(opts[:output], col_sep: "\t", headers: true).map do |r|
        r["matchSize"]
      end.uniq.sort
      expect(res[0...3]).to eq %w[0 1 2]
      FileUtils.rm(opts[:output])
    end
  end

  context "combining acceptedName output" do
    it "gives accepted name for all matches" do
      opts = { output: "/tmp/output.csv",
               input: FILES[:sciname],
               data_source_id: 1, skip_original: true }
      GnListResolver.run(opts)
      CSV.open(opts[:output], col_sep: "\t", headers: true).each do |r|
        next unless r["synonymStatus"] == "true"
        expect(r["matchedName"].strip).to_not eq ""
        expect(r["acceptedName"].strip).to_not eq ""
        expect(r["matchedName"]).to_not eq r["acceptedName"]
      end
      FileUtils.rm(opts[:output])
    end
  end

  context "use alternative headers" do
    it "uses alternative headers for resolution" do
      opts = { output: "/tmp/output.csv",
               input: FILES[:no_name],
               data_source_id: 1, skip_original: true,
               alt_headers: %w[taxonID scientificName rank] }
      GnListResolver.run(opts)
      CSV.open(opts[:output], col_sep: "\t", headers: true).each do |r|
        next unless r["matchedEditDistance"] == "0"
        expect(r["matchedName"].size).to be > 1
        expect(r["acceptedName"].size).to be > 1
      end
      FileUtils.rm(opts[:output])
    end

    it "ignores original headers if alternative headers exit" do
      opts = { output: "/tmp/output.csv",
               input: FILES[:all_fields_tiny],
               data_source_id: 1,
               alt_headers: %w[taxonID scientificName] }
      GnListResolver.run(opts)
      CSV.open(opts[:output], col_sep: "\t", headers: true).each do |r|
        next unless r["matchedEditDistance"] == "0"
        expect(r["inputName"]).to eq "Animalia"
        expect(r["acceptedName"]).to eq "Animalia"
      end
      FileUtils.rm(opts[:output])
    end

    it "breaks without alternative headers" do
      opts = { output: "/tmp/output.csv",
               input: FILES[:no_name],
               data_source_id: 1, skip_original: true }
      expect { GnListResolver.run(opts) }.to raise_error GnListResolverError
      FileUtils.rm(opts[:output])
    end

    it "uses complex alternative headers" do
      opts = { output: "/tmp/output.csv",
               input: FILES[:fix_headers],
               data_source_id: 1, skip_original: true,
               alt_headers: %w[nil nil taxonID rank genus species nil
                               scientificNameAuthorship nil] }
      GnListResolver.run(opts)
      CSV.open(opts[:output], col_sep: "\t", headers: true).each do |r|
        next unless r["matchedEditDistance"] == "0"
        expect(r["matchedName"].size).to be > 1
        expect(r["acceptedName"].size).to be > 1
      end
      FileUtils.rm(opts[:output])
    end
  end

  context "stop trigger" do
    it "stops process with a 'STOP' command" do
      opts = { output: "/tmp/output.csv",
               input: FILES[:large],
               data_source_id: 1, skip_original: true }
      GnListResolver.run(opts) { "STOP" }
      lines_num = File.readlines(opts[:output]).size
      expect(lines_num).to be_between(1, 1010)
      FileUtils.rm(opts[:output])
    end
  end

  context "with classification" do
    it "creates classification if the option is true" do
      opts = { output: "/tmp/output.csv",
               input: FILES[:sciname],
               data_source_id: 1, skip_original: true,
               with_classification: true }
      GnListResolver.run(opts)
      classification_exists = false
      CSV.open(opts[:output], col_sep: "\t", headers: true).each do |r|
        if r["classification"] && r["classification"].split(", ").size > 1
          classification_exists = true
        end
      end
      expect(classification_exists).to be true
      FileUtils.rm(opts[:output])
    end
  end
end
