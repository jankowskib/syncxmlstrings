#!/usr/bin/env ruby

require 'optparse'
require 'colorize'

def syncxmlfile(fin, fout, keys, fref = nil)

	puts "#{fin} -> #{fout}: Syncing..."

	if not File.exists?(fin) or not File.exists?(fout) then
		puts "Cannot open the file!"
		return
	end

	strs = {}
	newstrs = {}
	refstrs = {}
	xmlOrgData = File.read(fin)
	xmlNewData = File.read(fout)
	
	if fref
		xmlRefData = File.read(fref)
		xmlRefData.scan(/^\s*\<string\s*name="(\w*)"\s*(?:formatted="(\w*)"|\s*)\s*\>(.*?)\<\/string\>/m) do |a,b,c|
			refstrs[a] = {:formatted => b == "false" ? false : true, :content => c }
		end
	end
	
	xmlOrgData.scan(/^\s*\<string\s*name="(\w*)"\s*(?:formatted="(\w*)"|\s*)\s*\>(.*?)\<\/string\>/m) do |a,b,c|
		strs[a] = {:formatted => b == "false" ? false : true, :content => c }
	end
	xmlNewData.scan(/^\s*\<string\s*name="(\w*)"\s*(?:formatted="(\w*)"|\s*)\s*\>(.*?)\<\/string\>/m) do |a,b,c|
		newstrs[a] = {:formatted => b == "false" ? false : true, :content => c }
	end
			
	strs.each do |s,c|
		next if !newstrs.has_key?(s)
		if $options[:ask] == true && newstrs[s] != strs[s] then
			puts "#{item["name"]}:".green
			print "#{orgkeys[s]} -> #{newstrs[s]} [y/n/a]: "
			prompt = gets.upcase
			if(prompt == "A\n")
				puts "Adding remaining changes..."
				$options[:ask] = false
			elsif(prompt != "Y\n" && prompt != "\n")
				next
			end
		end
		
		if newstrs[s] != strs[s] && $options[:replace] == true
			puts "[M] " + s + ": '" + c[:content] + "' -> '" + newstrs[s][:content] + "'" if $options[:verbose]
			strs[s] = newstrs[s]
		end
	end
	
	newstrs.each do |s,c|	
		next if !refstrs.empty? && !refstrs.has_key?(s)

		if !strs.has_key?(s)
			puts "[A] " + s + ": '" + c[:content] + "'" if $options[:verbose]
			strs[s] = newstrs[s]
		end
	end

	File.open(fout+"test", 'wb') do |file| 
		file.write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<resources>\n") 
		entry = ""
		strs.each do |s,c| 
			entry << "    <string name=\"#{s}\""
			entry << ' formatted="false"' if not c[:formatted]
			entry << ">#{c[:content]}"
			entry << "</string>\n"
		end
		file.write entry
		file.write("</resources>")
	end

end



$options = {}
$options[:ask] = false
$options[:replace] = false
$options[:verbose] = false
$options[:dirmode] = false

OptionParser.new do |opts|
	opts.banner = "Usage: syncxmlstrings.rb [$options] --i[nput] <file.xml> --o[utput] <file.xml> --s[trings] <str1>,<str2> ...\n
	or \n
syncxmlstrings.rb [$options] --f[rom] <directory> --t[o] <directory> --s[trings] <str1>,<str2> ...\n
$options: --[v]erbose --[a]sk, --[r]eplace --[m]aster <file.xml>"
	opts.on("-i", "--input FILE", String, "Input string.xml file where strings will be searched") do |v|
		$options[:inp] = v
	end
	opts.on("-o", "--output FILE", String, "Output file that will be modifed") do |v|
		$options[:out] = v
	end
	opts.on("-m", "--master FILE", String, "Add only strings if were referenced in this file") do |v|
		$options[:ref] = v
	end
	opts.on("-f", "--from DIR", String, "Directory with resources") do |v|
		$options[:from] = v
	end
	opts.on("-t", "--to DIR", String, "Directory with resources that will be modified") do |v|
		$options[:to] = v
	end
	opts.on("-s", "--strings x,y,z", Array, "Strings keys that will be synced") do |v|
		$options[:strings] = v
	end
	opts.on("-a", "--ask", "Ask before change") do |v|
		$options[:ask] = true
	end
	opts.on("-r", "--replace", "Replace existing keys") do |v|
		$options[:replace] = true
	end
	opts.on("-v", "--verbose", "Print the changes") do |v|
		$options[:verbose] = true
	end
end.parse!


if ($options.has_key?(:inp) == false or $options.has_key?(:out) == false) and ($options.has_key?(:from) == false or $options.has_key?(:to) == false) then
	puts "Type syncxmlstrings.rb --help to see usage!"
	exit
end

if($options.has_key?(:inp) == false && $options.has_key?(:out) == false)
	$options[:dirmode] = true
end

puts "Synced strings: " << $options[:strings] if $options[:strings]

if $options[:dirmode] then
puts "Input directory: " + $options[:from] 
puts "Output directory: " + $options[:to]

Dir.entries($options[:to]).select { |file| File.directory? File.join($options[:to], file) }.each do |val|
	if val=~/values.*/ then
		if File.exists? "#{$options[:from]}/#{val}/strings.xml" then
			syncxmlfile("#{$options[:from]}/#{val}/strings.xml","#{$options[:to]}/#{val}/strings.xml", $options[:strings])
		else
			puts "Skipping #{$options[:from]}/#{val}/strings.xml, file doesn't exits!"
		end
	end
end
puts "Done!"

else
puts "Input: " << $options[:inp]
puts "Output: " << $options[:out]
puts "Reference: " << $options[:ref] if $options[:ref]
syncxmlfile($options[:inp], $options[:out], $options[:strings], $options[:ref])
end





