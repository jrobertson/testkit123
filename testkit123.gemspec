Gem::Specification.new do |s|
  s.name = 'testkit123'
  s.version = '0.1.1'
  s.summary = 'Generates a test suite of files (for use with the testdata ' + 
      'gem) from a config file.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/testkit123.rb']
  s.add_runtime_dependency('rxfhelper', '~> 0.7', '>=0.7.0')
  s.add_runtime_dependency('simple-config', '~> 0.6', '>=0.6.4') 
  s.signing_key = '../privatekeys/testkit123.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/testkit123'
end
