#!/usr/bin/env ruby

require 'set'
require 'csv'
require 'optparse'

unique = false
order = false
reqired_chars = Set.new

parser = OptionParser.new do |opts|
  opts.banner = "Usage:\n #$0 [--unique] [--added C] [--order] mask1 mask2 ..."
  opts.on('-u', '--unique', 'Do not repeat chars') do
    unique = true
  end
  opts.on('-o', '--order', 'Different order mechanics') do
    order = true
  end
  opts.on('-a', '--added=a', String, 'Added green-yellow chars') do |a|
    reqired_chars = Set.new(a.upcase.split '')
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
blocked_positions = 5.times.map { Set.new }
blocked_chars = Set.new
ARGV.each do |mask|
  (0...5).each do |i|
    char = mask[2*i+1].upcase
    control = mask[2*i]
    case control
    when '!'
      pattern[i] = char
    when '+'
      blocked_positions[i] << char
    when '.'
      #(0...5).each {|j| blocked_positions[j] << char }
      blocked_chars << char
    else
      abort "wrong control char: #{control}"
    end
  end
end

positioned_chars = pattern.split ''
positioned_chars.delete '.'

puts "positioned characters: #{positioned_chars.to_a.join ', '}"
puts "required characters: #{reqired_chars.to_a.join ', '}"
puts "blocked characters: #{blocked_chars.to_a.join ', '}"
puts "unique characters: #{unique}"
puts "blocked positions: #{blocked_positions.map {|s| s.to_a}}"
puts "pattern: #{pattern}"

selected = []
File.readlines('CZ-UTF8-words5.txt').each do |row|
  word = row.strip.upcase
  #p word
  word_chars = word.split ''
  chars = Set.new word_chars
  next if unique and word.size != chars.size
  next unless chars.subset? allowed_chars
  next unless Regexp.new(pattern).match word
  next if blocked_chars.intersect? chars
  next if word_chars.zip(blocked_positions).map do |pair| 
    char, blocked = pair
    blocked.include? char
  end.any? 
  positioned_chars.each do |pc|
    idx = word_chars.index pc
    word_chars.slice! idx unless idx.nil?
  end
  next unless reqired_chars.subset? Set.new(word_chars)
  selected << word
end

p selected.size
selected.sort_by! do |word|  
  w = word.split('').map {|char| weight[char] }
  order ? -w.reduce(:*) : -w.min
end

puts selected

