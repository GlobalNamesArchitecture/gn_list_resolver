module GnCrossmap
  # Saves output from GN Resolver to disk
  class Writer
    def initialize(output_io, original_fields, output_name)
      @output_io = output_io
      @output_fields = output_fields(original_fields)
      @output = CSV.new(@output_io)
      @output << @output_fields
      @output_name = output_name
      GnCrossmap.log("Open output to #{@output_name}")
    end

    def write(record)
      @output << record
    end

    def close
      GnCrossmap.log("Close #{@output_name}")
      @output_io.close
    end

    private

    def output_fields(original_fields)
      original_fields + [:matchedType, :inputName, :matchedName,
                         :matchedCanonicalForm, :inputRank, :matchedRank,
                         :synonymStatus, :acceptedName, :matchedEditDistance,
                         :marchedScore, :matchTaxonID]
    end
  end
end
