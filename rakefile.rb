############################
#          VERT.X          #
############################

namespace "vertx" do

  # run main vert.x module
  task :start do
    system("vertx/bin/vertx runmod iw~tm~web")
  end

  # link vertx modules (http://vertx.io/dev_guide.html#run-your-module-and-see-your-changes-immediately)
  task :link do
    # search all .classpath files
    Dir.glob "./**/.classpath" do |file|
      dir = File.dirname file

      paths = []
      # read relative paths from .classpath file
      # and transform them to absolute
      File.open file, "r" do |f|
        f.each_line do |path|
          paths << File.expand_path(
            File.join(dir, path)
          )
        end
      end

      # save vertx_classpath for
      # each vertx module
      File.write(
        File.join(dir, "vertx_classpath.txt"),
        paths.join
     )

      # link vertx module
      # to be able to find it in fs
      File.write(
        File.join(dir, "module.link"),
        File.expand_path(dir)
      )
    end
  end

end

############################
#        MULTITASKS        #
############################

# default task (just $rake)
task default: %w[run]

# run all install tasks
multitask :install => [
  "vertx:link",
]

# run all deploy tasks
multitask :run => [
  "vertx:start"
]
