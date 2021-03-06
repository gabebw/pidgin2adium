### HEAD (unreleased)

* Users can specify a custom output directory with `-o`/`--out`
* Extract `ArgumentParser` class
* Drop support for Ruby 1.9.x (#20)

### 4.0.0.beta2

* Extract `Pidgin2Adium::Cli`
* Fix bugs
* Print error and progress messages

### 4.0.0.beta1

* Massive refactoring
* Use Pipio gem to parse logs
* Chat times respect time zones instead of assuming inputs are UTC
* Test against Travis

### 3.3.0 / 2011-10-16
* Pidgin2Adium depended on itself for some reason. Now it doesn't.

### 3.2.3 / 2010-11-08
* Be more liberal in what Pidgin2Adium accepts when parsing the date and
  getting basic time info for the first line. Thanks to Matthew Jakubowski for
  helping me fix this bug.

### 3.2.2 / 2010-11-08
* Use DateTime#strftime to get dates in xmlschema format. DateTime#xmlschema
  doesn't exist in Ruby 1.8, and Ruby 1.9 has DateTime#iso8601, not
  DateTime#xmlschema. Just use strftime. Thanks to Matthew Jakubowski for
  pointing this bug out.

### 3.2.1 / 2010-11-08
* Use straight `DateTime.parse` when possible, and only fall back on hacky
  `Date._strptime` when we have to.

### 3.2.0 / 2010-10-12
* Last release broke 1.8 compatibility due to use of strptime. 1.8 and 1.9
  both work in 3.2.0.
* Moved Pidgin2Adium::VERSION to its own file

### 3.1.1 / 2010-08-13
* Moved BasicParser and its subclasses into parsers/ subdir.
  - You can now do `require 'pidgin2adium/parsers/all'`,
    though the old `require 'pidgin2adium/log_parser'` will still work
* Moved Message and its subclasses into messages/ subdir
  - You can now do `require 'pidgin2adium/messages/all'`,
    though the old `require 'pidgin2adium/message'` will still work

### 3.1.0 / 2010-08-13
* Compatible with Ruby 1.9!
  - removed dependency on `parsedate` library, which 1.9 doesn't have
* `log_parser.rb` has been split into separate files (1 per class, more or less)
  - `require pidgin2adium/log_parser` will still pull in all of the split-up
    classes
* `balance_tags_c` extension really does work now
* Cleans up more junk from Pidgin logfiles when parsing
* Bugfixes and more graceful handling of error states
* Fully tested (except bin/pidgin2adium, which remains tricky)

### 3.0.1 / 2010-08-07
Bugfix release.

* `balance_tags_c.c`: Use `rb_eval_string` instead of `rb_reg_regcomp` to avoid
  segfaults (commit #733ce88b0836256e14f0, fixes #27811)

Non-user-facing stuff:

* Switched to Jeweler, RSpec, and Bundler
* Rakefile now doesn't choke if Hanna gem isn't installed

### 3.0.0 / 2010-01-31
* `lbalance_tags.rb` is now a C extension (`Pidgin2Adium.balance_tags_c`)
  - the pure-ruby mixin `balance_tags` (without the trailing `_c`) is gone
* Better handling of command-line arguments
* Format time zones offsets correctly (e.g. "+0500", not "+-0500")
* Write Yahoo! and Jabber logs to correct directories (#27710)
* Better matching of regexes against time strings
* Better documentation

### 2.0.2 / 2009-12-18
* Much better documentation (more of it, and higher quality too!)
* Allow user-provided output dir at commandline
* Cleaner error messages
* require 'time' for `Time.zone_offset` (fixes bug)
* Gracefully handle lack of timezone info
* Gracefully handle nonexistent output dir
* Gracefully handle parsing errors
* Print error messages during *and* after batch converting so they're actually seen

### 2.0.1 / 2009-12-06
* Fix timestamps so they show up in Adium chat log viewer

### 2.0.0 / 2009-11-24
* Added documentation, available at http://pidgin2adium.rubyforge.org/rdoc/
* Added public interface for scripting purposes
* Removed -o and -l options. Now gem automatically outputs to Adium log dir with no intermediate folder.

### 1.0.0 / 2009-09-27
* Birthday!
