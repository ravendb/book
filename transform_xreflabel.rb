#!/usr/bin/env ruby
# transformer.rb: Prepends xreflabel to the title of each formalpara in a DocBook XML file
require 'nokogiri'

input_path = ARGV[0]
output_path = ARGV[1] || input_path

doc = Nokogiri::XML(File.read(input_path))

# Define the DocBook namespace
ns = { 'db' => 'http://docbook.org/ns/docbook' }

# For each formalpara, prepend xreflabel to the title if present
changed = false
doc.xpath('//db:formalpara', ns).each do |fp|
  xreflabel = fp['xreflabel']
  title = fp.at_xpath('db:title', ns)
  if xreflabel && title && !title.content.start_with?(xreflabel)
    title.content = "#{xreflabel} - #{title.content}"
    changed = true
  end
end

if changed
  File.write(output_path, doc.to_xml)
else
  puts 'No changes made.'
end
