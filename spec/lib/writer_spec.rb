describe GnListResolver::Writer do
  let(:output) { io(FILES[:output], "w:utf-8") }
  subject { GnListResolver::Writer.new(output, [], FILES[:output]) }
end
