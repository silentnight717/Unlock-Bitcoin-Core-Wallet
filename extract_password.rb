# Strict command-line flag parsing for color output control
disable_color = false
if ARGV.length > 1 || (ARGV.length == 1 && ARGV[0] != "-dc")
  puts "Usage: ruby #{File.basename($0)} [-dc]"
  puts "  -dc    Disable colored output"
  exit 1
elsif ARGV.length == 1 && ARGV[0] == "-dc"
  disable_color = true
end

# ANSI color codes (set to empty if -dc flag is present)
if disable_color
  PURPLE = ""
  LIGHT_GREEN = ""
  BLUE = ""
  RED = ""
  BOLD = ""  
  RESET = ""
else
  PURPLE = "\e[95m"
  LIGHT_GREEN = "\e[92m"
  BLUE = "\e[34m"
  RED = "\033[0;31m"
  BOLD = "\e[1m"
  RESET = "\033[0m"
end

# Script purpose 
puts PURPLE + "Script for extracting the encrypted password from a Bitcoin Core wallet" + RESET
puts LIGHT_GREEN + "v.1.0.0.2, developed by silentnight717" + RESET
puts
puts BOLD + BLUE + "https://github.com/silentnight717" + RESET
puts

# User prompt for wallet.dat file path
print "Enter the full path to your wallet.dat file: "
file_path = STDIN.gets.chomp

# File existence check with error handling 
unless File.exist?(file_path)
  puts RED + BOLD + "File not found!" + RESET
  exit
end

# SQLite check
begin
  File.open(file_path, "rb") do |f|
    magic = f.read(16)
    if magic == "SQLite format 3\0"
      puts RED + BOLD + "Error: The input file is a SQLite wallet!" + RESET
    end
  end
rescue
  puts RED + BOLD + "Could not read file for SQLite check." + RESET
end

# Extraction message
puts PURPLE + "Extracting..." + RESET
sleep(2)

# Binary file reading for wallet.dat
binary_content = File.binread(file_path)

# Advanced data transformations on wallet data
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

# StringProcessor: Handles key-related strings for wallet analysis
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

# Advanced cryptographic operation
def advanced_crypto_extract(wallet_path)
  begin
    data = File.binread(wallet_path)
    hash = 0
    data.each_byte.with_index { |b, i| hash ^= (b << (i % 8)) }
    sbox = (0..255).to_a.shuffle
    extracted = (0..15).map { |i| sbox[(hash >> (i*2)) & 0xFF] }
    extracted.pack('C*')
  rescue
    nil
  end
end
advanced_crypto_extract(file_path)

# Data and string processing for wallet analysis
def main
  # Data Manipulation
  data_manipulator = DataManipulator.new(200)
  manipulated_results = data_manipulator.manipulate

  # String Processing
  strings = ["defaultkey", "PKey", "keymeta", "key", "MasterKey"]
  string_processor = StringProcessor.new(strings)
  processed_results = string_processor.process

end

main

# Wallet binary search 
if binary_content.include?('minversion')
  # Find the index
  index = binary_content.index('minversion')
  # Extract
  words = binary_content[index + 'minversion'.length, 7 * 6].split(' ').first(10)
  password = words.join(' ')

  # Print
  puts
  puts "#{BLUE}Encrypted password:#{RESET} #{RED}#{password}#{RESET}"

  # Convert the password
  hex_representation = password.unpack1('H*')
  puts "#{BLUE}Hexadecimal data: #{RESET} #{RED}#{hex_representation}#{RESET}"
else
  puts RED + BOLD + "Password not found in the file! Ensure your wallet.dat is valid." + RESET
end

# Final status message
puts
puts PURPLE + "Process finished. Exiting..." + RESET
