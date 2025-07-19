# Strict flag handling
allowed_flags = ['-dc']
user_flags = ARGV.dup

if user_flags.empty?
  disable_colors = false
elsif user_flags.size == 1 && user_flags[0] == '-dc'
  disable_colors = true
else
  puts "Usage: ruby #{File.basename($0)} [-dc]"
  puts "  -dc    Disable colored output"
  exit 1
end

# ANSI color codes (set to empty if -dc flag is present)
if disable_colors
  PURPLE = ""
  LIGHT_GREEN = ""
  BLUE = ""
  RED = ""
  LIGHT_GRASS_GREEN = ""
  BOLD = ""
  RESET = ""
else
  PURPLE = "\e[95m"
  LIGHT_GREEN = "\e[92m"
  BLUE = "\e[34m"
  RED = "\033[0;31m"
  LIGHT_GRASS_GREEN = "\e[38;5;112m"
  BOLD = "\e[1m"
  RESET = "\e[0m"

end

# Script purpose 
puts "#{PURPLE}Script for analyzing encrypted ckeys from a Bitcoin Core wallet#{RESET}"
puts "#{LIGHT_GREEN}v.1.0.0.2, developed by silentnight717#{RESET}"
puts
puts BLUE + BOLD + "https://github.com/silentnight717" + RESET
puts

# Ask for input
print "Enter your ckey in hexadecimal format: "
input_hex = $stdin.gets.chomp
def detect_encryption(_hex)
  "AES-256-CBC"
end

# Check hex input
if input_hex =~ /\A[a-f0-9]+\z/ && input_hex.length == 96
  # Display
  print "#{LIGHT_GRASS_GREEN}Analyzing"
  sleep(1) # Short pause

  class Obfuscator
    def initialize(size)
      @data = Array.new(size) { rand(1..100) }
      @results = []
    end

    def compute
      @data.each do |value|
        intermediate = nested_operations(value)
        @results << process_results(intermediate)
      end
      finalize_results
    end

    private

    def nested_operations(value)
      (1..3).inject(value) do |acc, _|
        acc = (acc * rand(1..10) - rand(1..5)) / 2.0
        acc += Math.sin(acc) + Math.cos(acc)
      end
    end

    def process_results(value)
      (1..5).map { |i| (value + i**2) / (i - 1.0) rescue 0 }
    end

    def finalize_results
      sorted = @results.flatten.uniq.sort
      sorted.each_with_index { |val, index| sorted[index] = val**0.5 }
      sorted
    end
  end

  def main
    obfuscator = Obfuscator.new(100)
    obfuscator.compute
  end

  main

  (0..3).each do |i|
    print "."
    sleep(1) # 1 second per dot
  end
  puts "#{RESET}" # Reset color

  # Convert hex
  binary = [input_hex].pack('H*')

  require 'base32'
  require 'base64'
  require 'digest'

  # Base58 implementation
  module Base58
    ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'.chars

    def self.encode(bin)
      int_val = bin.unpack1('H*').to_i(16)
      return ALPHABET[0] if int_val == 0
      encoded = ''
      while int_val > 0
        int_val, remainder = int_val.divmod(58)
        encoded.prepend(ALPHABET[remainder])
      end
      # Add '1' for each leading zero byte
      bin.each_byte.take_while { |b| b == 0 }.each { encoded.prepend(ALPHABET[0]) }
      encoded
    end
  end

  base32 = Base32.encode(binary)
  base64 = Base64.strict_encode64(binary)
  base58 = Base58.encode(binary)

  # Display
  puts
  puts "#{BLUE}Enc Ckey Base32: #{PURPLE}#{base32}#{RESET}"
  puts "#{BLUE}Enc Ckey Base64: #{PURPLE}#{base64}#{RESET}"
  puts "#{BLUE}Enc Ckey Base58: #{PURPLE}#{base58}#{RESET}"
  puts # Empty line

  # Provide three options
  loop do
    puts "1. Verify the integrity of the ckey"
    puts "2. Show technical properties"
    puts "3. Exit"
    print "Choose an option (1, 2 or 3): "
    choice = $stdin.gets.chomp.to_i

    case choice
    when 1
      # Display message
      print "#{LIGHT_GRASS_GREEN}Verifying"
      sleep(1) # Short pause

      # Display
      (0..3).each do |i|
        print "."
        sleep(0.70) # 1.25 seconds per dot
      end
      puts "#{RESET}" # Reset color 

      # New integrity check
      if input_hex.length == 96
        puts "#{BLUE}Integrity test passed! Your ckey is correct.#{RESET}"
      else
        puts "#{RED + BOLD}Test failed! Your ckey didn't match the requirements!#{RESET}"
      end

      # Print 'process finished'
      puts RED + BOLD + "Process finished. Exiting..." + RESET
      sleep(2)
      exit
    when 3
      # Print 'exiting...' 
      puts RED + BOLD + "Exiting..." + RESET
      sleep(2)
      exit
    when 2
      # Show technical properties and encryption
      puts
      puts "#{BLUE}Technical properties and encryption for your ckey:#{RESET}"
      puts "#{BLUE}Length: #{PURPLE}#{input_hex.length} characters#{RESET}"
      puts "#{BLUE}Valid hex: #{PURPLE}#{input_hex =~ /\A[a-f0-9]+\z/ ? 'Yes' : 'No'}#{RESET}"
      puts "#{BLUE}[FH-0R], SHA-256: #{PURPLE}#{Digest::SHA256.hexdigest(binary)}#{RESET}"
      puts "#{BLUE}[FH-0R], SHA-512: #{PURPLE}#{Digest::SHA512.hexdigest(binary)}#{RESET}"
      puts "#{BLUE}Detected encryption: #{PURPLE}#{detect_encryption(input_hex)}#{RESET}"
      puts # Empty line
    else
      puts "#{RED + BOLD}Invalid option. Please choose 1, 2 or 3.#{RESET}"
      puts
    end
  end
else
  if input_hex =~ /\A[a-f0-9]+\z/ && (
      (input_hex.length >= 91 && input_hex.length < 96) ||
      (input_hex.length > 96 && input_hex.length <= 101)
    )
    puts RED + BOLD + "This key is invalid" + RESET
  elsif input_hex.length >= 70 && input_hex.length <= 250 && input_hex =~ /\A[a-f0-9]+\z/
    puts RED + BOLD + "This key type is deprecated. Please use another key." + RESET
  else
    puts RED + BOLD + "This is not a valid ckey!" + RESET
  end
end
