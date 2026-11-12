# frozen_string_literal: true

# Usage: ruby [--yjit|--zjit] bench/bench.rb [seconds_per_benchmark]
#
# Prints iterations/sec (by process CPU time, median of batches) for each
# workload over the pbxproj fixtures. Set NANAIMO_LIB to benchmark another
# checkout's lib directory, ONLY=parse,write_xml to select workloads.

$LOAD_PATH.unshift(ENV['NANAIMO_LIB'] || File.expand_path('../lib', __dir__))
require 'nanaimo'

CLOCK = Process::CLOCK_PROCESS_CPUTIME_ID
SECONDS = Float(ARGV[0] || 3)
FIXTURES = Dir[File.expand_path('../spec/fixtures/*/project.pbxproj', __dir__)].sort.map { |f| File.read(f) }.freeze
PLISTS = FIXTURES.map { |s| Nanaimo::Reader.new(s).parse! }.freeze
RUBY_PLISTS = PLISTS.map { |p| Nanaimo::Plist.new(p.as_ruby, :ascii) }.freeze

WORKLOADS = {
  'parse' => -> { FIXTURES.each { |s| Nanaimo::Reader.new(s).parse! } },
  'as_ruby' => -> { PLISTS.each(&:as_ruby) },
  'write_ascii' => -> { PLISTS.each { |p| Nanaimo::Writer.new(p).write } },
  'write_pbxproj' => -> { PLISTS.each { |p| Nanaimo::Writer::PBXProjWriter.new(p).write } },
  'write_pbxproj_ruby' => -> { RUBY_PLISTS.each { |p| Nanaimo::Writer::PBXProjWriter.new(p).write } },
  'write_xml' => -> { RUBY_PLISTS.each { |p| Nanaimo::Writer::XMLWriter.new(p).write } },
  'roundtrip' => -> { FIXTURES.each { |s| Nanaimo::Writer::PBXProjWriter.new(Nanaimo::Reader.new(s).parse!).write } }
}.freeze

def measure(work)
  # Warm up (lets the JIT compile), then time batches and take the median rate.
  warm_until = Process.clock_gettime(CLOCK) + [SECONDS / 3, 0.5].max
  work.call while Process.clock_gettime(CLOCK) < warm_until

  GC.start
  rates = []
  deadline = Process.clock_gettime(CLOCK) + SECONDS
  while Process.clock_gettime(CLOCK) < deadline
    t0 = Process.clock_gettime(CLOCK)
    work.call
    rates << 1.0 / (Process.clock_gettime(CLOCK) - t0)
  end
  rates.sort!
  rates[rates.size / 2]
end

jit = if defined?(RubyVM::ZJIT) && RubyVM::ZJIT.enabled?
        'zjit'
      elsif defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
        'yjit'
      else
        'interp'
      end
puts "# #{RUBY_DESCRIPTION} (#{jit})"
only = ENV['ONLY']&.split(',')
WORKLOADS.each do |name, work|
  next if only && !only.include?(name)

  printf("%-20s %10.2f i/s\n", name, measure(work))
end
