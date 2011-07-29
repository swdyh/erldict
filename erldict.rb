# -*- coding: utf-8 -*-
require 'open-uri'
require 'fileutils'
require 'pp'
require 'rubygems'
require 'nokogiri'

HTML_DOC_DIR = 'html'

def main
  mods = get_modules
  # without wx
  mods.reject! {|mod| /^(wx)/.match(mod[2]) }

  size = mods.size
  content = ''
  mods.each_with_index do |i, index|
    mod, path = i
    puts "#{index + 1}/#{size} #{mod}"
    content << generate_entries(mod, path)
  end

  xml = <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<d:dictionary xmlns="http://www.w3.org/1999/xhtml" xmlns:d="http://www.apple.com/DTDs/DictionaryService-1.0.rng">
#{content}
</d:dictionary>
EOS

  out = ARGV.first || 'erldict.xml'
  open(out, 'w') {|f| f.write(xml) }
  puts "create #{out}"
end

def get_modules
  html = read 'man_index.html'
  doc = Nokogiri::HTML html
  mods = doc.xpath('//tr/td[1]/a').map do |i|
    [i.text, i.attribute('href').value, i.xpath('../../td[2]/a').text]
  end
  # mods.uniq { |i| i[0] } # does not work in ruby 1.8
  h = {}
  mods.inject([]) do |r, i|
    h[i[0]] ||= r << i
  end
end

def generate_entries mod, path
  r = ''
  doc = Nokogiri::HTML read(path)

  r << get_summary(doc, mod)
  re = /\// # reject c function
  funs = doc.xpath('//li[@id="loadscrollpos"]//a').inject([]) do |rr, i|
    f = i.text.strip.gsub("'", '')
    if re.match(f) && !rr.include?(f)
      rr << f
    end
    rr
  end

  funs.each do |f|
    id = f.gsub('/', '-')
    node = doc.xpath('//a[@name="%s"]' % id)[0]
    next unless node

    t = get_type node, id, mod
    body = get_body node, id, mod
    title = [mod, f].join(':')
    r << <<-EOS
<d:entry id="#{mod}-#{id}" d:title="#{title}">
  <d:index d:value="#{title}" d:title="#{title}" />
  <d:index d:value="#{f}" d:title="#{title}" />
  <h1>#{title}</h1>
  <div>#{t}</div>
  <div>#{body}</div>
</d:entry>
EOS
  end
  r
end

def get_summary doc, mod_name
  r = []
  doc.xpath('//h3[contains(string(), "SUMMARY")]/following-sibling::*').each do |node|
    if node.node_name == 'h3' && node.text == 'EXPORTS'
      break
    end
    r << node
  end
  if r.size == 0
    debug :summry_not_found, mod_name
  end
  body = r.map do |i|
    node_filter i, mod_name
    i.to_xhtml
  end.join('')
  <<-EOS
<d:entry id="#{mod_name}" d:title="#{mod_name}">
  <d:index d:value="#{mod_name}" d:title="#{mod_name}" />
  <h1>#{mod_name}</h1>
  <div>#{body}</div>
</d:entry>
EOS
end

def get_type node, name, mod_name
  xpath = <<-EOS
     (span[@class="bold_code"] | following-sibling::span[@class="bold_code"])[1]
  EOS
  r = node.xpath(xpath)
  if r.size == 0
    debug :type_not_found, mod_name, name, node
  end
  r.to_xhtml
end

def get_body node, name, mod_name
  b_nodes = []
  node.parent.xpath('following-sibling::*').each do |n|
    if n.node_name == 'div' && n.attribute('class').value == 'REFBODY'
      b_nodes << n
    else
      break
    end
  end
  if b_nodes.size == 0
    debug :body_not_found, mod_name, name, node
    # raise RuntimeError, "body_not_found, #{[mod_name, name, node].inspect}" rescue nil
  end
  b_nodes.map do |b_node|
    node_filter b_node, mod_name
    b_node.to_xhtml
  end.join('')
end

def node_filter node, mod_name
  node.xpath('.//*').each do |n|
    if n.node_name == 'a'
      # TODO ancher
      # name = n.attribute('name')
      # if name
      #   p name.value
      #   name.value = mod_name + '-' + name.value
      #   p name.value
      #   puts
      # end
      href = n.attribute('href')
      if href
        if href.value.match(/.+\.html\#.+-\d$/)
          mod, fun = href.value.split('.html#')
          if !fun.match(/:/)
            fun = mod + ':' + fun
          end
          href.value = 'x-dictionary:r:' + fun.gsub(':', '-')
        elsif href.value.match(/\#.+-\d$/)
          href.value = 'x-dictionary:r:' + mod_name + '-' + href.value.gsub('#', '')
        elsif href.value.match(/\#/)
          # TODO ancher
          # p [:ancher, mod_name, href.value]
          n.remove_attribute('href')
        else
          # TODO open browser
          # p [:else, href.value, n.text, "http://www.erlang.org/doc/man/#{href.value}"]
          # href.value = "http://www.erlang.org/doc/man/#{href.value}"
          n.remove_attribute('href')
        end
      end
    end
  end
end

def read path
  doc_dir = File.join(File.dirname(__FILE__), HTML_DOC_DIR, 'doc')
  IO.read File.join(doc_dir, path)
end

def debug(name, *args)
  puts "*DEBUG #{name} #{caller.first} #{args.inspect}" if $DEBUG
end

main if __FILE__ == $0
