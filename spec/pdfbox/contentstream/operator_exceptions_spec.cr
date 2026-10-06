require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/operator/MissingOperandException.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/contentstream/operator/state/EmptyGraphicsStackException.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/MissingResourceException.java
#
# Ports the content-stream / pdmodel exception types (all extend IOException in
# Java, i.e. IO::Error in Crystal) with their exact messages.

module Pdfbox::ContentStream
  describe MissingOperandException do
    it "is an IO::Error with the Java message" do
      operator = Pdfbox::ContentStream::Operator.new("Tm")
      operands = [Pdfbox::Cos::Float.new(1.0_f32)]
      ex = MissingOperandException.new(operator, operands)
      ex.should be_a(::IO::Error)
      ex.message.should eq("Operator Tm has too few operands: [#{operands.first}]")
    end
  end

  describe EmptyGraphicsStackException do
    it "is an IO::Error with the Java message" do
      ex = EmptyGraphicsStackException.new
      ex.should be_a(::IO::Error)
      ex.message.should eq("Cannot execute restore, the graphics stack is empty")
    end
  end
end

module Pdfbox::Pdmodel
  describe MissingResourceException do
    it "is an IO::Error carrying the message" do
      ex = MissingResourceException.new("Could not find resource 'X'")
      ex.should be_a(::IO::Error)
      ex.message.should eq("Could not find resource 'X'")
    end
  end
end
