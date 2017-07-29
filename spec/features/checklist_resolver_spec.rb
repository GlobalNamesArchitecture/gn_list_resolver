# frozen_string_literal: true

describe "features" do
  context "resolving variety of csv files" do
    %i[all_fields sciname sciname_auth sciname_rank csv_relaxed].each do |input|
      context input do
        it "resolves #{input}" do
          opts = { output: "/tmp/#{input}-processed.csv",
                   input: FILES[input],
                   data_source_id: 1,
                   skip_original: true,
                   debug: true }
          FileUtils.rm(opts[:output]) if File.exist?(opts[:output])
          GnListResolver.run(opts)
          expect(File.exist?(opts[:output])).to be true
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

  context "combining acceptedName output" do
    it "gives accepted name for all matches"
    # do
    #   opts = { output: "/tmp/output.csv",
    #            input: FILES[:sciname],
    #            data_source_id: 1, skip_original: true }
    #   GnListResolver.run(opts)
    #   CSV.open(opts[:output], col_sep: "\t", headers: true).each do |r|
    #     next unless r["matchedEditDistance"] == "0"
    #     expect(r["matchedName"].size).to be > 1
    #     expect(r["acceptedName"].size).to be > 1
    #   end
    #   FileUtils.rm(opts[:output])
    # end
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
    end

    it "breaks without alternative headers" do
      opts = { output: "/tmp/output.csv",
               input: FILES[:no_name],
               data_source_id: 1, skip_original: true }
      expect { GnListResolver.run(opts) }.to raise_error GnListResolverError
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
      expect(lines_num).to be 1007
      FileUtils.rm(opts[:output])
    end
  end
end
