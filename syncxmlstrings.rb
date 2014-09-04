#!/usr/bin/env ruby

require 'optparse'
require 'xmlsimple'



def replace(filepath, regexp, *args, &block)
  content = File.read(filepath).gsub(regexp, *args, &block)
  File.open(filepath, 'wb') { |file| file.write(content) }
end

def syncxmlfile(fin, fout, keys)

	puts "#{fin} -> #{fout}: Syncing..."

	if not File.exists?(fin) or not File.exists?(fout) then
		puts "Cannot open the file!"
		return
	end

xmlOrgData = XmlSimple.xml_in(fin)

strs = {}

xmlOrgData['string'].each do |str|
   if keys.include?(str["name"]) then
	strs[str["name"]] = str["content"] 
   end
end

xmlOrgData = XmlSimple.xml_in(fout)

 xmlOrgData['string'].each do |str|
   if strs.include?(str["name"]) then
    #old = str["name"]
	#str["content"] = strs[old] 
    #puts "[M] " + str["name"] + ": '" + strs[old] + "'" 
	strs.delete(str["name"])
   end
end

	xmlOrgData = { 'string' => []}
strs.each do |s,c|
	item = {"name" => s, "content" => c}
	xmlOrgData['string'].insert(0, item);
#	puts "[A] " + s + ": '" + c + "'"
end

if strs.empty? then
puts "#{fin} -> #{fout}: Nothing to do!"
return
end

xmlOut = XmlSimple.xml_out(xmlOrgData, {"AttrPrefix" => false, "RootName" => "", "ContentKey" => "content", "NoEscape" => "1"})
#puts xmlOut
#exit

replace(fout, /^<resources.*>/) { |match| "#{match}\n#{xmlOut}"}
end



options = {}

OptionParser.new do |opts|
	opts.banner = "Usage: syncxmlstrings.rb --i[nput] <file.xml> --o[utput] <file.xml> --s[trings] <str1>,<str2> ...\n
					or \n
					syncxmlstrings.rb --f[rom] <directory> --t[o] <directory> --s[trings] <str1>,<str2> ..."
	opts.on("-i", "--input FILE", String, "Input string.xml file where strings will be searched") do |v|
		options[:inp] = v
	end
	opts.on("-o", "--output FILE", String, "Output file that will be modifed") do |v|
		options[:out] = v
	end
	opts.on("-f", "--from DIR", String, "Directory with resources") do |v|
		options[:from] = v
	end
	opts.on("-t", "--to DIR", String, "Directory with resources that will be modified") do |v|
		options[:to] = v
	end
	opts.on("-s", "--strings x,y,z", Array, "Strings that will be synced") do |v|
		options[:strings] = v
	end
end.parse!


if ((options.has_key?(:inp) == false or options.has_key?(:out) == false) && (options.has_key?(:from) == false or options.has_key?(:to) == false)) or options.has_key?(:strings) == false then
	puts "Type syncxmlstrings.rb --help to see usage!"
	return
end

dirMode = false
if(options.has_key?(:inp) == false || options.has_key?(:out) == false)
dirMode = true
end

puts "Synced strings: " + options[:strings].inspect + "\n"
puts "----------------\n"

if dirMode then
puts "Input directory: " + options[:from] + "\n"
puts "Output directory: " + options[:to] + "\n"

Dir.entries(options[:to]).select { |file| File.directory? File.join(options[:to], file) }.each do |val|
	if val=~/values.*/ then
		if File.exists? "#{options[:from]}/#{val}/strings.xml" then
			syncxmlfile("#{options[:from]}/#{val}/strings.xml","#{options[:to]}/#{val}/strings.xml", options[:strings])
		else
			puts "Skipping #{options[:from]}/#{val}/strings.xml, file doesn't exits!"
		end
	end
end
puts "Done!"

else
puts "Input: " + options[:inp] + "\n"
puts "Output: " + options[:out] + "\n"
syncxmlfile(options[:inp], options[:out], options[:strings])
end





