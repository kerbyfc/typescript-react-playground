include FileUtils

# default task (just $rake)
task default: %w[run]

# run all install tasks
multitask :install => [
  "vertx:install",
  "vertx:link",
  "project:create_symlinks"
]

# run all deploy tasks
multitask :run => [
  "web:start"
]

namespace "project" do

  task :create_symlinks do
    if File.exists? ".symlinks"
      File.open ".symlinks", "r" do |f|
        f.each_line do |paths|
          begin
            link, target = paths.split ":"
            link = File.expand_path(link)
            target = File.expand_path target.sub(/\n/, '')
            puts "create symlink: #{target} -> #{link}"
            FileUtils.ln_sf target, link
          rescue NotImplementedError
            puts "Symlinks are not supported"
          rescue
            puts "File not found"
          end
        end
      end
    else
      puts ".symlinks file not found"
    end
  end
end

# vertx.io
namespace "vertx" do

  task :install do

  end

  # link vertx modules (http://vertx.io/dev_guide.html#run-your-module-and-see-your-changes-immediately)
  task :link do
    # search all .classpath files
    Dir.glob "./**/.classpath" do |file|
      dir = File.dirname file

      # read relative paths from .classpath file
      # and transform them to absolute
      paths = []
      File.open file, "r" do |f|
        f.each_line do |path|
          path =  File.expand_path(File.join(dir, path))
          paths << path
        end
      end

      # save classpath
      File.write File.join(dir, "vertx_classpath.txt"), paths.join

      # link vertx module
      File.write File.join(dir, "module.link"), File.expand_path(dir)
    end
  end

end

