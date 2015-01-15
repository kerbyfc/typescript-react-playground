var gulp        = require('gulp');
var browserify  = require('gulp-browserify');
var yaml        = require('gulp-yaml');
var replace     = require('gulp-replace');
var shell       = require('gulp-shell');
var cjsx2coffee = require('gulp-coffee-react-transform');
var plumber     = require('gulp-plumber');
var cjsx        = require('gulp-cjsx');
var rimraf      = require('gulp-rimraf');
var install     = require("gulp-install");

// var webserver   = require('gulp-webserver');

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
        './bower_components/react',
        './bower_components/react-router/dist/'
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

gulp.task('install', function() {
  return gulp.src(['./bower.yaml', './package.yaml'])
    .pipe(yaml({
      space: 2
    }))
    .pipe(gulp.dest('./'))
    .pipe(install())
});

gulp.task('init', ['install'], function() {
  return gulp.src(['./bower.json', './package.json'])
    .pipe(plumber())
    .pipe(rimraf())
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
  './node_modules/.bin/codo --undocumented --closure ./doc/sources | perl -pe "s/\\x1b\\[[0-9;]*m//g" | sed "s/'+process.cwd().replace(/\//g, "\\/")+'\\/doc\\/sources\\///" | sed "s/[│├┌┬┼┐┤┤┘┴└─]//g" | perl -pe "s/ \n//g" | tee .todoc'
]));

gulp.task('webserver', function() {
  gulp.src('build')
    .pipe(plumber())
    .pipe(webserver({
      // livereload: true,
      directoryListing: true
    }));
});

gulp.task('watch', function() {
  return gulp.watch([
    'src/**/*.coffee',
    'src/**/*.html',
    'src/**/*.yaml',
    'src/**/*.yml',
    '!node_modules',
    '!bower_components'
  ], [ 'build' ]);
});

gulp.task('build', [
  'config',
  'bundle',
  'html',
  'codo',
]);

gulp.task('serve', ['build'], function(){
  // gulp.start('webserver');
  gulp.start('watch');
});

gulp.task('default', ['init'], function() {
  gulp.start('serve');
});
