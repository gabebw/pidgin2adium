#include <ruby.h>

#ifndef RARRAY_LEN
#define RARRAY_LEN(arr)  RARRAY(arr)->len
#define RARRAY_PTR(arr)  RARRAY(arr)->ptr
#define RSTRING_LEN(str) RSTRING(str)->len
//#define RSTRING_PTR(str) RSTRING(str)->ptr
#endif

VALUE balance_tags_c(VALUE, VALUE);
static VALUE mP2A;

/*
    # Balances tags of string using a modified stack. Returns a balanced
    # string, but also affects the text passed into it!
    # Use text = balance_tags(text).
    
    # From Wordpress's formatting.php; rewritten in Ruby by Gabe
    # Berke-Williams, 2009.
    # Author:: Leonard Lin <leonard@acm.org>
    # License:: GPL v2.0
    # Copyright:: November 4, 2001
*/

VALUE balance_tags_c(VALUE mod, VALUE text){
    if( TYPE(text) != T_STRING ){
	rb_raise(rb_eArgError, "bad argument to balance_tags, String only please.");
    }
    VALUE tagstack = rb_ary_new2(1);
    int stacksize = 0;
    VALUE tagqueue = rb_str_new2("");
    VALUE ZERO = INT2FIX(0),
	  ONE = INT2FIX(1);
    VALUE newtext = rb_str_new2("");
    // Known single-entity/self-closing tags
    VALUE single_tags = rb_ary_new3(5,
	    rb_str_new2("br"),
	    rb_str_new2("hr"),
	    rb_str_new2("img"),
	    rb_str_new2("input"),
	    rb_str_new2("meta"));
    // Tags that can be immediately nested within themselves
    VALUE nestable_tags = rb_ary_new3(4,
	    rb_str_new2("blockquote"),
	    rb_str_new2("div"),
	    rb_str_new2("span"),
	    rb_str_new2("font"));
    // 1: tagname, with possible leading "/"
    // 2: attributes
    //tag_regex = /<(\/?\w*)\s*([^>]*)>/
    VALUE tag_regex = rb_reg_regcomp(rb_str_new2("<(\\/?\\w*)\\s*([^>]*)>"));
    VALUE pos;  // position in text
    VALUE match;
    VALUE tag;
    VALUE attributes;
    VALUE t; // loop variable when iterating over tagstack at end of while loop
    int matchlen;
    int done = 0;
    int j, k, i; // loop counters

    // WP bug fix for comments - in case you REALLY meant to type '< !--'
    rb_funcall(text, rb_intern("gsub!"), 2,
	    rb_str_new2("< !--"),
	    rb_str_new2("<    !--"));

    // WP bug fix for LOVE <3 (and other situations with '<' before a number)
    rb_funcall(text, rb_intern("gsub!"), 2,
	    rb_reg_regcomp(rb_str_new2("<([0-9]{1})")),
	    rb_str_new2("&lt;\\1"));

    pos = rb_funcall(text, rb_intern("=~"), 1, tag_regex);
    done = (pos == Qnil);
    //rb_io_puts(1, &pos, rb_defout);
    while ( ! done ){
	rb_str_concat(newtext, tagqueue); // newtext << tagqueue
	match = rb_funcall(text, rb_intern("match"), 1, tag_regex);
	tag = rb_funcall(rb_reg_nth_match(1, match), rb_intern("downcase"), 0);
	attributes = rb_reg_nth_match(2, match);

	matchlen = NUM2INT(rb_funcall(rb_reg_nth_match(0, match), rb_intern("size"), 0));

	// clear the shifter
	tagqueue = rb_str_new2("");
	// Pop or Push
	if (0 == rb_str_cmp(rb_str_substr(tag, 0, 1), rb_str_new2("/"))){ // End Tag
	    rb_funcall(tag, rb_intern("slice!"), 2, ZERO, ONE);
	    // if too many closing tags
	    if(stacksize <= 0){
		tag = rb_str_new2("");
		//or close to be safe: tag = '/' << tag
	    } else if (0 == rb_str_cmp(RARRAY_PTR(tagstack)[stacksize - 1], tag)){
		// found closing tag
		// if stacktop value == tag close value then pop
		// tag = '</' << tag << '>' # Close Tag
		// Close Tag
		tag = rb_str_append(rb_str_new2("</"), tag);
		rb_str_concat(tag, rb_str_new2(">")); 
		// Pop
		rb_ary_pop(tagstack);
		stacksize--;
		} else { // closing tag not at top, search for it
		    for(j=stacksize-1; j>=0; j--){
			if(0 == rb_str_cmp(RARRAY_PTR(tagstack)[j], tag) ){
			    // add tag to tagqueue
			    for(k = stacksize-1;k>=j;k--){
				//tagqueue << '</' << tagstack.pop << '>';
				rb_str_concat(tagqueue, rb_str_new2("</"));
				rb_str_concat(tagqueue, rb_ary_pop(tagstack));
				rb_str_concat(tagqueue, rb_str_new2(">"));
				stacksize--;
			    }
			    break;
			}
		    }
		    tag = rb_str_new2("");
		}
	    } else {
		// Begin Tag

		// Tag Cleaning

		if( ( RSTRING_LEN(attributes) > 0 && // test length before rb_str_substr
		    (0 == rb_str_cmp(rb_str_substr(attributes, -1, 1), rb_str_new2("/"))) ) ||
			(0 == rb_str_cmp(tag, rb_str_new2(""))) ){
		    // If: self-closing or '', don't do anything.
		} else if ( rb_ary_includes(single_tags, tag) ) {
		    // ElseIf: it's a known single-entity tag but it doesn't close itself, do so
		    rb_str_concat(attributes, rb_str_new2("/"));
		} else {
		    // Push the tag onto the stack
		    // If the top of the stack is the same as the tag we want
		    // to push, close previous tag
		    if ( (stacksize > 0) &&
			(Qfalse == rb_ary_includes(nestable_tags, tag)) &&
			(0 == rb_str_cmp(rb_ary_entry(tagstack, stacksize - 1), tag))){
			//tagqueue = '</' << tagstack.pop << '>'
			tagqueue = rb_str_new2("</");
			rb_str_concat(tagqueue, rb_ary_pop(tagstack));
			rb_str_concat(tagqueue, rb_str_new2(">"));
			stacksize--; 
		    }
		    rb_ary_push(tagstack, tag);
		    stacksize++;
		}

		// Attributes
		if( 0 != rb_str_cmp(attributes, rb_str_new2("")) ){
		    attributes = rb_str_plus(rb_str_new2(" "), attributes);
		}
		//tag = '<' << tag << attributes << '>'
		tag = rb_str_plus(rb_str_new2("<"), tag);
		rb_str_concat(tag, attributes);
		rb_str_concat(tag, rb_str_new2(">"));
		//If already queuing a close tag, then put this tag on, too
		//if( tagqueue)
		if( RSTRING_LEN(tagqueue) > 0 ){
		    rb_str_concat(tagqueue, tag);
		    tag = rb_str_new2("");
		}
	    }
	    //newtext << text[0,pos] << tag
	    rb_str_concat(newtext,
		    //rb_str_plus(rb_str_substr(text, 0, pos), tag));
		    rb_str_plus(rb_str_substr(text, 0, pos-1), tag));
	    //text = text[pos+matchlen, text.length - (pos+matchlen)]
	    text = rb_str_substr(text,
		    NUM2INT(pos)+matchlen,
		    RSTRING_LEN(text) - (NUM2INT(pos)+matchlen));
	    pos = rb_funcall(text, rb_intern("=~"), 1, tag_regex);
	    done = (pos == Qnil);
	}

	// Clear Tag Queue
	rb_str_concat(newtext, tagqueue);

	// Add Remaining text
	rb_str_concat(newtext, text);

	i = NUM2INT(rb_funcall(tagstack, rb_intern("length"), 0)) - 1;
	// Empty Stack
	for(; i >= 0; i--){
	    // Add remaining tags to close
	    t = RARRAY_PTR(tagstack)[i];
	    rb_str_concat(newtext, rb_str_new2("</"));
	    rb_str_concat(newtext, t);
	    rb_str_concat(newtext, rb_str_new2(">"));
	}

	// WP fix for the bug with HTML comments
	//newtext.gsub!("< !--", "<!--")
	rb_funcall(newtext, rb_intern("gsub!"), 2,
		rb_str_new2("< !--"),
		rb_str_new2("<!--"));
	//newtext.gsub!("<    !--", "< !--")
	rb_funcall(newtext, rb_intern("gsub!"), 2,
		rb_str_new2("<    !--"),
		rb_str_new2("< !--"));

	return newtext;
}

void Init_balance_tags_c(){
    mP2A = rb_define_module("Pidgin2Adium");
    rb_define_module_function(mP2A, "balance_tags_c", balance_tags_c, 1);
}
