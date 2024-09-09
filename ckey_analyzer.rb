# ANSI color codes
LIGHT_ORANGE = "\e[38;5;214m"
RED = "\e[31m"
LIGHT_GRASS_GREEN = "\e[38;5;112m"
BLUE = "\e[34m"
PURPLE = "\e[35m"
RESET = "\e[0m"

# Display the text
puts "#{LIGHT_ORANGE}Script for analyzing the extracted ckey#{RESET}"
puts # Empty line

# Ask for input
print "Enter your ckey in hexadecimal format: "
input_hex = gets.chomp

# Check if the input hex meets the specified requirements
if input_hex =~ /\A[a-f0-9]+\z/ && input_hex.length >= 70 && input_hex.length <= 250
  # Display 'Analyzing'
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

  # Animation
  (0..3).each do |i|
    print "."
    sleep(3.75) # Sleep
  end
  puts "#{RESET}" # Reset color

  # Convert hex
  binary = [input_hex].pack('H*')
  ascii = binary.unpack('C*').map { |c| c.chr }.join

  # Display
  puts "#{BLUE}Your encrypted ckey displayed in ASCII: #{PURPLE}#{ascii}#{RESET}"
  puts "#{BLUE}(If the characters are scattered, it's only the terminal's fault to display them in that way) #{RESET}"
  puts # Empty line

  # Provide two options
  loop do
    puts "1. Verify the integrity of the ckey"
    puts "2. Exit"
    print "Choose an option (1 or 2): "
    choice = gets.chomp.to_i

    case choice
    when 1
      # Display 'Verifying'
      print "#{LIGHT_GRASS_GREEN}Verifying"
      sleep(1) # Short pause

      # Animation
      (0..3).each do |i|
        print "."
        sleep(6.25) # Sleep
      end
      puts "#{RESET}" # Reset color 
      
      # Check
      if input_hex.scan('0').length >= 3
        puts "#{BLUE}Integrity test passed! Your ckey is correct!#{RESET}"
      else
        puts "#{RED}Test failed! Your ckey didn't match the requirements!#{RESET}"
      end

      # Print 'process finished'
      puts "#{RED}Process finished. Exiting...#{RESET}"
      sleep(2)
      exit
    when 2
      # Print 'exiting...' 
      puts "#{RED}Exiting...#{RESET}"
      sleep(2)
      exit
    else
      puts "#{RED}Invalid option. Please choose 1 or 2.#{RESET}"
    end
  end
else
  # Display
  puts "#{RED}This is not a valid ckey!#{RESET}"
end
