describe GnListResolver::Resolver do
  let(:original_fields) do
    %w(TaxonId kingdom subkingdom phylum subphylum superclass class subclass
       cohort superorder order suborder infraorder superfamily family
       subfamily tribe subtribe genus subgenus section species subspecies
       variety form ScientificNameAuthorship)
  end
  let(:stats) { GnListResolver::Stats.new }
  let(:skip_original) { false }
  let(:writer) do
    GnListResolver::Writer.new(io(FILES[:output], "w:utf-8"),
                           original_fields,
                           FILES[:output])
  end
  subject { GnListResolver::Resolver.new(writer, 1, stats) }

  describe ".new" do
    it "creates an instance" do
      expect(subject).to be_kind_of GnListResolver::Resolver
    end
  end

  describe "#resolve" do
    let(:data) do
      GnListResolver::Reader.new(io(FILES[:all_fields]),
                             FILES[:all_fields], true, [], stats).
        read
    end

    it "resolves names and writes them into output file" do
      expect(subject.resolve(data))
    end

    context "Resolver sends 500 error" do
      let(:data) do
        GnListResolver::Reader.new(io(FILES[:all_fields_tiny]),
                               FILES[:all_fields_tiny],
                               skip_original, [], stats).read
      end

      it "resolves data by every name" do
        allow(RestClient).to receive(:post) { raise RestClient::Exception }
        allow(GnListResolver).to receive(:log) {}
        expect(subject.resolve(data))
      end
    end
  end
end
