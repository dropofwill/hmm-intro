module.exports = function(grunt) {
  [ 'grunt-contrib-coffee',
    'grunt-contrib-watch' ].forEach(grunt.loadNpmTasks);

  grunt.initConfig({
    coffee: {
      compile: {
        options: {
          sourceMap: true
        },
        files: {
           // compile and concat into single file
          'lib/main.js': ['src/*.coffee']
        }
      },
    },

    watch: {
      js: {
        files: 'src/*.coffee',
        tasks: ['dev']
      }
    }
  });

  grunt.registerTask('dev', [ 'coffee:compile' ]);
};
