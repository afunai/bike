require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name              = 'bike'
    gem.rubyforge_project = 'bike'
    gem.summary           = 'The laziest web application framework'
    gem.description       = <<'_eos'
Bike is a web application framework that can make feature-rich apps by HTML files only.
You need no database setup (by default), no scheme definition, no command-line voodoo.
Just put a good old HTML file under skin/, and your new app is already running.
_eos

    gem.authors  = ['Akira FUNAI']
    gem.email    = 'akira@funai.com'
    gem.homepage = 'http://github.com/afunai/bike'

    gem.files = FileList[
      'bin/*',
      'lib/**/*.rb',
      'locale/**/*',
      'skel/*',
      'skel/skin/**/*',
      't/*',
      't/locale/**/*',
      't/skin/**/*',
    ].to_a
    gem.test_files = FileList['t/test_*.rb']
    gem.executables = ['bike']

    gem.add_dependency('rack',    '>= 0.9')
    gem.add_dependency('sequel',  '>= 3.0')
    gem.add_dependency('ya2yaml', '>= 0.26')

    gem.add_development_dependency('gettext',      '>= 2.1.0')
    gem.add_development_dependency('jeweler',      '>= 1.4.0')
    gem.add_development_dependency('mocha',        '>= 0.9.8')
    gem.add_development_dependency('quick_magick', '>= 0.7.4')
    gem.add_development_dependency('sqlite3-ruby', '>= 1.2.5')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 't'
  test.pattern = 't/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 't'
    test.pattern = 't/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "bike #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
