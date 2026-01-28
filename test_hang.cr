require "./src/pdfbox"

pdf_path = File.expand_path("./spec/resources/pdfbox/pdparser/PDFBOX-3947-670064.pdf", __DIR__)
puts "Testing PDF: #{pdf_path}"
puts "File exists: #{File.exists?(pdf_path)}"

# Set up logging - use warn to reduce noise
Log.setup(:warn)

begin
  # Try to load with lenient mode (enables brute-force parser)
  puts "Attempting to load PDF with lenient mode (brute-force fallback)..."
  start_time = Time.instant
  doc = Pdfbox::Pdmodel::Document.load(pdf_path, lenient: true)
  elapsed = Time.instant - start_time
  puts "Success! Loaded PDF in #{elapsed.total_seconds.round(2)} seconds"

  puts "Document version: #{doc.version}"
  puts "Page count: #{doc.page_count}"

  doc.close if doc.responds_to?(:close)
rescue ex
  puts "Exception: #{ex.class}: #{ex.message}"
  ex.backtrace.each { |line| puts "  #{line}" }
end
