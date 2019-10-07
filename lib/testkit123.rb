#!/usr/bin/env ruby

# file: testkit123.rb

require 'rxfhelper'
require 'fileutils'
require 'testdata_text'
require 'simple-config'


module StringFormat
  
  refine String do
    
    def camelize
      self.split('_').collect(&:capitalize).join 
    end
    
  end
  
end

class TestKit123
  using StringFormat
  using ColouredText
  
  def initialize(templates: {testdata: nil, testx: nil}, project: nil, 
        debug: false, localpath: nil, datapath: nil, 
        gemtest_url: nil, rubyver: 'ruby-2.5.1')

    @debug = debug
    @h = templates
    
    @project_config = if project =~ /\.txt$/ then
      project
    elsif project
      File.join(localpath, project + '.txt')      
    end
    puts '@project_config: ' + @project_config.inspect if @debug
    

    @localpath, @datapath, @gemtest_url = localpath, datapath, gemtest_url
    @rubyver = rubyver

  end

  def create_files(project=@project_config)

    puts 'running create_files ...' if @debug

    puts '1) Reading the config file' if @debug
    raise "missing the config file " unless @project_config
    raise "config file not found" unless File.exists? @project_config

    config_file = @project_config
    
    puts 'config_file: ' + config_file.inspect if @debug
    
    config = SimpleConfig.new(config_file).to_h
    puts 'config : ' + config.inspect if @debug

    rbfile_buffer = config[:test][:items].join "\n"

    puts 'before project' if @debug
    proj = config[:project]
    classname = config[:classname]

    puts 'proj: ' + proj.inspect if @debug

    filepath = config[:local_path] + '/' + proj
    puts 'filepath: ' + filepath.inspect if @debug
    datafilepath = config[:data_path] + '/' + proj

    puts 'before ext' if @debug

    ext = config[:testdata_ext][/\.?td$/] ? 'td' : 'xml'

    puts 'before stage 2' if @debug

    puts '2) Making directory for file path ' + filepath.inspect if @debug
    FileUtils.mkdir_p filepath

    puts '3) Writing the .testdata file' if @debug
    buffer = config[:http_gemtest] + "%s/testdata_%s.%s" % ([proj, proj, ext])
    File.write filepath + '/.testdata', buffer

    puts '4) Creating the working code tests from templates' if @debug
    # fetch the template testdata

    testdata = @h[:testdata].gsub(/(?<=\.)\w+$/, ext)
    puts 'testdata: ' + testdata.inspect if @debug
    buffer_testdata, _ = RXFHelper.read(testdata)
    
    FileUtils.mkdir_p datafilepath
    
    testdata_file = File.join(datafilepath, "testdata_#{proj}.#{ext}")
    File.write testdata_file, eval('%{' + buffer_testdata + '}') 

    test_template_rsf = @h[:testx]
    buffer_test, _ = RXFHelper.read(test_template_rsf)

    test_rsffile = File.join(config[:data_path], "#{proj}.rsf")
    File.write test_rsffile, eval('%{' + buffer_test + '}') 

buffer_rb = %{#!/usr/bin/env ruby

# file: test_#{proj}.rb

#require 'timecop'

    
class Test#{config[:classname]} < Testdata::Base
  
  # 2011-07-24 19:52:15
  #Timecop.freeze(Time.local(2011, 7, 24, 19, 52, 15))

  def tests()

#{rbfile_buffer.lines.map {|x| ' '*4 + x}.join}

  end
end
}

    test_rbfile = File.join(datafilepath, "test_#{proj}.rb")
    puts 'reading the ruby template file ...' if @debug
    File.write test_rbfile, eval('%{' + buffer_rb + '}') 

    "finished processing #{proj}"
  end
  
  def create_standalone(n)
    
    # use the test number to find the test to copy from the test file
    
    config = SimpleConfig.new(@project_config, debug: false).to_h
    puts ('config: ' + config.inspect).debug if @debug
    
    proj = config[:project]
    puts 'create_standalone: proj: ' + proj.inspect if @debug
    datafilepath = config[:data_path] + '/' + proj
    test_rbfile = File.join(datafilepath, "test_#{proj}.rb")    
    
    ext = config[:testdata_ext][/\.?td$/] ? 'td' : 'xml'
    testdata_file = File.join(datafilepath, "testdata_#{proj}.#{ext}")
    puts 'testdata_file: ' + testdata_file.inspect if @debug
    puts 'source code filepath: '  + test_rbfile.inspect if @debug
    
    s = File.read(test_rbfile).gsub(/^(  )?end/,'')
    require_gems = s.scan(/^require +['"]([^'"]+)/).map(&:first)
    
    before_test = s[/(?<=def tests\(\)).*/m].split(/    test /)[0].lstrip
    puts '** before_test: ' + before_test.inspect

    a = s.split(/(?=    test )/)
    a.shift
    puts 'a: ' + a.inspect if @debug
    
    tests = a.map do |x|
      r = x.match(/(?<=['"])(?<test>[^"']+)['"]\s+do\s+\|(?<raw_args>[^\|]+)/)
      
      [r[:test], r[:raw_args].split(/, */)]
    end

    s2 , filetype = RXFHelper.read testdata_file
    puts 'filetype: ' + filetype.inspect if @debug

    xml = if s2.lstrip[0] == '<' then
      s2
    else
      TestdataText.parse s2
    end

    puts 'xml: ' + xml.inspect if @debug
    
    doc = Rexle.new(xml)
    puts 'after doc : ' if @debug
    r = doc.root.xpath('records//test') || doc.root.xpath('records/test')
    
    if @debug then
      puts 'r: ' + r.inspect 
      puts 'r.length: '  + r.length.inspect
      puts 'n: ' + n.inspect
    end
    
    testnode = r[n-1]
    puts 'testnode: ' + testnode.xml.inspect if @debug
    
    title = testnode.text('summary/type')
    puts ('title: ' + title.inspect).debug if @debug
    puts ('tests: ' + tests.inspect).debug if @debug
    i = tests.index tests.assoc(title)
    puts 'i: ' + i.inspect if @debug
        
    testcode = a[i].strip.lines[1..-2].map do |line|
      line.sub(/^ {6}/,'')
    end.join
    
    # replace the input variable names with the input variable names defined 
    # in the testdata file and prefix them with *test_*.
    
    input_vars = testnode.xpath('records/input/summary/*/name()')
    
    puts 'input_vars: '  + input_vars.inspect
    puts 'tests[i][1]: '  + tests[i][1].inspect
    puts 'zip: ' + tests[i][1].zip(input_vars).inspect
    tests[i][1].zip(input_vars).each do |x|
      testcode.gsub!(x[0], 'test_' + x[1])
    end  

    args = testnode.xpath('records/input/summary/*').map do |input|
      "test_%s =<<EOF\n%s\nEOF\n" % [input.name, 
                                     input.texts.join.gsub(/'/,"\'").strip]
    end
    
    vars = testnode.xpath('records/input/summary/*').map(&:name)
    
    puts 'args: ' + args.inspect if @debug    
    
    vars.each do |var|
      testcode.gsub!(/\b#{var}\b/, 'test_' + var)
    end
    
    puts 'gems: ' + require_gems.inspect if @debug
    
    codex = testcode.rstrip.lines
    
    "# Test %d. Type: %s\n# Description: %s\n" \
        % [n, title, testnode.text('summary/type')] + \
    "# --------------------------------------------\n\n" + \
    "require '#{proj}'\n" + require_gems.map {|x| "require '%s'" \
                                              % x}.join("\n") + "\n\n\n" \
     + before_test.gsub(/^    /,'') + "\n" + args.join("\n") \
     + codex[0..-2].join + 'puts ' + codex.last

  end

  def delete_files(s=nil)
    
    filepath = if s =~ /\.txt$/ then
      project
    elsif s
      File.join(@localpath, s + '.txt')      
    else
      @project_config
    end
    
    puts 'filepath: ' + filepath.inspect if @debug
    
    config = SimpleConfig.new(filepath).to_h
    
    proj = config[:project]
    datafilepath = config[:data_path] + '/' + proj
    FileUtils.rm_rf datafilepath
        
    filepath = config[:local_path] + '/' + proj
    FileUtils.rm_rf filepath
    
    FileUtils.rm File.join(config[:data_path], "#{proj}.rsf")
    
    proj + ' test files deleted'
    
  end
  
  def make_testdata(s)
    
    inputs = s.scan(/test_([\w]+) += +['"]([^'"]+)/)\
        .inject({}){|r,x| r.merge(x.first.to_sym => x.last)}    
    
    h = {
      _test: {
        summary: {
          path: '',
          type: '',
          description: ''
        },
        records: {
          input: {
            summary: inputs,
            records: {}
          },
          output: {
            summary: {result: ''},
            records: {}
          }
        }      
      }
    }

    a = RexleBuilder.new(h, debug: false).to_a

    Rexle.new(a).xml pretty: true
    
  end

  def new_project(project='myproject', classname=nil, save: false)

    classname ||= project.camelize

s =<<EOF
project: #{project}
classname: #{classname}
local_path: #{@localpath || '~/test-ruby'}
data_path: #{@datapath || '~/gemtest'}
http_gemtest: #{@gemtest_url || 'http://mywebsite.com/r/gemtest/'}
ruby_version: #{@rubyver}

# testdata_ext defaults to .xml

testdata_ext: .xml
test:

  test 'to_s only' do |filepath|

    #{classname}.new(filepath).to_s

  end
EOF


    if save then
      filepath = File.join(@localpath, project + '.txt')
      File.write filepath, s
      puts 'file saved ' + filepath if @debug
      @project_config = filepath
      self
    else
      s
    end

  end

end

