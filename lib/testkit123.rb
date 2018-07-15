#!/usr/bin/env ruby

# file: testkit123.rb

require 'rxfhelper'
require 'fileutils'
require 'simple-config'


class String
  def camelize
    self.split('_').collect(&:capitalize).join 
  end
end

class TestKit123

  def initialize(templates: {testdata: nil, testx: nil}, project: nil, 
        testdata: nil, debug: false, localpath: nil, datapath: nil, 
        gemtest_url: nil, rubyver: 'ruby-2.5.1')

    @h = templates
    @project_config = project
    @testdata, @debug = testdata, debug
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

class Test#{config[:classname]} < Testdata::Base

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
  
  def create_standalone()
  end

  def destroy_files()
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

