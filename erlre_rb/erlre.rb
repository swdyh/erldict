#!/usr/local/bin/macruby
# -*- coding: utf-8 -*-

# based on http://gist.github.com/770759

framework 'CoreServices'
load_bridge_support_file File.dirname(__FILE__) + '/DictionaryServices.bridgesupport'
if ARGV.length != 1
  puts 'Usage: ./erlre.rb word'
  exit
end

word = ARGV[0]
dict = DCSCopyAvailableDictionaries().allObjects.find {|i|
  DCSDictionaryGetName(i) == 'Erlang OTP Reference'
}
r = DCSCopyRecordsForSearchString(dict, word, 1, 0)

unless r
  puts "not match: #{word}"
  exit
end

m = r.find {|i| DCSRecordGetHeadword(i) == word }
if r.size == 1 || m
  puts DCSRecordGetHeadword(m || r[0])
  puts
  range = DCSGetTermRangeInString(nil, word, 0)
  t = DCSCopyTextDefinition(dict, word, range)
  puts t.gsub(/^/m, '    ')
else
  puts r.map {|i| DCSRecordGetHeadword(i) }
end


