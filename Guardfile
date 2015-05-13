# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# Uncomment to clear the screen before every task
clearing :on

## Guard internally checks for changes in the Guardfile and exits.
## If you want Guard to automatically start up again, run guard in a
## shell loop, e.g.:
##
##  $ while bundle exec guard; do echo "Restarting Guard..."; done
##
## Note: if you are using the `directories` clause above and you are not
## watching the project directory ('.'), then you will want to move
## the Guardfile to a watched dir and symlink it back, e.g.
#
#  $ mkdir config
#  $ mv Guardfile config/
#  $ ln -s config/Guardfile .
#
# and, you'll have to watch "config/Guardfile" instead of "Guardfile"

guard 'minitest' do

  # with Minitest::Unit
  watch(%r|^test/(.*)\/?test_(.*)\.rb|)
  watch(%r|^lib/immortus/(.*)\.rb|)     { |m| "test/immortus_#{m[1]}_test.rb" }
  watch(%r|^lib/(.*)([^/]+)\.rb|)     { |m| "test/#{m[1]}test_#{m[2]}.rb" }
  watch(%r|^test/test_helper\.rb|)    { "test" }

  # Rails 4 - App Files
  watch(%r|^app/controllers/(.*)\.rb|) { |m| "test/controllers/#{m[1]}_test.rb" }

  # Rails 4 - Test Files
  watch(%r|^test/controllers/(.*)\.rb|) { |m| "test/controllers/#{m[1]}.rb" }
  watch(%r|^test/integration/(.*)\.rb|) { |m| "test/integration/#{m[1]}.rb" }

end
