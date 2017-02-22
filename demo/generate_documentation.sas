%include "parse_comments-v1_1_1.sas";
%include "convert_markdown_to_html-v1_0_1.sas";

* Set up workplan section style;
data work.alias_list;
	infile datalines;
	input short_keyword $1-10 long_keyword $11-50;

	datalines;
excl      exclusion
stat      statistics
;

data work.order_list;
	infile datalines;
	input keyword $1-15 order_no 16-20;

	datalines;
todo           -30
exclusion      -20
methods        -10
no_keyword     0
;

data work.header_list;
	infile datalines;
	input keyword $1-15 header $16-50;

	datalines;
exclusion      Exclusion criteria
person         Subjects
time           Time periods
todo           Task list
;

data work.scrub_list;
	infile datalines;
	input keyword $1-15;

	datalines;
todo
;

%parse_comments(
	input_main_file = main.sas,
	out_file = '.\output_coder.md',
	out_file_scrubbed = '.\output_for_all.md',
	debug_mode = 0,
	section_aliases = work.alias_list,
	section_order = work.order_list,
	section_headers = work.header_list,
	sections_scrubbed = work.scrub_list
);

%convert_markdown_to_html(
	in_file_md = 'output_for_all.md',
	out_file_html = 'output_for_all.htm',
	debug_mode = 0
);