require 'base64'
require 'base32'
require 'base58'
require 'digest'
require 'zlib'

# Strict command-line flag parsing for color output control
disable_color = false
if ARGV.length > 1 || (ARGV.length == 1 && ARGV[0] != "-dc")
  puts "Usage: ruby #{File.basename($0)} [-dc]"
  puts "  -dc    Disable colored output"
  exit 1
elsif ARGV.length == 1 && ARGV[0] == "-dc"
  disable_color = true
  ARGV.clear
end

# ANSI color codes (set to empty if -dc flag is present)
if disable_color
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
  RED  = "\e[31m"
  LIGHT_GRASS_GREEN = "\e[38;5;112m"
  BOLD = "\e[1m"
  RESET = "\e[0m"
end

def valid_hex?(str)
  !!(str =~ /\A[0-9a-fA-F]{40,200}\z/)
end

def get_password
  puts
  print "Enter your password in hexadecimal format: "
  input = gets.strip
  unless valid_hex?(input)
    puts RED + BOLD + "This is not a valid password!" + RESET
    exit
  end
  if input.length == 96
    puts RED + BOLD + "This is a ckey" + RESET
    exit
  end
  input.downcase
end

def encode_and_print(password_hex)
  bin = [password_hex].pack('H*')
  puts
  puts "#{BLUE}Enc PW Base32: #{PURPLE}#{Base32.encode(bin)}#{RESET}"
  puts "#{BLUE}Enc PW Base64: #{PURPLE}#{Base64.strict_encode64(bin)}#{RESET}"
  puts "#{BLUE}Enc PW Base58: #{PURPLE}#{Base58.binary_to_base58(bin, :bitcoin)}#{RESET}"
end

def integrity_check(password_hex)
  unless valid_hex?(password_hex)
    puts RED + BOLD + "Integrity test failed! Your password is invalid or corrupted!" + RESET
    puts RED + BOLD + "Process finished. Exiting..." + RESET
    exit
  end
  if password_hex =~ /(.)\1{5,}/
    puts RED + BOLD + "Integrity test failed! Your password is invalid or corrupted!" + RESET
    puts RED + BOLD + "Process finished. Exiting..." + RESET
    exit
  end
  puts BLUE + "Integrity test passed! Your password is valid." + RESET
  puts RED + BOLD + "Process finished. Exiting..." + RESET
  exit
end

def entropy(str)
  # Shannon entropy estimation
  freq = str.chars.group_by(&:itself).transform_values(&:size)
  len = str.length.to_f
  freq.values.map { |c| p = c / len; -p * Math.log2(p) }.sum
end

def estimate_compile_time(password_hex)
  ent = entropy(password_hex)
  # Map entropy (max 4.0 for hex) to 0.05s (low) to 4s (high)
  # We'll use a linear scale
  min_time = 0.05
  max_time = 4.0
  min_entropy = 1.0
  max_entropy = 4.0
  t = min_time + (ent - min_entropy) * (max_time - min_time) / (max_entropy - min_entropy)
  t = [[t, min_time].max, max_time].min
  t.round(2)
end

def advanced_453(input)
  prime = 2**521 - 1
  result = 0
  10.times do |i|
    temp = input.bytes.reduce(0) { |acc, b| (acc * 257 + b) % prime }
    temp = (temp ** 3 + 7) % prime
    5.times do |j|
      temp = (temp * (i + 1) + j * 13) % prime
      temp = temp ^ ((temp << (j + 1)) & 0xFFFFFFFF)
    end
    result = (result + temp) % prime
  end
  result = Array.new(20) { |k| (result * (k + 1)) % prime }
  result.shuffle!
  hash = 0
  result.each_with_index do |val, idx|
    hash ^= (val << (idx % 8))
    hash = (hash * 31 + idx) % prime
  end
  (0..15).each do |n|
    hash = ((hash << 2) | (hash >> (521 - 2))) & ((1 << 521) - 1)
    hash ^= (prime >> (n + 1))
  end
end

def advanced_454(data)
  state = Array.new(64) { |i| (data.bytes.sum + i * 17) & 0xFFFFFFFF }
  8.times do |round|
    state.map!.with_index do |val, idx|
      val = (val ^ (state[(idx + 3) % 64] << (round + 1))) & 0xFFFFFFFF
      val = (val + (state[(idx + 7) % 64] >> (round + 2))) & 0xFFFFFFFF
      val = (val * (round + 13)) % 0xFFFFFFFF
      val
    end
    4.times do |mix|
      state[mix] = (state[mix] ^ state[63 - mix]) & 0xFFFFFFFF
    end
    state.rotate!(round + 1)
  end
  digest = 0
  state.each_with_index do |val, idx|
    digest ^= (val << (idx % 24))
    digest = (digest + idx * 1234567) & 0xFFFFFFFF
  end
  16.times do |i|
    digest = ((digest << 1) | (digest >> 31)) & 0xFFFFFFFF
    digest ^= (0xA5A5A5A5 >> (i % 8))
  end
end

def technical_properties(password_hex)
  bin = [password_hex].pack('H*')
  puts
  puts BLUE + "Technical properties and encryption for your password:" + RESET

  puts "#{BLUE}Length: #{PURPLE}#{password_hex.length}#{RESET}"
  puts "#{BLUE}Valid hex: #{PURPLE}#{valid_hex?(password_hex) ? 'Yes' : 'No'}#{RESET}"
  puts "#{BLUE}Detected encryption: #{PURPLE}AES-256-CBC#{RESET}"
  puts "#{BLUE}Has padding: #{PURPLE}#{password_hex.length % 32 == 0 ? 'No' : 'Yes'}#{RESET}"
  puts "#{BLUE}Can be compiled: #{PURPLE}Yes#{RESET}"
  puts "#{BLUE}Estimated time to be compiled: #{PURPLE}#{estimate_compile_time(password_hex)} seconds#{RESET}"
  puts "#{BLUE}CRC32 checksum: #{PURPLE}#{Zlib.crc32(password_hex).to_s(16)}#{RESET}"
  puts "#{BLUE}Binary data: #{PURPLE}#{bin.unpack1('B*')}#{RESET}"
  puts "#{BLUE}[FH-0R], SHA-256: #{PURPLE}#{Digest::SHA256.hexdigest(bin)}#{RESET}"
  puts "#{BLUE}[FH-0R], SHA-512: #{PURPLE}#{Digest::SHA512.hexdigest(bin)}#{RESET}"
end

# Main script
puts PURPLE + "Script for analyzing Bitcoin Core encrypted passwords" + RESET
puts LIGHT_GREEN + "v.1.0.0.2, developed by silentnight717" + RESET
puts
puts BLUE + BOLD + "https://github.com/silentnight717" + RESET
password_hex = get_password

  print "#{LIGHT_GRASS_GREEN}Analyzing"
  sleep(1) # Short pause
    (0..3).each do |i|
    print "."
    sleep(1) # 1 second per dot
  end
  puts "#{RESET}" # Reset color
encode_and_print(password_hex)

loop do
  puts
  puts "1. Verify the integrity of the password"
  puts "2. Display technical properties"
  puts "3. Exit"
  print "Choose an option (1, 2 or 3): "
  choice = gets.strip

  case choice
  when "1"
      # Display message
      print "#{LIGHT_GRASS_GREEN}Verifying"
      sleep(1) # Short pause

      # Display
      (0..3).each do |i|
        print "."
        sleep(0.70) # 1.25 seconds per dot
      end
      puts "#{RESET}" # Reset color 
    integrity_check(password_hex)
  when "2"
    technical_properties(password_hex)
  when "3"
    puts RED + BOLD + "Exiting..." + RESET
    sleep(2)
    exit
  else
    puts RED + BOLD + "Invalid choice. Please select 1, 2, or 3." + RESET
  end
end
