#!/usr/bin/env ruby
# coding: utf-8

require 'json'
require 'optparse'

option={}
OptionParser.new do |opt|
  opt.banner = "Usage: #{__FILE__} [options] security_group.json"
  opt.on('-a',   'Enable ALL (= cdgt)')   {|v| option[:a] = v}
  opt.on('-c',   'show group chain')         {|v| option[:c] = v}  
  opt.on('-d',   'show Description')   {|v| option[:d] = v}
  opt.on('-g VALUE', 'show this group only. example: sg-12345678')   {|v| option[:g] = v}
  

  opt.on('-t',   'show TAG')   {|v| option[:t] = v}
  opt.on('--no-ipp', 'Disable to show IpPermission') {|v| option[:ipp] = v}
  
  opt.parse!(ARGV)
end

if option[:a]
  option[:c] = true  
  option[:t] = true
  option[:d] = true
end

def checkIpPermissions(args = {}, sg = {})
  if args['UserIdGroupPairs']
    args['UserIdGroupPairs'].each do |k|
      checkUserIdGroupPairs(k, sg)
    end
  end
end

def checkIpPermissionsEgress(args = {}, sg = {})
  if args['UserIdGroupPairs']
    args['UserIdGroupPairs'].each do |k|
      checkUserIdGroupPairs(k, sg)
    end
  end
end

def checkUserIdGroupPairs(args = {}, sg = {})
  groupId = sg['GroupId']
  sg[:relation].push args
end

def showGroupRelation(sg = {})
  sg[:relation].each do |k|
    if k['GroupId'] == sg['GroupId']
      puts "\t[Group] self reference"
      next
    end
    
    if k['GroupName']
      puts "\t[Group] referred by " + k['GroupId'] +" ((" + k['GroupName'] + "))"
    else
      puts "\t[Group] referred by " + k['GroupId']
    end
  end
end

def writeDotFile(sgdot = {}, sgs = [])
  File.open("output.dot", "w") do |io|

    labels = Hash.new
    
    sgs.each do |k|
      if k['GroupName']
        labels.store(k['GroupId'], k)
      end
    end
  
    sgdot.each do |root,children|
      children.each do |child|
        if child['GroupName']
          labels.store(child['GroupId'], child)
        end
      end
    end

    io.puts "digraph SecurityGroupChain {"
    
    labels.each do |gid, child|
      if child['GroupName']
        io.puts '"' + gid + '" [label="' + child['GroupId'] + '/'  + child['GroupName'] + '"];'
      else
        io.puts '"' + gid + '" [label="' + child['GroupId'] + '"];'
      end
    end
    

    sgdot.each do |root,children|
      children.each do |child|
        labels.store(child['GroupId'], child)
        io.puts '"' + root + '" -> "' + child['GroupId'] + '";'
      end
    end    

    io.puts "}"
  end
end

sgdot = Hash.new
sgs = ''
if ARGV[0]
  open(ARGV[0]) do |io|
    sgs = JSON.load io
  end
else
  sgs = JSON.load $stdin
end

sgs = sgs["SecurityGroups"]

sgs.each do |sg|
  if option[:g]
    unless option[:g] == sg['GroupId']
      next
    end
  end
  
  sg[:relation] = Array.new
  begin
    puts sg['GroupId']
    puts "\tTags: " + sg['Tags'].to_s if option[:t]
    puts "\tDescritption: " + sg['Description'].to_s if option[:d]

    next if option[:ipp] == false

    puts "\tIpPermissions: #"+ sg['IpPermissions'].size.to_s   
    sg['IpPermissions'].each do |k|
      checkIpPermissions(k, sg)
    end

    puts "\tIpPermissionsEgress: #"+ sg['IpPermissionsEgress'].size.to_s   
    sg['IpPermissionsEgress'].each do |k|
      checkIpPermissionsEgress(k, sg)
    end
        
  rescue
    puts "******* ERROR *******"
    p $!
    p sg
  end
  sg[:relation].uniq!
  showGroupRelation(sg) if option[:c]
  sgdot.store(sg['GroupId'],sg[:relation])
end

writeDotFile(sgdot,sgs)

