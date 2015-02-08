# pidgin2adium [![Build Status][travis]](http://travis-ci.org/gabebw/pidgin2adium) [![Code Climate][codeclimate]](https://codeclimate.com/github/gabebw/pidgin2adium)

[travis]: https://travis-ci.org/gabebw/pidgin2adium.svg?branch=master
[codeclimate]: https://codeclimate.com/github/gabebw/pidgin2adium.svg

Convert [Pidgin](http://pidgin.im/) (formerly gaim) logs to the
[Adium](http://adium.im/) format. This is a command-line wrapper around the
[Pipio] log-parsing library.

[Pipio]: https://github.com/gabebw/pipio

## Install

    gem install pidgin2adium

## Quick Start

Let's say you have some logs in `~/pidgin-logs`, and your aliases are "Gabe
B-W", "Gabe", and "Gabe Berke-Williams". Then you should run this:

    pidgin2adium --in ~/pidgin-logs --aliases "Gabe B-W,Gabe,Gabe Berke-Williams"

By default, `pidgin2adium` outputs logs to the directory that Adium looks for
logs in. If you want to customize the output directory, use the `--out` option:

    pidgin2adium --in ~/pidgin-logs --aliases "Gabe B-W,Gabe" -o ./output-dir

## OK, what's with the aliases?

Pidgin2adium needs a comma-separated list of your aliases to work. Aliases make
it so that you show up in chats as (for example) `Me` instead of as
`best_screen_name_ever_018845`.

Pidgin then uses aliases in the log file instead of the actual screen name,
which makes it impossible to match "Me" to your actual screen name.  Therefore
Pidgin2adium needs to know which aliases belong to you so it can map them to the
correct screen name.

If Pidgin2adium encounters an alias that you did not list, it assumes that it
belongs to the person to whom you are chatting.

You do not need to provide your screenname in the alias list.

## Testing

To get a coverage report, run `rake` with the `COVERAGE` environment variable
set:

    COVERAGE=1 rake

## THANKS

With thanks to Li Ma, whose [blog post](http://li-ma.blogspot.com/2008/10/pidgin-log-file-to-adium-log-converter.html)
helped tremendously.

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2009-2014 Gabe Berke-Williams. See LICENSE for details.
