require 'awesome_print'

# Given a quo.aut file, generate the transitions
# @return: hash: s1 -> s2 -> action
def generate_transitions(quo)
  trans = {}
  File.open(quo, 'r').read.split("\n").each do |line|
    next if line =~ /des/
    s, a, t = line.scan(/(\d+), (.*), (\d+)/)[0]
    trans[s] = {} unless trans.key?(s)
    trans[s][t] = a
  end
  trans
end

# This function extracts the sub LTS that starts from s in quo.aut
def extract_from_state(s, quo)
  trans = generate_transitions(quo)
  ss = [s]
  visited = {}
  File.open('output/tmp.aut', 'wb') do |f|
    until ss.empty?
      cur_s = ss.shift
      next if visited.key?(cur_s)
      next unless trans.key?(cur_s)
      visited[cur_s] = nil
      trans[cur_s].each_key do |k|
        f.puts("(#{cur_s}, #{trans[cur_s][k]}, #{k})")
        ss << k unless visited.key?(k)
      end
    end
  end
  puts 'file exported to output/tmp.aut.'
end

extract_from_state(2321.to_s, ARGV[0])
