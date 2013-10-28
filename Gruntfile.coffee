module.exports = (grunt) ->
  # Paths
  sourceDir = 'app' # Where the source lives
  buildDir = 'public' # Where fully minified and concatenated output code lives
  configDir = 'etc' # Where to put config files
  vendorDir = 'bower_components' # Where the package-managed vendor files are

  # Load Grunt tasks
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-conventional-changelog'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-bump'
  grunt.loadNpmTasks 'grunt-exec'
  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-concurrent'

  # Configuration
  grunt.initConfig
    # Package metadata
    pkg: grunt.file.readJSON 'package.json'

    # Automatic changelog
    changelog:
      options:
        dest: 'CHANGELOG.md'
        template: 'etc/changelog.tpl'

    # Bump version to both Bower and NPM
    bump:
      options:
        files: ['package.json', 'bower.json']
        commit: false
        commitMessage: 'chore(release): v%VERSION%'
        commitFiles: ['package.json', 'client/bower.json']
        createTag: false
        tagName: 'v%VERSION%'
        tagMessage: 'Version %VERSION%'
        push: false
        pushTo: 'origin'

    # Clean house
    clean:
      build: ['public']

    # Watch
    watch:
      options:
        livereload: true
      # Run test case
      test:
        files: ["#{sourceDir}/**/*"]
        tasks: ['karma:unit:run']

    # Testing
    karma:
      options:
        configFile: "#{configDir}/karma.conf.coffee"
        browsers: ['PhantomJS']
        reporters: 'dots'
      unit:
        browsers: ['ChromeCanary']
      continuous:
        singleRun: true

    # Concurrently run watch and server
    concurrent:
      options:
        limit: 4
        logConcurrentOutput: true
      # When developing, just run the server and watch for changes
      develop: [
        # Start the Karma server
        'karma:unit:start'
        # Re-assemble on change
        'exec:brunchWatch'
        # Run tests on change
        'watch:test'
        # Run local web server
        'exec:harpServer'
      ]

    ## Execute arbitrary commands

    exec:
      # Install Bower components
      bower:
        cmd: 'node_modules/.bin/bower install'
      # Compile for development with Brunch
      brunchCompile:
        cmd: 'node_modules/.bin/brunch build'
      # Build for production with Brunch
      brunchBuild:
        cmd: 'node_modules/.bin/brunch build -P'
      # Watch for changes for re-assembly
      brunchWatch:
        cmd: 'node_modules/.bin/brunch watch'
      # Run Harp server
      harpServer:
        cmd: "node_modules/.bin/harp server #{buildDir}"
      # Kill the harp server and force exit peacefully no matter what
      harpKill:
        cmd: 'etc/kill_harp.sh'

  ## Build tasks

  # Usually you just want to run `grunt` to enter development mode
  grunt.registerTask 'default', [
    'init'
    'exec:harpKill'
    'concurrent:develop'
  ]

  # Continuous integration mode
  grunt.registerTask 'continuous', [
    'init'
    'exec:brunchCompile'
    'karma:continuous:start'
  ]

  # Build for production
  grunt.registerTask 'build', [
    'init'
    'exec:brunchBuild'
  ]

  # Setup
  grunt.registerTask 'init', [
    'exec:bower'
  ]
