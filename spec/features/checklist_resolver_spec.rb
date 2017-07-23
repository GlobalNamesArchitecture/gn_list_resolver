describe "features" do
  context "resolving variety of csv files" do
    %i[all_fields sciname sciname_auth sciname_rank csv_relaxed].each do |input|
      context input do
        it "resolves #{input}" do
          opts = { output: "/tmp/#{input}-processed.csv",
                   input: FILES[input],
                   data_source_id: 1,
                   skip_original: true }
          FileUtils.rm(opts[:output]) if File.exist?(opts[:output])
          time = Time.now
          stats = GnListResolver.run(opts)
          GnListResolver.logger.warn(stats.stats)
          GnListResolver.logger.warn(format("Elapsed time: %ss",
                                            Time.now - time))
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
      stats_caps = GnCrossmap.run(opts)
      FileUtils.rm(opts[:output])
      opts = { output: "/tmp/output.csv",
               input: FILES[:all_fields],
               data_source_id: 1, skip_original: true }
      stats_nocaps = GnCrossmap.run(opts)
      expect(stats_caps.stats[:matches]).to eq stats_nocaps.stats[:matches]
      FileUtils.rm(opts[:output])
    end
  end

  context "combining acceptedName output" do
    it "gives accepted name for all matches" do
      pending("need to resolve CoL error with name \
               'Testechiniscus spitsbergensis (Scourfield, 1897)'")

      opts = { output: "/tmp/output.csv",
               input: FILES[:sciname],
               data_source_id: 1, skip_original: true }
      time = Time.now
      stats = GnListResolver.run(opts)
      GnListResolver.logger.warn(stats.stats)
      GnListResolver.logger.warn(format("Elapsed time: %ss", Time.now - time))
      CSV.open(opts[:output], col_sep: "\t", headers: true).each do |r|
        next unless r["matchedEditDistance"] == "0"
        expect(r["matchedName"].size).to be > 1
        expect(r["acceptedName"].size).to be > 1
        if r["synonymStatus"] == "true"
          expect(r["matchedName"]).to_not eq r["acceptedName"]
        else
          expect(r["matchedName"]).to eq r["acceptedName"]
        end
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
      time = Time.now
      stats =GnListResolver.run(opts)
      GnListResolver.logger.warn(stats.stats)
      GnListResolver.logger.warn(format("Elapsed time: %ss", Time.now - time))
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
      time = Time.now
      stats = GnListResolver.run(opts)
      GnListResolver.logger.warn(stats.stats)
      GnListResolver.logger.warn(format("Elapsed time: %ss", Time.now - time))
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
      time = Time.now
      stats = GnListResolver.run(opts)
      GnListResolver.logger.warn(stats.stats)
      GnListResolver.logger.warn(format("Elapsed time: %ss", Time.now - time))
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
               input: FILES[:sciname],
               data_source_id: 1, skip_original: true }
      time = Time.now
      stats = GnListResolver.run(opts) { "STOP" }
      GnListResolver.logger.warn(stats.stats)
      GnListResolver.logger.warn(format("Elapsed time: %s", Time.now - time))
      lines_num = File.readlines(opts[:output]).size
      expect(lines_num).to be 1521
      FileUtils.rm(opts[:output])
    end
  end
end
