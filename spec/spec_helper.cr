require "spec"
require "log"

Log.setup_from_env

module SpecPaths
  private def self.detect_project_root : Path
    current = Path[__DIR__].expand
    loop do
      return current if File.exists?((current / "shard.yml").to_s)
      parent = current.parent
      raise "Could not detect project root from #{__DIR__}" if parent == current
      current = parent
    end
  end

  PROJECT_ROOT = detect_project_root
  SPEC_PATH    = PROJECT_ROOT / "spec"
  VENDOR_PATH  = PROJECT_ROOT / "vendor"

  # Resolves a relative path from project root, searching ancestor roots as fallback.
  def self.resolve(relative : String) : String
    current = PROJECT_ROOT
    loop do
      candidate = (current / relative).to_s
      return candidate if File.exists?(candidate)
      parent = current.parent
      break if parent == current
      current = parent
    end
    raise "Fixture not found: #{relative}"
  end
end

require "../src/pdfbox"
