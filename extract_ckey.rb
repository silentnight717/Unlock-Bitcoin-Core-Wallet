require 'io/console'

# ANSI color codes
LIGHT_PURPLE = "\e[95m"
LIGHT_RED = "\e[91m"
BLUE = "\e[34m"
LIGHT_GREEN = "\e[92m"  # Color for match count
RED = "\033[0;31m"
RESET = "\e[0m"

# Define control characters
SOH = "\x01"  # Start of Heading
EOT = "\x04"  # End of Transmission

def center_text(text)
  width = IO.console.winsize[1]
  text.center(width)
end

# Function to convert bytes to hexadecimal format
def bytes_to_hex(bytes)
  bytes.unpack1('H*')  # Return as a continuous hex string
end

# Display initial message
puts LIGHT_PURPLE + "Script for extracting the ckey from Bitcoin Core wallet" + RESET
puts

# Ask for the path of the input file
print "Enter the full path to your wallet dat file: "
file_path = gets.chomp

# Check if file exists
unless File.exist?(file_path)
  puts "#{RED}File not found!#{RESET}"
  exit
end

puts center_text(BLUE + "Extracting..." + RESET)
sleep(15) 
puts

# Read the file in binary mode
begin
  content = File.binread(file_path)
rescue => e
  puts "Error reading file: #{e.message}"
  exit
end

# Search for the specified pattern
pattern = /#{SOH}#{EOT}\s*ckey!(.*?)#{EOT}/m
matches = content.scan(pattern)

# Count of matches
match_count = 0

# Display found matches in hexadecimal format
if matches.empty?
  puts "No matches found."
else
  matches.each do |match|
    # Get the content after "ckey!"
    matched_content = match[0].strip
    hex_content = bytes_to_hex(matched_content.b) 

    if hex_content.length <= 200 && hex_content.length >= 70
      puts LIGHT_RED + "ckey!" + RESET + BLUE + hex_content + RESET
      match_count += 1  # Increment match count for each valid match
    end
  end
end

# Display the count of matches in light green
puts LIGHT_GREEN + "#{match_count} ckey matches found." + RESET

# Final message
puts LIGHT_PURPLE + "Process finished. Exiting..." + RESET
