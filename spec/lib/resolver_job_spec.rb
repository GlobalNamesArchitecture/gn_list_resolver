# frozen_string_literal: true

describe GnListResolver::ResolverJob do
  let(:names) do
    [{ id: "1", name: "Pomatomus saltator" },
     { id: "2", name: "Puma concolor" },
     { id: "3", name: "Monochamus galloprovincialis" },
     { id: "4", name: "Bubo bubo" },
     { id: "5", name: "Potentilla erecta" },
     { id: "6", name: "Parus major" }]
  end
  let(:opts) { GnListResolver.opts_struct({}) }
  subject { GnListResolver::ResolverJob }
  describe ".new" do
    it "creates instance" do
      expect(subject.new(names, {}, opts.data_source_id)).
             to be_kind_of GnListResolver::ResolverJob
    end
  end

  describe "#run" do
    it "resolves names" do
      job = subject.new(names, {}, opts.data_source_id)
      res = job.run
      expect(res[0]).to be_kind_of Array
      expect(res[0].size).to eq 6
      expect(res[1]).to be_kind_of Hash
      expect(res[1].empty?).to be true
      expect(res[2]).to be_kind_of GnListResolver::Stats
    end
  end
end
