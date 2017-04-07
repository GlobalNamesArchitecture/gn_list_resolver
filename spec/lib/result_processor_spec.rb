describe GnListResolver::ResultProcessor do
  let(:writer) { GnListResolver::Writer.new(FILES[:output]) }
  subject { GnListResolver::ResultProcessor.new(writer) }
end
