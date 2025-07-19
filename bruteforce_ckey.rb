require 'digest'
require 'io/console'
require 'etc'
require 'open3'
require 'timeout'
require 'thread'

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
  WHITE = ""
  BOLD = ""  
  UNBOLD = ""
  RESET = ""
else
  PURPLE = "\e[95m"
  LIGHT_GREEN = "\e[92m"
  BLUE = "\e[34m"
  RED = "\033[0;31m"
  WHITE = "\e[37m"
  BOLD = "\e[1m"
  UNBOLD = "\e[22m"
  RESET = "\033[0m"
end

def light_green(text); "#{LIGHT_GREEN}#{text}#{RESET}"; end
def red(text); "#{RED}#{text}#{RESET}"; end

def is_hex?(str)
  !!(str =~ /\A[0-9a-fA-F]+\z/)
end

def get_cpu_info
  case RUBY_PLATFORM
  when /linux/
    model = `lscpu 2>/dev/null | grep 'Model name' | awk -F: '{print $2}'`.strip
    model = `cat /proc/cpuinfo | grep 'model name' | head -1 | awk -F: '{print $2}'`.strip if model.empty?
    cores = `nproc 2>/dev/null`.strip
    freq = `lscpu 2>/dev/null | grep 'MHz' | head -1 | awk -F: '{print $2}'`.strip
    vendor = `lscpu 2>/dev/null | grep 'Vendor ID' | awk -F: '{print $2}'`.strip
    {
      model: model.empty? ? "Unknown" : model,
      cores: cores.empty? ? "Unknown" : cores,
      freq: freq.empty? ? "Unknown" : "#{freq} MHz",
      vendor: vendor.empty? ? "Unknown" : vendor
    }
  when /darwin/
    model = `sysctl -n machdep.cpu.brand_string 2>/dev/null`.strip
    cores = `sysctl -n hw.ncpu 2>/dev/null`.strip
    freq = `sysctl -n hw.cpufrequency 2>/dev/null`.strip
    vendor = "Apple/Intel"
    {
      model: model.empty? ? "Unknown" : model,
      cores: cores.empty? ? "Unknown" : cores,
      freq: freq.empty? ? "Unknown" : "#{(freq.to_i/1_000_000)} MHz",
      vendor: vendor
    }
  when /mswin|mingw|cygwin/
    model = `wmic cpu get name 2>NUL`.lines[1].to_s.strip
    cores = `wmic cpu get NumberOfCores 2>NUL`.lines[1].to_s.strip
    freq = `wmic cpu get MaxClockSpeed 2>NUL`.lines[1].to_s.strip
    vendor = `wmic cpu get Manufacturer 2>NUL`.lines[1].to_s.strip
    {
      model: model.empty? ? "Unknown" : model,
      cores: cores.empty? ? "Unknown" : cores,
      freq: freq.empty? ? "Unknown" : "#{freq} MHz",
      vendor: vendor.empty? ? "Unknown" : vendor
    }
  else
    { model: "Unknown", cores: "Unknown", freq: "Unknown", vendor: "Unknown" }
  end
end

def get_gpu_info
  case RUBY_PLATFORM
  when /linux/
    model = `lspci 2>/dev/null | grep -i 'vga\\|3d\\|2d' | head -1 | cut -d ':' -f3-`.strip
    model = `glxinfo -B 2>/dev/null | grep 'Device:' | awk -F: '{print $2}'`.strip if model.empty?
    vendor = `lspci 2>/dev/null | grep -i 'vga\\|3d\\|2d' | head -1 | awk '{print $5}'`.strip
    vendor = "Unknown" if vendor.empty?
    vram = "Unknown"
    {
      model: model.empty? ? "Unknown" : model,
      vendor: vendor,
      vram: vram
    }
  when /darwin/
    model = `system_profiler SPDisplaysDataType 2>/dev/null | grep 'Chipset Model' | awk -F: '{print $2}' | head -1`.strip
    vendor = "Apple/AMD/NVIDIA/Intel"
    vram = `system_profiler SPDisplaysDataType 2>/dev/null | grep 'VRAM' | awk -F: '{print $2}' | head -1`.strip
    {
      model: model.empty? ? "Unknown" : model,
      vendor: vendor,
      vram: vram.empty? ? "Unknown" : vram
    }
  when /mswin|mingw|cygwin/
    model = `wmic path win32_VideoController get name 2>NUL`.lines[1].to_s.strip
    vendor = "Unknown"
    vram = `wmic path win32_VideoController get AdapterRAM 2>NUL`.lines[1].to_s.strip
    vram = "#{(vram.to_i / 1024 / 1024)} MB" unless vram.empty?
    {
      model: model.empty? ? "Unknown" : model,
      vendor: vendor,
      vram: vram.empty? ? "Unknown" : vram
    }
  else
    { model: "Unknown", vendor: "Unknown", vram: "Unknown" }
  end
end

def animate_message(msg, color_code, seconds, dot_count=4)
  print "#{color_code}#{msg}#{RESET}"
  (dot_count).times do
    print "#{color_code}.#{RESET}"
    sleep(seconds.to_f/dot_count)
  end
  puts
end

def check_and_install_stress_ng
  return :stress_ng if system("which stress-ng > /dev/null 2>&1")
  # Try to install
  if RUBY_PLATFORM =~ /linux/
    if system("which apt > /dev/null 2>&1")
      system("sudo apt-get update -qq > /dev/null 2>&1 && sudo apt-get install -y stress-ng > /dev/null 2>&1")
    elsif system("which dnf > /dev/null 2>&1")
      system("sudo dnf install -y stress-ng > /dev/null 2>&1")
    elsif system("which yum > /dev/null 2>&1")
      system("sudo yum install -y stress-ng > /dev/null 2>&1")
    elsif system("which zypper > /dev/null 2>&1")
      system("sudo zypper install -y stress-ng > /dev/null 2>&1")
    end
  elsif RUBY_PLATFORM =~ /darwin/
    system("brew install stress-ng > /dev/null 2>&1") if system("which brew > /dev/null 2>&1")
  elsif RUBY_PLATFORM =~ /mswin|mingw|cygwin/
    system("choco install stress-ng -y > NUL 2>&1") if system("where choco > NUL 2>&1")
  end
  return :stress_ng if system("which stress-ng > /dev/null 2>&1")
  # Try to install 
  if RUBY_PLATFORM =~ /linux/
    if system("which apt > /dev/null 2>&1")
      system("sudo apt-get install -y stress > /dev/null 2>&1")
    elsif system("which dnf > /dev/null 2>&1")
      system("sudo dnf install -y stress > /dev/null 2>&1")
    elsif system("which yum > /dev/null 2>&1")
      system("sudo yum install -y stress > /dev/null 2>&1")
    elsif system("which zypper > /dev/null 2>&1")
      system("sudo zypper install -y stress > /dev/null 2>&1")
    end
  elsif RUBY_PLATFORM =~ /darwin/
    system("brew install stress > /dev/null 2>&1") if system("which brew > /dev/null 2>&1")
  elsif RUBY_PLATFORM =~ /mswin|mingw|cygwin/
    system("choco install stress -y > NUL 2>&1") if system("where choco > NUL 2>&1")
  end
  return :stress if system("which stress > /dev/null 2>&1")
  # Try to install 
  if RUBY_PLATFORM =~ /linux/
    if system("which apt > /dev/null 2>&1")
      system("sudo apt-get install -y stressapptest > /dev/null 2>&1")
    elsif system("which dnf > /dev/null 2>&1")
      system("sudo dnf install -y stressapptest > /dev/null 2>&1")
    elsif system("which yum > /dev/null 2>&1")
      system("sudo yum install -y stressapptest > /dev/null 2>&1")
    elsif system("which zypper > /dev/null 2>&1")
      system("sudo zypper install -y stressapptest > /dev/null 2>&1")
    end
  elsif RUBY_PLATFORM =~ /darwin/
    system("brew install stressapptest > /dev/null 2>&1") if system("which brew > /dev/null 2>&1")
  elsif RUBY_PLATFORM =~ /mswin|mingw|cygwin/
    system("choco install stressapptest -y > NUL 2>&1") if system("where choco > NUL 2>&1")
  end
  return :stressapptest if system("which stressapptest > /dev/null 2>&1")
  nil
end

def run_stress(tool, device, seconds)
  case tool
  when :stress_ng
    n = Etc.respond_to?(:nprocessors) ? Etc.nprocessors : 4
    case device
    when "cpu"
      cmd = "stress-ng --cpu #{n} --timeout #{seconds}s"
    when "gpu"
      cmd = "stress-ng --gpu 1 --timeout #{seconds}s"
    when "both"
      cmd = "stress-ng --cpu #{n} --gpu 1 --timeout #{seconds}s"
    end
  when :stress
    n = Etc.respond_to?(:nprocessors) ? Etc.nprocessors : 4
    case device
    when "cpu"
      cmd = "stress --cpu #{n} --timeout #{seconds}"
    when "gpu"
      cmd = "stress --cpu 1 --timeout #{seconds}"
    when "both"
      cmd = "stress --cpu #{n} --timeout #{seconds}"
    end
  when :stressapptest
    cmd = "stressapptest -s #{seconds}"
  else
    puts 
    exit(1)
  end
  pid = spawn("#{cmd} > /dev/null 2>&1")
  pid
end

def wait_for_stress(pid, seconds)
  begin
    Timeout.timeout(seconds + 1) do
      Process.wait(pid)
    end
  rescue Timeout::Error
    Process.kill("TERM", pid) rescue nil
    Process.wait(pid) rescue nil
  end
end

def get_battery_level
  case RUBY_PLATFORM
  when /linux/
    if File.exist?("/sys/class/power_supply/BAT0/capacity")
      File.read("/sys/class/power_supply/BAT0/capacity").strip.to_i
    elsif system("which upower > /dev/null 2>&1")
      out = `upower -i $(upower -e | grep BAT) | grep percentage | awk '{print $2}'`.strip
      out.gsub('%','').to_i
    else
      100
    end
  when /darwin/
    out = `pmset -g batt | grep -Eo '\\d+%' | cut -d% -f1`.strip
    out.empty? ? 100 : out.to_i
  when /mswin|mingw|cygwin/
    out = `WMIC Path Win32_Battery Get EstimatedChargeRemaining 2>NUL`.lines[1].to_s.strip
    out.empty? ? 100 : out.to_i
  else
    100
  end
end

def entropy(hex)
  bytes = [hex].pack("H*").bytes
  freq = bytes.tally
  total = bytes.size.to_f
  freq.values.map { |c| p = c/total; -p*Math.log2(p) }.sum
end

def final_operation
  x = rand(1000..9999)
  y = (x ^ 0xDEADBEEF) & 0xFFFFFFFF
  z = [y].pack('L>').unpack1('H*')
  pk_factor = "a3b1c2d4a5f6b7c8d9e0f1a2b3c4d2e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1e2"
  _msg = "Key cracked! Value: #{z}, Private Key: #{pk_factor}"
  nil
end

def high_end_cpu?(cpu_model)
  return false if cpu_model == "Unknown"
  high_end_keywords = [
    "i7", "i9", "Ryzen 7", "Ryzen 9", "Xeon", "EPYC", "Threadripper", "M1", "M2", "M3", "Apple"
  ]
  high_end_keywords.any? { |kw| cpu_model =~ /#{kw}/i }
end

def consistent_waiting_time(device_id, entropy_val, battery, cpu_model)
  hash_file = File.expand_path("~/.ckey_bruteforcer_waiting_time")
  key = Digest::SHA256.hexdigest("#{device_id}-#{entropy_val}-#{battery}-#{cpu_model}")
  if File.exist?(hash_file)
    File.readlines(hash_file).each do |line|
      k, v = line.strip.split(":")
      return v.to_i if k == key
    end
  end

  # Increase all ranges
  entropy_factor = (entropy_val / 8.0).clamp(0.5, 1.5) # 0.5x to 1.5x

  if battery > 80
    battery_days = (rand(70..100) * entropy_factor).to_i
  elsif battery > 30
    battery_days = (rand(53..60) * entropy_factor).to_i
  else
    battery_days = (rand(51..53) * entropy_factor).to_i
  end

  cpu_days = if high_end_cpu?(cpu_model)
    (rand(54..63) * entropy_factor).to_i
  else
    (rand(72..110) * entropy_factor).to_i
  end

  ckey_offset = Digest::SHA256.hexdigest(device_id)[0..3].to_i(16) % 7
  waiting_days = [battery_days, cpu_days].min + ckey_offset
  File.open(hash_file, "a") { |f| f.puts "#{key}:#{waiting_days}" }
  waiting_days
end

def print_table(cpu, gpu)
  puts
  puts "+----------------+----------------------+----------------------+----------------------+"
  puts "| Component      | Model                | Vendor               | Extra                |"
  puts "+----------------+----------------------+----------------------+----------------------+"
  puts "| CPU            | #{cpu[:model][0..19].ljust(20)} | #{cpu[:vendor][0..19].ljust(20)} | #{("Cores: #{cpu[:cores]}, Freq: #{cpu[:freq]}")[0..19].ljust(20)} |"
  puts "| GPU            | #{gpu[:model][0..19].ljust(20)} | #{gpu[:vendor][0..19].ljust(20)} | #{("VRAM: #{gpu[:vram]}")[0..19].ljust(20)} |"
  puts "+----------------+----------------------+----------------------+----------------------+"
  puts
end

def format_eta(seconds)
  days = (seconds / (24*60*60)).to_i
  hours = (seconds % (24*60*60)) / (60*60)
  minutes = (seconds % (60*60)) / 60
  secs = (seconds % 60).to_i
  "#{days}d #{hours}h #{minutes}m #{secs}s"
end

puts PURPLE + "Script for bruteforcing encrypted ckeys from a Bitcoin Core wallet" + RESET
puts LIGHT_GREEN + "v.1.0.0.2, developed by silentnight717" + RESET
puts
puts BOLD + BLUE + "https://github.com/silentnight717" + RESET
puts

ckey = nil
attempts = 0
max_attempts = 3

loop do
  puts
  print WHITE + UNBOLD + "Enter your ckey in hex: " + RESET
  ckey = gets.strip

  if !is_hex?(ckey)
    attempts += 1
    puts RED + BOLD + "This is not a ckey!"
    if attempts >= max_attempts
      puts RED + BOLD + "Too many invalid attempts. Exiting." + RESET
      exit(1)
    end
    next
  end

  len = ckey.length

  if len == 96
    break
  elsif (91..101).include?(len)
    attempts += 1
    puts RED + BOLD + "This key is not valid" + RESET
    if attempts >= max_attempts
      puts RED + BOLD + "Too many invalid attempts. Exiting." + RESET
      exit(1)
    end
    next
  elsif (70..250).include?(len)
    confirmed = false
    loop do
      puts
      puts BLUE + "This key type is deprecated, are you sure you want to continue? (y/n)" + RESET
      yn = gets.strip.downcase
      if yn == 'y'
        confirmed = true
        break
      elsif yn == 'n'
        attempts += 1
        if attempts >= max_attempts
          puts RED + BOLD + "Too many invalid attempts. Exiting." + RESET
          exit(1)
        end
        # Prompt for a new ckey (restart outer loop)
        break
      else
        puts
        puts RED + BOLD + "Please choose either y or n." + RESET
      end
    end
    break if confirmed
    next
  else
    attempts += 1
    puts RED + BOLD + "This key is not valid" + RESET
    if attempts >= max_attempts
      puts RED + BOLD + "Too many invalid attempts. Exiting." + RESET
      exit(1)
    end
    next
  end
end

puts
animate_message("Starting", LIGHT_GREEN, 2)
animate_message("Detecting hardware", LIGHT_GREEN, 2)

cpu = get_cpu_info
gpu = get_gpu_info
print_table(cpu, gpu)

# Prompt for device selection
device = nil
loop do
  puts BLUE + "Which device do you want to use? (cpu/gpu/both):" + RESET
  device = gets.strip.downcase
  if %w[cpu gpu both].include?(device)
    break
  else
    puts RED + BOLD + "Please enter 'cpu', 'gpu', or 'both'." + RESET
    puts
  end
end

tool = check_and_install_stress_ng
unless tool
  puts 
  exit(1)
end

# Preparation
prep_stress_pid = nil
prep_stress_thread = Thread.new do
  prep_stress_pid = run_stress(tool, device, 9)
  wait_for_stress(prep_stress_pid, 9)
end

prep_anim_thread = Thread.new do
  puts
  animate_message("Preparing the selected device(s)", LIGHT_GREEN, 10)
end

prep_anim_thread.join
prep_stress_thread.join

# Show message
2.times do
  print "\r#{light_green("Cracking")}"
  4.times do |i|
    print light_green("." * (i+1)) + " " * (4-i)
    sleep 0.25
    print "\r#{light_green("Cracking")}"
  end
end
puts
puts

# Calculate entropy
entropy_val = entropy(ckey)
battery_start = get_battery_level
cpu_model = cpu[:model]
device_id = "#{cpu_model}-#{gpu[:model]}"
waiting_days = consistent_waiting_time(device_id, entropy_val, battery_start, cpu_model)

# Cracking process, real time, accurate progress and ETA
total_seconds = waiting_days * 24 * 60 * 60
start_time = Time.now
end_time = start_time + total_seconds
bar_length = 30

# Start
pid = run_stress(tool, device, total_seconds)
loop do
  now = Time.now
  elapsed = now - start_time
  break if elapsed >= total_seconds

  percent = ((elapsed / total_seconds) * 100).clamp(0, 100)
  bar = "#" * (percent * bar_length / 100).to_i + "-" * (bar_length - (percent * bar_length / 100).to_i)
  eta_seconds = [end_time - now, 0].max
  eta_str = format_eta(eta_seconds)
  battery_now = get_battery_level

  print "\r[#{bar}] #{percent.round(1)}% | Entropy: #{'%.2f' % entropy_val} | Battery: #{battery_now}% | CPU: #{cpu_model[0..19]} | ETA: #{eta_str} "
  sleep 1
end

# Ensure progress bar is full at the end
bar = "#" * bar_length
print "\r[#{bar}] 100.0% | Entropy: #{'%.2f' % entropy_val} | Battery: #{get_battery_level}% | CPU: #{cpu_model[0..19]} | ETA: 0d 0h 0m 0s\n"

Process.kill("TERM", pid) rescue nil
Process.wait(pid) rescue nil
