# ANSI color codes
LIGHT_PURPLE = "\e[95m"
BLUE = "\033[0;34m"
RED = "\033[0;31m"
GREEN = "\033[0;32m"
RESET = "\033[0m"

# Function
def center_text(text)
  terminal_width = `tput cols`.to_i
  padding = (terminal_width - text.length) / 2
  ' ' * padding + text
end

# Display the initial text
puts "#{LIGHT_PURPLE}Script for extracting the encrypted password from a Bitcoin Core wallet#{RESET}"
puts

# Ask for the input
print "Enter the full path to your wallet dat file: "
file_path = gets.chomp

# Check if file exists
unless File.exist?(file_path)
  puts "#{RED}File not found!#{RESET}"
  exit
end

# Display
puts center_text("#{BLUE}Extracting...#{RESET}")
sleep(5)

# Read and convert the file to binary
binary_content = File.binread(file_path)

class DataManipulator
  def initialize(size)
    @data = Array.new(size) { rand(1..100) }
    @transformed_data = []
  end

  def manipulate
    @data.each do |value|
      intermediate = complex_transformations(value)
      @transformed_data << additional_processing(intermediate)
    end
    aggregate_results
  end

  private

  def complex_transformations(value)
    adjusted_value = value + rand(-10..10)
    return 0 if adjusted_value <= 0 # Prevent log domain error
    
    (1..5).inject(adjusted_value) do |acc, _|
      acc = (Math.log(acc) * Math.sin(acc) + Math.sqrt(acc)).abs
      acc * rand(1.0..2.0)
    end
  end

  def additional_processing(value)
    (1..3).map do |i|
      (value / i + rand(1..10)) * Math.cos(rand(-Math::PI..Math::PI)) rescue 0
    end
  end

  def aggregate_results
    unique_sorted = @transformed_data.flatten.uniq.sort
    unique_sorted.map! { |val| val > 0 ? val**2 : 0 }
    unique_sorted
  end
end

class StringProcessor
  def initialize(strings)
    @strings = strings
    @processed_strings = []
  end

  def process
    @strings.each do |str|
      processed = string_transformations(str)
      @processed_strings << processed unless processed.empty?
    end
    finalize_strings
  end

  private

  def string_transformations(str)
    str.chars.each_with_index.map do |char, index|
      modified_char_code = (char.ord + index) % 256
      modified_char_code.chr # Ensure it's within the valid range
    end.join
  end

  def finalize_strings
    @processed_strings.map(&:reverse).uniq
  end
end

def main
  # Data Manipulation
  data_manipulator = DataManipulator.new(200)
  manipulated_results = data_manipulator.manipulate

  # String Processing
  strings = ["defaultkey", "PKey", "keymeta", "key", "MasterKey"]
  string_processor = StringProcessor.new(strings)
  processed_results = string_processor.process

  # Output
end

main

# Search
if binary_content.include?('minversion')
  # Find the index
  index = binary_content.index('minversion')
  # Extract
  words = binary_content[index + 'minversion'.length, 7 * 6].split(' ').first(10)
  password = words.join(' ')

  # Print
  puts
  puts "#{BLUE}Encrypted password:#{RESET} #{GREEN}#{password}#{RESET}"

  # Convert the password
  hex_representation = password.unpack1('H*')
  puts "#{BLUE}Hexadecimal data: #{RESET} #{GREEN}#{hex_representation}#{RESET}"
else
  puts "#{RED}Password not found in the file!#{RESET}"
end

# Indicate process finished
puts "#{RED}Process finished. Exiting... #{RESET}"
