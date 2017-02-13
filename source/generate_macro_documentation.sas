/*~
Script to parse the macro and script documentation for the VDEC source folder
~*/

%include "P:\VDEC\source\documentation\parse_macros-v1_0_0.sas";
%include "P:\VDEC\source\documentation\convert_markdown_to_html-v1_0_1.sas";

%parse_macros(
	source_dir = P:\VDEC\source\,
	out_file_md = 'P:\VDEC\source\VDEC_source_documentation.txt',
	debug_mode = 0
);

%convert_markdown_to_html(
	in_file_md = 'P:\VDEC\source\VDEC_source_documentation.txt',
	out_file_html = 'P:\VDEC\source\VDEC_source_documentation.htm',
	debug_mode = 0
);
