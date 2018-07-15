# Introducing the Testkit123 gem

    h = {
      templates: {
        testdata: 'http://rorbuilder.info/r/test_project/testdata.xml',
        testx: 'http://rorbuilder.info/r/test_project/test.rsf',
      },
      localpath: '/home/james/jamesrobertson.eu/test-ruby',
      datapath: '/home/james/rorbuilder/r/gemtest', 
      gemtest_url: 'http://rorbuilder.info/r/gemtest/',
      rubyver: 'ruby-2.5.1',
      debug: true
    }

    TestKit123.new(h).new_project('quiz_game', save: true).create_files

The above example demonstrates how to create a new test project and to create the associated files used to by the test framework called *testdata*.

## Files created

The *new_project* method created the file quiz_game.txt in the file directory */home/james/jamesrobertson.eu/test-ruby*.

The *create_files* method created the following files and directories:

* ~/rorbuilder/r/gemtest/quiz_game.rsf
* ~/rorbuilder/r/gemtest/quiz_game/testdata_quiz_game.xml
* ~/rorbuilder/r/gemtest/quiz_game/test_quiz_game.rb
* ~/jamesrobertson.eu/test-ruby/quiz_game/.testdata

## Template files used

testdata: 'http://rorbuilder.info/r/test_project/testdata.xml'

<pre>
&lt;tests&gt;
  &lt;summary&gt;
    &lt;title&gt;#{proj} testdata&lt;/title&gt;
    &lt;recordx_type&gt;polyrex&lt;/recordx_type&gt;
    &lt;schema&gt;tests/test[path,type,description]/io[type,*]&lt;/schema&gt;
    &lt;ruby_version&gt;#{config[:ruby_version]}&lt;/ruby_version&gt;
    &lt;script&gt;//job:test #{config[:http_gemtest]}#{proj}.rsf&lt;/script&gt;
    &lt;test_dir&gt;#{config[:local_path]}/#{proj}&lt;/test_dir&gt;    
  &lt;/summary&gt;
  &lt;records&gt;
    &lt;test id='1'&gt;
      &lt;summary&gt;
        &lt;path&gt;1&lt;/path&gt; 
        &lt;type&gt;string only&lt;/type&gt;
        &lt;description&gt;&lt;/description&gt;
        &lt;format_mask&gt;[!path] [!type] [!description]&lt;/format_mask&gt;
      &lt;/summary&gt;
      &lt;records&gt;
        &lt;input id='2'&gt;
          &lt;summary&gt;
            &lt;date&gt;1-Apr-2011#3:12pm&lt;/date&gt;
            &lt;times&gt;Mon-Fri 10:30-16:00&lt;/times&gt;
          &lt;/summary&gt;
          &lt;records&gt;&lt;/records&gt;
        &lt;/input&gt;
        &lt;output id='3'&gt;
          &lt;summary&gt;
            &lt;within&gt;true&lt;/within&gt;
          &lt;/summary&gt;
          &lt;records&gt;&lt;/records&gt;
        &lt;/output&gt;
      &lt;/records&gt;
    &lt;/test&gt;
  &lt;/records&gt;
&lt;/tests&gt;
</pre>

testx: 'http://rorbuilder.info/r/test_project/test.rsf'

<pre>
&lt;package&gt;
  &lt;job id='test'&gt;
    &lt;script src="http://rorbuilder.info/r/ruby/testdata.rb"/&gt;
    &lt;script src="http://rorbuilder.info/r/ruby/#{proj}.rb"/&gt;
    &lt;script src="#{config[:http_gemtest]}#{proj}/test_#{proj}.rb"/&gt;
    &lt;script&gt;
      
      &lt;![CDATA[ 
      
      file = '~/jamesrobertson.eu/test-ruby/#{proj}'
      this_path = File.expand_path(file)

      if this_path != Dir.pwd then
        puts "you must run this from script #{'#{this_path}'}" 
        exit
      end

      url = '#{config[:http_gemtest]}#{proj}/testdata_#{proj}.#{ext}'
      puts 'testing ..'
      test = Test#{classname}.new(url)
      test.debug = true if params.has_key? :debug
      id = params[:id] ? params[:id] : nil
      test.run id

      ]]&gt;
    &lt;/script&gt;
  &lt;/job&gt;
&lt;/package&gt;
</pre>

## Resources

* testkit123 https://rubygems.org/gems/testkit123

test testing gem testdata config
