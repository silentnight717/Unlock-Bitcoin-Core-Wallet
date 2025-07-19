require 'io/console'

# ANSI color codes
PURPLE = "\e[95m"
LIGHT_GREEN = "\e[92m"
BLUE = "\e[34m"
RED = "\033[0;31m"
LIGHT_RED = "\e[91m"
BOLD = "\e[1m"
RESET = "\e[0m"


def bytes_to_hex(bytes)
  bytes.unpack1('H*')
end

def usage
  puts PURPLE + "Script for extracting encrypted private keys from a Bitcoin Core wallet" + RESET
  puts LIGHT_GREEN + "v.1.0.0.2, developed by silentnight717" + RESET
  puts
  puts BOLD + BLUE + "https://github.com/silentnight717" + RESET
  puts
  puts <<~USAGE
    Usage: #{RED + BOLD}ruby#{RESET} #{BOLD}extract_ckey.rb#{RESET} [options]

    #{PURPLE + BOLD}Wallet:#{RESET}
      #{LIGHT_GREEN}-fwp#{RESET}     --full-wallet-path <path>    Specify the full path to the wallet.dat file
      #{LIGHT_GREEN}-ro#{RESET}      --read-only                  Open the wallet as read only (useful for not damaging the wallet)

    #{PURPLE + BOLD}Other:#{RESET}
      #{LIGHT_GREEN}-of#{RESET}      --old-formatting             Display the previous formatting method for ckeys
      #{LIGHT_GREEN}-sik#{RESET}     --skip-incorrect-keys        Skip ckeys that are incorrect
      #{LIGHT_GREEN}-dc#{RESET}      --disable-colors             Disable colored output for extraction

    #{PURPLE + BOLD}Help:#{RESET}
      #{LIGHT_GREEN}-h#{RESET}       --help                       Show this usage message
  USAGE
end

# Manual argument parsing
args = ARGV.dup
flags = {
  help: false,
  wallet_path: nil,
  read_only: false,
  old_formatting: false,
  skip_incorrect_keys: false,
  disable_colors: false
}
seen_flags = {}

def get_flag_value(args, seen_flags, *names)
  idx = args.find_index { |a| names.include?(a) }
  if idx
    flag = args[idx]
    if seen_flags[flag]
      puts RED + BOLD + "Duplicate flag detected: #{flag}" + RESET
      exit 1
    end
    seen_flags[flag] = true
    if args[idx+1].nil? || args[idx+1].start_with?('-')
      puts RED + BOLD + "You must specify the wallet path!" + RESET
      exit 1
    end
    val = args[idx+1]
    args.slice!(idx,2)
    val
  else
    nil
  end
end

def get_bool_flag(args, seen_flags, *names)
  names.each do |name|
    if (idx = args.index(name))
      if seen_flags[name]
        puts RED + BOLD + "Duplicate flag detected: #{name}" + RESET
        exit 1
      end
      seen_flags[name] = true
      args.delete_at(idx)
      return true
    end
  end
  false
end

if args.include?('-h') || args.include?('--help')
  if args.length > 1
    puts RED + BOLD + "Something is not right! Check again your syntax." + RESET
    exit 1
  else
    usage
    exit
  end
end

flags[:wallet_path] = get_flag_value(args, seen_flags, '-fwp', '--full-wallet-path')
flags[:read_only] = get_bool_flag(args, seen_flags, '-ro', '--read-only')
flags[:old_formatting] = get_bool_flag(args, seen_flags, '-of', '--old-formatting')
flags[:skip_incorrect_keys] = get_bool_flag(args, seen_flags, '-sik', '--skip-incorrect-keys')
flags[:disable_colors] = get_bool_flag(args, seen_flags, '-dc', '--disable-colors')

if ARGV.empty? && flags[:wallet_path].nil?
  puts "#{RED + BOLD}Please use the -h option for usage information.#{RESET}"
  exit 1
end

if flags[:wallet_path].nil?
  puts "#{RED + BOLD}You must specify the wallet path!#{RESET}"
  exit 1
end

if flags[:read_only] && flags[:wallet_path].nil?
  puts "#{RED + BOLD}-ro/--read-only must be used with -fwp/--full-wallet-path!#{RESET}"
  exit 1
end

if !args.empty?
  puts "#{RED + BOLD}Unknown or invalid argument(s): #{args.join(' ')}#{RESET}"
  puts "#{RED + BOLD}Please use the -h option for usage information.#{RESET}"
  exit 1
end

if flags[:disable_colors]
  PURPLE.replace('')
  LIGHT_RED.replace('')
  BLUE.replace('')
  LIGHT_GREEN.replace('')
  RED.replace('')
  RESET.replace('')
end

unless File.exist?(flags[:wallet_path].to_s)
  puts "#{RED + BOLD}File not found!#{RESET}"
  exit
end

# SQLite check
def sqlite_file?(filename)
  File.open(filename, "rb") do |f|
    header = f.read(16)
    header == "SQLite format 3\0"
  end
rescue
  false
end

if sqlite_file?(flags[:wallet_path].to_s)
  puts "#{RED + BOLD}Error: The input file is a SQLite wallet!#{RESET}"
end

# Print "Extracting..."
puts PURPLE + "Extracting..." + RESET
sleep(1)
puts

if flags[:old_formatting]
  begin
    content = File.binread(flags[:wallet_path])
  rescue => e
    puts RED + BOLD + "Error reading file: #{e.message}" + RESET
    exit
  end

  SOH = "\x01"
  EOT = "\x04"
  pattern = /#{SOH}#{EOT}\s*ckey!(.*?)#{EOT}/m
  matches = content.scan(pattern)
  match_count = 0

  if matches.empty?
    puts RED + BOLD + "No matches found." + RESET
  else
    matches.each do |match|
      matched_content = match[0].strip
      hex_content = bytes_to_hex(matched_content.b)

      if flags[:skip_incorrect_keys] && hex_content =~ /(.)\1{4,}/
        next
      end

      if hex_content.length <= 200 && hex_content.length >= 70
        puts LIGHT_RED + BOLD + "ckey!" + RESET + BLUE + hex_content + RESET
        match_count += 1
      end
    end
  end

  puts LIGHT_GREEN + "#{match_count} ckey matches found." + RESET
else
  match_count = 0
  File.open(flags[:wallet_path], "rb") do |wallet|
    wallet_size = wallet.size
    wallet.rewind
    data = wallet.read

    offset = 0
    while offset < wallet_size - 4
      if data[offset,4] == "ckey"
        ckey_offset = offset
        start = ckey_offset - 52
        if start >= 0 && (start + 123) <= wallet_size
          ckey_data = data[start, 123]
          ckey_encrypted = ckey_data[0,48]
          hex = bytes_to_hex(ckey_encrypted)

          if flags[:skip_incorrect_keys] && hex =~ /(.)\1{4,}/
            offset += 4
            next
          end

          if hex.length <= 200 && hex.length >= 70
            puts LIGHT_RED + BOLD + "ckey!" + RESET + BLUE + hex + RESET
            match_count += 1
          end
        end
        offset += 3
      end
      offset += 1
    end
  end
  puts LIGHT_GREEN + "#{match_count} ckey matches found." + RESET
end

puts PURPLE + "Process finished. Exiting..." + RESET
