* Define folders;
%let DEMO_ROOT = %qsubstr(%sysget(SAS_EXECFILEPATH),1,%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname)));
%let GIT_ROOT = %qsubstr(&DEMO_ROOT,1,%length(&DEMO_ROOT)-5);
%let MACRO_ROOT = %qsubstr(&DEMO_ROOT,1,%length(&DEMO_ROOT)-5)source\;

* Includes;
%include "&MACRO_ROOT.macro_diary.sas";
%include "&MACRO_ROOT.convert_markdown_to_html.sas";

%macro_diary(
	source_dir = &GIT_ROOT,
	out_file_md = "&DEMO_ROOT.output-macro-documentation.md",
	debug_mode = 0
);

%convert_markdown_to_html(
	in_file_md = "&DEMO_ROOT.output-macro-documentation.md",
	out_file_html = "&DEMO_ROOT.output-macro-documentation.htm",
	debug_mode = 0
);
