# ANSI escape codes for colors
ORANGE = "\e[38;5;214m"  # Orange
LIGHT_GREEN = "\e[38;5;82m"  # Light Green
RESET = "\e[0m"  # Reset to default color

puts "#{ORANGE}Script for converting wallet dat file to binary#{RESET}"
puts ""

# Ask for the location of the input file
print "Enter the full path to your wallet dat: "
input_file_path = gets.chomp

# Ask for the output directory
print "Enter the full path where to save the output file: "
output_directory = gets.chomp

# Define the output file name
output_file_name = "converted_wallet.txt"
output_file_path = File.join(output_directory, output_file_name)

begin
  # Read the input file in binary mode
  input_file_content = File.binread(input_file_path)

  # Convert the content to binary representation
  binary_content = input_file_content.unpack1('B*')

  # Write the binary content to the output file
  File.open(output_file_path, 'wb') do |file|
    file.write(binary_content)
  end

  puts "#{LIGHT_GREEN}Conversion complete! Binary data saved to #{output_file_path}#{RESET}"
rescue StandardError => e
  puts "An error occurred: #{e.message}"
end
