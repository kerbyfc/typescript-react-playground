var gulp        = require('gulp');
var browserify  = require('gulp-browserify');
var webserver   = require('gulp-webserver');
var yaml        = require('gulp-yaml');
var cjsx        = require('gulp-cjsx');
var replace     = require('gulp-replace');
var transform   = require('coffee-react-transform');
var shell       = require('gulp-shell');
var cjsx2coffee = require('gulp-coffee-react-transform');
var plumber     = require('gulp-plumber');

var paths = {
  js:     [ 'build/**/*.js'   ],
  coffee: [ 'src/**/*.coffee' ],
  html:   [ 'src/*.html'      ],
  yaml:   [ 'src/**/*.yml'    ]
};

gulp.task('cjsx', function() {
  return gulp.src(paths.coffee)
    .pipe(plumber())
    .pipe(cjsx({bare: true}))
    .pipe(gulp.dest('./build'));
});

gulp.task('bundle', ['cjsx'], function() {
  return gulp.src('./build/bootstrap.js')
    .pipe(plumber())
    .pipe(browserify({
      paths: [
        // source
        './build',
        './build/framework',

        // vendors
        './node_modules',
        './bower_components',
      ],
      shim: {
        jquery: {
          path: './bower_components/jquery/dist/jquery.js',
          exports: 'jQuery'
        },
        lodash: {
          path: './bower_components/lodash/dist/lodash.js',
          exports: '_'
        }
      }
    }))
    .pipe(gulp.dest('build'));
});

gulp.task('scripts', ['cjsx', 'bundle']);

gulp.task('html', function() {
  return gulp.src('./src/*.html')
    .pipe(plumber())
    .pipe(gulp.dest('./build'));
});

gulp.task('config', function() {
  return gulp.src('./src/config.yml')
    .pipe(plumber())
    .pipe(yaml({
      space: 2
    }))
    .pipe(gulp.dest('./build'));
});

gulp.task('transform', function () {
  return gulp.src('./src/**/*.coffee', {read: false})
    .pipe(plumber())
    .pipe(shell(
      [
        'echo <%= f(file.path) %>',
      ],{
      templateData: {
        f: function (s) {
          return s.replace(/$/, '.bak')
        }
      }
    }));
});

gulp.task('cleanupDocSources', shell.task([
  'rm -rf ./doc/sources'
]));

gulp.task('cjsx2coffee', ['cleanupDocSources'], function(){
  return gulp.src(paths.coffee)
    .pipe(plumber())
    .pipe(cjsx2coffee())
    .pipe(gulp.dest('./doc/sources'))
});

gulp.task('codo', ['cjsx2coffee'], shell.task([
  'codo'
]));

gulp.task('webserver', function() {
  gulp.src('build')
    .pipe(plumber())
    .pipe(webserver({
      livereload: true,
      directoryListing: true
    }));
});

gulp.task('watch', function() {
  gulp.watch( paths.coffee , [ 'scripts' ]);
  gulp.watch( paths.html   , [ 'html'    ]);
  gulp.watch( paths.yaml   , [ 'config'  ]);
  gulp.watch( paths.js     , [ 'codo'    ]);
});

gulp.task('default', [
  'config',
  'watch',
  'scripts',
  'html',
  'codo',
  'webserver'
]);
