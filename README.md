# pidgin2adium [![Build Status](https://secure.travis-ci.org/gabebw/pidgin2adium.png)](http://travis-ci.org/gabebw/pidgin2adium)

Convert [Pidgin](http://pidgin.im/) (formerly gaim) logs to the
[Adium](http://adium.im/) format.

## For the impatient

This parses a log file and loops through the returned LogFile.

    require 'pidgin2adium'
    logfile = Pidgin2Adium.parse("/path/to/log/file.html", "gabe,gbw,gabeb-w")
    if logfile
      logfile.each do |message|
        # Every Message subclass has sender, time, and buddy_alias
        puts "Sender's screen name: #{message.sender}"
        puts "Time message was sent: #{message.time}"
        puts "Sender's alias: #{message.buddy_alias}"
        if message.respond_to?(:body)
          puts "Message body: #{message.body}"
          if message.respond_to?(:event) # Pidgin2Adium::Event class
            puts "Event type: #{message.event_type}"
          end
        elsif message.respond_to?(:status) # Pidgin2Adium::StatusMessage
          puts "Status: #{message.status}"
        end
        # Prints out the message in Adium log format
        puts message.to_s
      end
    else
      puts "Oh no! Could not parse!"
    end

## The fine print

This library needs access to aliases to work correctly, which may require a bit
of explanation. Adium and Pidgin allow you to set aliases for buddies as well as
for yourself, so that you show up in chats as (for example) `Me` instead of as
`best_screen_name_ever_018845`.

However, Pidgin then uses aliases in the log file instead of the actual screen
name, which complicates things. To parse properly, this gem needs to know which
aliases belong to you so it can map them to the correct screen name. If it
encounters an alias that you did not list,  it assumes that it belongs to the
person to whom you are chatting. Note that aliases are lower-cased and space is
removed, so providing `Gabe B-W, GBW` is the same as providing `gabeb-w,gbw`.

You do not need to provide your screenname in the alias list.


## INSTALL

    gem install pidgin2adium

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

Copyright (c) 2011 Gabe Berke-Williams. See LICENSE for details.
