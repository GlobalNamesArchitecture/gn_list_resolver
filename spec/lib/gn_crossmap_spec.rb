describe GnCrossmap do
  subject { GnCrossmap }

  describe ".version" do
    it "has a version number" do
      expect(subject::VERSION).to match(/^\d+\.\d+\.\d+$/)
      expect(subject.version).to match(/^\d+\.\d+\.\d+$/)
    end
  end

  describe ".run" do
    let(:input) { FILES[:sciname_auth] }
    let(:output) { FILES[:output] }
    let(:data_source_id) { 1 }
    let(:skip_original) { false }
    it "runs crossmapping" do
      expect(subject.run(input, output, data_source_id, skip_original)).
        to eq output
    end

    context "spaces in fields" do
      let(:input) { FILES[:spaces_in_fields] }
      it "suppose to work even when fields have additional spaces" do
        expect(subject.run(input, output, data_source_id, skip_original)).
          to eq output
        expect(File.readlines(output).size).to be > 100
      end
    end

    context "original fields flag" do
      it "leaves only taxonID when skip_original is true" do
        i = File.open(input)
        expect(i.first).to include("taxonRank")
        i.close
        subject.run(input, output, data_source_id, true)
        o = File.open(output)
        expect(o.first).to_not include("taxonRank")
        o.close
      end

      it "keeps original fields when keep_original is true" do
        i = File.open(input)
        expect(i.first).to include("taxonRank")
        i.close
        subject.run(input, output, data_source_id, skip_original)
        o = File.open(output)
        expect(o.first).to include("taxonRank")
        o.close
      end
    end

    context "no taxonid" do
      let(:input) { FILES[:no_taxonid] }
      it "raises an error" do
        expect { subject.run(input, output, data_source_id, skip_original) }.
          to raise_error GnCrossmapError
      end
    end
  end
end
