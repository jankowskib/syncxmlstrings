#!/usr/bin/env ruby

require 'optparse'
require 'colorize'
require 'fileutils'

def syncxmlfile(fin, fout, keys, fref = nil)
	
	folder = /^.*(values.*)\//.match(fin)[1]
	if not File.exists?(fin) or not File.exists?(fout) then
		print "#{folder} [NO_FILE] ".red
		return {}
	end

	strs = {}
	newstrs = {}
	refstrs = {}
	xmlNewData = File.read(fin)
	xmlOrgData = File.read(fout)
	changes = 0
	
	strexp = /^\s*\<string\s*name="(\w*)"\s*(?:product="\w*"|\s*)\s*(?:msgid="\w*"|\s*)\s*(?:formatted="(\w*)"|\s*)\s*\>(.*?)\<\/string\>/m
	
	if fref
		xmlRefData = File.read(fref)
		xmlRefData.scan(strexp) do |a,b,c|
			refstrs[a] = {:formatted => b == "false" ? false : true, :content => c }
		end
	end
	
	xmlOrgData.scan(strexp) do |a,b,c|
		strs[a] = {:formatted => b == "false" ? false : true, :content => c }
	end
	entries = strs.length
	
	xmlNewData.scan(strexp) do |a,b,c|
		newstrs[a] = {:formatted => b == "false" ? false : true, :content => c }
	end
			
	strs.each do |s,c|
		if $options[:clean] == true && !refstrs.has_key?(s) then
			puts "[R] " + s + ": '" + c[:content] + "'" if $options[:verbose]
			strs.delete(s)
			next
		end
		
		next if !newstrs.has_key?(s)
		if $options[:ask] == true && newstrs[s] != strs[s] then
			puts "#{s}:".green
			print "#{c[:content]} -> #{newstrs[s][:content]} [y/n/a]: "
			prompt = gets.upcase
			if(prompt == "A\n")
				puts "Adding remaining changes..."
				$options[:ask] = false
			elsif(prompt != "Y\n" && prompt != "\n")
				next
			end
		end
		
		if newstrs[s] != strs[s] && $options[:replace] == false
			puts "[M] " + s + ": '" + c[:content] + "' -> '" + newstrs[s][:content] + "'" if $options[:verbose]
			strs[s] = newstrs[s]
			changes+=1
		end
		
	end
	
	newstrs.each do |s,c|	
		next if !refstrs.empty? && !refstrs.has_key?(s)

		if !strs.has_key?(s)
			puts "[A] " + s + ": '" + c[:content] + "'" if $options[:verbose]
			strs[s] = newstrs[s]
			changes+=1
		end
	end

	if changes>0
		print "#{folder} [#{changes}/#{entries}] ".yellow 
		strs
	else
		{}
	end
end



$options = {}
$options[:ask] = false
$options[:replace] = false
$options[:verbose] = false
$options[:dirmode] = false
$options[:look] = false
$options[:quick] = false
$options[:clean] = false

OptionParser.new do |opts|
	opts.banner = "Usage:\n
To sync single file: syncxmlstrings.rb [options] --i[nput] <file.xml> --o[utput] <file.xml>
	or
To sync every strings from directory: syncxmlstrings.rb [options] --f[rom] <directory> --t[o] <directory>
options: --[v]erbose --[a]sk, -r --dont-replace, --[m]aster <file.xml>, --[l]ook-for-master (dir sync mode only), --s[trings] <str1>,<str2> ... --[j]ust-add-missing (dir sync mode only) --[c]lean"
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
	opts.on("-r", "--dont-replace", "Replace existing keys") do |v|
		$options[:replace] = true
	end
	opts.on("-l", "--look-for-master", "Uses strings.xml from /values/ as reference. Directory mode only") do |v|
		$options[:look] = true
	end
	opts.on("-j", "--just-add-missing", "Adds only missing strings.xml files. Directory mode only") do |v|
		$options[:quick] = true
	end
	opts.on("-c", "--clean", "Remove strings not included in refrence file. Use with -m or -l") do |v|
		$options[:clean] = true
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

if !$options[:dirmode] && ($options[:quick] || $options[:look])
	puts "Incorrect option combination"
	puts "Type syncxmlstrings.rb --help to see usage!"
	exit
end


puts "Synced strings: " << $options[:strings] if $options[:strings]

if $options[:dirmode] then
	puts "Input directory: " + $options[:from] 
	puts "Output directory: " + $options[:to]
		if $options[:look] && File.exists?("#{$options[:from]}/values/strings.xml")
			puts "Using reference: " + "#{$options[:from]}/values/strings.xml"
			$options[:ref] = "#{$options[:from]}/values/strings.xml"
		end
	puts "Legend: ".colorize(:default) << "up to date ".green << "modified [changes/entries]".yellow << "copied ".blue << "error [type]".red
	Dir.entries($options[:from]).select { |file| File.directory? File.join($options[:from], file) }.each do |val|
		if val=~/values.*/ then
			if File.exists?("#{$options[:to]}/#{val}/strings.xml") then
				next if $options[:quick]
				strs = syncxmlfile("#{$options[:from]}/#{val}/strings.xml","#{$options[:to]}/#{val}/strings.xml", $options[:strings], $options[:ref])
					if strs.empty?
						print "#{val} ".green
						next
					end
				File.open("#{$options[:to]}/#{val}/strings.xml", 'wb') do |f| 
					f.write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<resources>\n") 
					entry = ""
					strs.each do |s,c| 
						entry << "    <string name=\"#{s}\""
						entry << ' formatted="false"' if not c[:formatted]
						entry << ">#{c[:content]}"
						entry << "</string>\n"
					end
					f.write entry
					f.write("</resources>")
				end
			elsif File.exists?("#{$options[:from]}/#{val}/strings.xml")
				print "#{val} ".blue
				FileUtils.mkdir "#{$options[:to]}/#{val}/" if not File.directory?("#{$options[:to]}/#{val}/")
				FileUtils.cp("#{$options[:from]}/#{val}/strings.xml", "#{$options[:to]}/#{val}/")
			end
		end
	end
	puts "\nDone!".green
else
	puts "Input: " << $options[:inp]
	puts "Output: " << $options[:out]
	puts "Reference: " << $options[:ref] if $options[:ref]
	strs = syncxmlfile($options[:inp], $options[:out], $options[:strings], $options[:ref])
	if strs.empty?
		puts "#{$options[:inp]}: Up to date...".green
		exit
	end
	
	puts "#{$options[:inp]}: Syncing...".green
	File.open($options[:out], 'wb') do |file| 
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
