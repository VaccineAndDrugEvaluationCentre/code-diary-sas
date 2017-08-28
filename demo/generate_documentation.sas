%include "&MACRO_ROOT.code_diary.sas";
%include "&MACRO_ROOT.convert_markdown_to_html.sas";

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
	input keyword $1-20 order_no 21-25;

	datalines;
todo                -30
exclusion           -20
exclusion.time      -19
exclusion.person    -18
methods             -10
no_keyword          0
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

%code_diary(
	input_main_file = &DEMO_ROOT.project_main.sas,
	out_dir = &DEMO_ROOT,
	out_file = output-coder.md,
	out_file_scrubbed = output-for-all.md,
	debug_mode = 0,
	section_aliases = work.alias_list,
	section_order = work.order_list,
	section_headers = work.header_list,
	sections_scrubbed = work.scrub_list
);

%convert_markdown_to_html(
	in_file_md = "&DEMO_ROOT.output-for-all.md",
	out_file_html = "&DEMO_ROOT.output-for-all.htm",
	debug_mode = 0
);
