describe GnListResolver::Stats do
  subject { GnListResolver::Stats }
  describe ".new" do
    it "creates an instance" do
      expect(subject.new).to be_kind_of GnListResolver::Stats
    end
  end
end
