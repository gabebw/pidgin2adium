%%{
  machine thing;

  pre = '<head><meta http-equiv="content-type" content="text/html; charset=UTF-8"><title>Conversation with ';
  at = 'at';
  username_chars = [a-zA-Z0-9\%\+];
  username = username_chars+;
  date = [0-9/ ];
  hour = digit{1,2};
  colon = ':';
  time = [0-9 ];
  am_pm = [AP]'M';

  post = '</title></head>';

  first_line = pre username ' ' at;

  main := |*
    pre => {
      emit(:pre, data, token_array, ts, te)
    };

    username => {
      emit(:username, data, token_array, ts, te)
    };

    first_line => {
      emit(:first_line, data, token_array, ts, te)
    };
  *|;
}%%

%% write data;

def emit(token_name, data, target_array, ts, te)
  target_array << {name: token_name.to_sym, value: data[ts...te].pack("c*") }
end

def run_lexer(data)
  data = data.unpack("c*") if(data.is_a?(String))
  eof = data.length
  token_array = []

  %% write init;
  %% write exec;

  puts token_array.inspect
end

string = '<head><meta http-equiv="content-type" content="text/html; charset=UTF-8"><title>Conversation with aolsystemmsg at 10/13/2007 12:47:52 PM on jiggerificbug (aim)</title></head><h3>Conversation with aolsystemmsg at 10/13/2007 12:47:52 PM on jiggerificbug (aim)</h3>'
run_lexer(string)
