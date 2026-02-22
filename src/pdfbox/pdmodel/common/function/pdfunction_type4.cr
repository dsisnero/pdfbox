# Type 4 (PostScript calculator) function in a PDF document
# Corresponds to PDFunctionType4 in Apache PDFBox
require "./type4"

module Pdfbox::Pdmodel::Common::Function
  class PDFunctionType4 < PDFunction
    @instructions : Type4::InstructionSequence

    # Constructor.
    def initialize(function : Cos::Base)
      super(function)
      stream = pd_stream
      raise "PDFunctionType4 requires a stream" unless stream
      bytes = stream.to_byte_array
      string = String.new(bytes, "ISO-8859-1")
      @instructions = Type4::InstructionSequenceBuilder.parse(string)
    end

    # Returns the function type (4 for PostScript calculator)
    def function_type : Int32
      4
    end

    # Evaluate the PostScript calculator function
    def eval(input : Array(Float32)) : Array(Float32)
      # Setup the input values
      operators = Type4::Operators.new
      context = Type4::ExecutionContext.new(operators)

      input.each_with_index do |value, i|
        domain = domain_for_input(i)
        clipped_value = clip_to_range(value, domain.min.to_f32, domain.max.to_f32)
        context.stack.push(clipped_value)
      end

      # Execute the type 4 function.
      @instructions.execute(context)

      # Extract the output values
      number_of_output_values = number_of_output_parameters
      number_of_actual_output_values = context.stack.size
      if number_of_actual_output_values < number_of_output_values
        raise "The type 4 function returned #{number_of_actual_output_values} values but the Range entry indicates that #{number_of_output_values} values be returned."
      end

      output_values = Array(Float32).new(number_of_output_values, 0.0_f32)
      (number_of_output_values - 1).downto(0) do |i|
        range = range_for_output(i)
        output_value = context.pop_real
        output_values[i] = clip_to_range(output_value, range.min.to_f32, range.max.to_f32)
      end

      output_values
    end

    def to_s : String
      "FunctionType4{PostScript calculator}"
    end
  end
end
