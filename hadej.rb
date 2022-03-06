#!/usr/bin/env ruby

require 'set'
require 'csv'
require 'optparse'

unique = false
order = false
addeded_chars = []

parser = OptionParser.new do |opts|
  opts.banner = "Usage:\n #$0 [--unique] [--added C] [--order] mask1 mask2 ..."
  opts.on('-u', '--unique', 'Do not repeat chars') do
    unique = true
  end
  opts.on('-o', '--order', 'Different order mechanics') do
    order = true
  end
  opts.on('-a', '--added=a', String, 'Added green-yellow chars') do |a|
    addeded_chars = a.upcase.split ''
  end
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end
parser.parse!

abort parser.help if ARGV.size < 1

weight = {}
CSV.table('freq.csv').each {|row| weight[row[:char].upcase] = row[:count]/10000.0 }
allowed_chars = Set.new weight.keys

pattern = '.....'
required_chars = []
blocked_positions = 5.times.map { Set.new }
ARGV.each_with_index do |mask,idx|
  (0..4).each do |i|
    abort "wrong number of chars in mask #{mask}" unless mask.size == 10
    char = mask[2*i+1].upcase
    control = mask[2*i]
    case control
    when '!'
      pattern[i] = char
    when '+'
      blocked_positions[i] << char
      if idx == ARGV.size-1
        required_chars << char unless required_chars.include? char
      end
    when '.'
      blocked_positions.each {|pos| pos << char }
    else
      abort "wrong control char: #{control}"
    end
  end
end
required_chars += addeded_chars

puts "required characters: #{required_chars.to_a.join ', '}"
puts "blocked positions: #{blocked_positions.map {|s| s.to_a}}"
puts "pattern: #{pattern}"
puts "unique characters: #{unique}"

selected = []
File.readlines('CZ-UTF8-words5.txt').each do |row|
  word = row.strip.upcase
  #p word
  word_chars = word.split ''
  chars = Set.new word_chars
  next if unique and word.size != chars.size
  next unless chars.subset? allowed_chars
  next unless Regexp.new(pattern).match word
  next if word_chars.zip(blocked_positions).map do |pair| 
    char, blocked = pair
    blocked.include? char
  end.any? 
  next if required_chars.map do |required|
    idx = word_chars.index required
    word_chars.slice! idx unless idx.nil?
    idx.nil?
  end.any?
  selected << word
end

p selected.size
selected.sort_by! do |word|  
  w = word.split('').map {|char| weight[char] }
  order ? -w.reduce(:*) : -w.min
end

puts selected

