/*~

# Summary
* This macro parses a main file for include statements and will read specifically formatted comments to create code-generated documentation. 
* It does reads include files recursively as long as they have the format: %include "C:\dir\file.sas";
* The output is formatted as a markdown file, which can be transfered/translated in your file format of choice.
* The macro also reads included Stata files as long as the stata main is called using SAS' x command window and all relative path macro variables are identically defined in both SAS and Stata.
	
# Usage
## Comment block
The main file and included scripts need to incorporate specially formatted comment blocks to be included in the output file. An example is:
The special comment block is opened with:/**
The special comment block is closed with:*/
/*
An example of use inside the blocks is:
@main :title The best documentation ever
@main :authors Author One; Author Two; Author Three
@main :org Our Glorious Institute
@main :version 1.2.3
@main A general comment
@def ABC = The alphabet
@stat The p-values are calculated using the carrot test for bunnies
@note I'm writing this example on a Friday afternoon...
A line without keyword

## Single line comments
Parsable single line comments are also supported:
The line starts with: **
The line ends with: ;

## Document structure
The lines are all grabbed and can be organized by using @keyword for the same themes (e.g. @def in the example, will put all @def lines together). Use . as a seperator for multi-level keywords, e.g. @covar.cost.
There are a few special tags (e.g. @main :title) that grab the document metadata.
If a line within a comment block does not have a keyword it is seen as a continuation of the previous line (in the same block) 
	
The output can be converted to any format (e.g. pdf [needs latex installed], word, html) using pandoc. (See Google for details)
Go to the directory in the command window and use
* markdown to pdf: pandoc infile.txt --toc --latex-engine=pdflatex -o outfile.pdf
* markdown to word: pandoc -s -S infile.txt --toc -o outfile.docx
* markdown to html: pandoc -s infile.txt --toc -o outfile.htm
		
# Parameters	
* input_main_file = Is the main file for the sas project tree, all files/scripts called from this main will be read recursively. (e.g P:\project\source\main.sas)
* out_dir = Is the output folder (e.g. P:\project\)
* out_file = Is the resulting markdown file in which the results are written with script and line information. (e.g. workplan_coding.txt)
* out_file_scrubbed = Is the resulting markdown file in which the comments without script and line information is written. [Optional (e.g. workplan_output.txt')]
* debug_mode = Set to 1 to run in debug mode. (This does not delete macro data-sets for troubleshooting) [optional]
* section_aliases = This is the dataset with keyword aliases to cause multiple keywords to map to the same section [optional]. See example for structure.
* section_order = This is the dataset to overwrite the order of sections (all values should be negative, with the lowest order number coming first) [optional]. See example for structure.
* section_headers = This is the dataset to determine section headers [optional]. See example for structure.
* sections_scrubbed = This is the dataset with a list of sections to omit from the scrubbed file [optional]. See example for structure.

# Notes
* There is a practical limit to the number of include files because of the creation of the dataset _includes_&curr_script_no_text. When this exceeds 32 characters it will cause an error, because of internal sas limits.
* The maximum of several fields is hard-coded under the comment "Define character lengths" with several %let statements. Adjust these if needed for longer comments.
* The warning<br>WARNING: The quoted string currently being processed has become more than 262 characters long. You might have unbalanced quotation marks.<br>Is turned off for the duration of the macro.
* Keyword comments are all saved in their own intermediate datasets, which need to meet SAS 32 character limit. This should not cause any issues as long as keywords are 20 chars or less. (Use section_headers entries to define longer headings in the created report.)

# Example
The following example demonstrates the use of the macro, the section_: inputs should have the same variable names as the example:
data work.alias_list;
	infile datalines;
	input short_keyword $1-10 long_keyword $11-50;

	datalines;
cond      condition
cov       covariate
covar     covariate
def       definition
descr     descriptive
incl      inclusion
excl      exclusion
exp       exposure
out       outcome
var       variable
;

data work.order_list;
	infile datalines;
	input keyword $1-15 order_no 16-20;

	datalines;
todo           -999
assert         -998
main           -100
definition     -94
variable       -92
note           -90
inclusion      -85
exclusion      -80
condition      -70
exposure       -60
outcome        -50
covariate      -40
descriptive    -30
rate           -20
stat           -10
no_keyword     0
;

data work.header_list;
	infile datalines;
	input keyword $1-15 header $16-50;

	datalines;
condition      Condition criteria
covariate      Covariates
definition     Definitions
descriptive    Descriptive tables
exclusion      Exclusion criteria
exposure       Exposures
inclusion      Inclusion criteria
main           Main 
no_keyword     General
note           Notes
outcome        Outcomes
rate           Rate tables
stat           Statistics
todo           Task list
variable       Variables
;

data work.scrub_list;
	infile datalines;
	input keyword $1-15;

	datalines;
assert
todo
;

%parse_comments(
	input_main_file = &SOURCE_ROOT\main_sas.sas,
	out_dir = P:\project\
	out_file = workplan_coding.txt,
	out_file_scrubbed = workplan_output.txt,
	section_aliases = work.alias_list,
	section_order = work.order_list,
	section_headers = work.header_list,
	sections_scrubbed = work.scrub_list
);

# Final
Authors: Christiaan Righolt
Copyright (c) 2016 Vaccine and Drug Evaluation Centre, Winnipeg.

~*/

%macro code_diary(
	input_main_file = ,
	out_dir = ,
	out_file = ,
	out_file_scrubbed = '0' ,
	debug_mode = 0,
	section_aliases = _null_,
	section_order = _null_,
	section_headers = _null_,
	sections_scrubbed = _null_
);

	%put %STR( -> Start of %upcase( &sysmacroname ) macro );
	
	* Define local dataset names;
	%let scripts_ds = work._m_ds_scripts;
	%let all_source_ds = work._m_ds_source_all;
	%let output_lines_ds = work._m_ds_output_lines;
	
	* Define numbering parameters;
	%let main_script_no = 1;
	
	* Define character lengths;
	%let len_script_no = 31;
	%let len_line_no = 15;
	%let len_script = 255;
	%let len_line = 1023;
	
	* Check for existence of directories for output and create actual file names;
	%let rc = %sysfunc( filename(fileref, &out_dir) );
	%if not %sysfunc( fexist(&fileref) ) %then %do;
		%put ERROR: The save directory &out_dir does not exist.;
	%end;

	%let out_file_path = "&out_dir&out_file";
	%let out_file_scrubbed_path = "&out_dir&out_file_scrubbed";
	
	* Get original option for displaying 262 character warnings and turn it off for the duration of the macro;
	%let original_quotelenmax_value = %sysfunc( getoption(quotelenmax) );
	option noquotelenmax; 
	
	* Start script table with main file;
	* Start source table empty;
	proc sql noprint;
	
		create table &scripts_ds. 
			(
				script_no char(&len_script_no.),
				script char(&len_script.)
			);

		insert into &scripts_ds.
		values ("&main_script_no.", "&input_main_file.");
		
		create table &all_source_ds. 
			(
				script_no char(&len_script_no.),
				line_no num format=&len_line_no..,
				source_line char(&len_line.)
			);
		
	quit;
	
	* Recursively read through all included source code;
	%read_through_includes(
		input_file = &input_main_file.,
		script_ds = &scripts_ds.,
		source_lines_ds = &all_source_ds.,
		curr_script_no = &main_script_no.
	);
	
	* Add a script order number based on the occurence in the full source dataset;
	data &all_source_ds. (drop = last_script_no);
		set &all_source_ds.;

		retain last_script_no script_order_no;

		* The order number is the row if it is a new script, else it remains the same;
		if script_no ^= last_script_no then script_order_no = _N_;
		else script_order_no = script_order_no;

		last_script_no = script_no;
	run;

	* Order scripts by number using their occurence in the full source;
	* Use a join to get the numbers from &all_source_ds.;
	proc sql noprint;
	
		create table &scripts_ds._ordered as
		select S.script_no, S.script
		from &scripts_ds. as S
		inner join (
				select distinct script_no, script_order_no
				from &all_source_ds.
			) as ord
			on S.script_no = ord.script_no
		order by ord.script_order_no;
	
	quit;
	
	* Deal with script numbering for scripts that are included multiple times;
	proc sql noprint;
		
		* Find repeated scripts;
		create table &scripts_ds._repeated as
		select 
			script_no as old_script_no, 
			script, 
			('R' || min(script_no)) as new_script_no length=&len_script_no.,
			min(monotonic()) as order_no
		from &scripts_ds._ordered 
		group by script
		having count(*) > 1;
		
		create table &scripts_ds._rep_unique as
		select distinct new_script_no as script_no, script, order_no
		from &scripts_ds._repeated
		order by order_no;
		
		*Link their number to a repeat script number;
		update &scripts_ds._ordered as ord
		set script = (
			select rep.new_script_no 
			from &scripts_ds._repeated as rep
			where ord.script_no = rep.old_script_no
		)
		where script_no in (select old_script_no from &scripts_ds._repeated);

	quit;
	
	* Add repeated scripts to ordered set;
	data &scripts_ds._ordered;
		set &scripts_ds._ordered &scripts_ds._rep_unique;
		drop order_no;
	run;
	
	* Extract only formatted comment lines;
	* "/**" turns it on for the next line;
	* "*/" turns it off for this line;
	* First line of a script will be off;
	* Need two temp parameters to work, because of order of commands and retain statement;
	data _m_ds_source_comments (drop = is_comment use_line);
		set &all_source_ds.;
		retain is_comment use_line;
		by script_order_no;
		
		* Only a continued comment block if it is the second line in the block (put it before use_line is defined);
		if use_line = 1 then continued_comment_block = 1;
		else continued_comment_block = 0;
		
		if first.script_no then is_comment = 0;
		if find(source_line, '*/') then is_comment = 0;
		
		if is_comment then use_line = 1;
		else use_line = 0;
		
		/* If you update this line, ALSO UPDATE THE SECOND LINE AFTER ACCORDINGLY!!!*/
		if find(source_line, '/**') then is_comment = 1;
		/* But escape the line above when this comment parser file is included as part of main. */
		if find(source_line, "if find(source_line, '/**') then is_comment = 1;") then is_comment = 0;/**/
		
		if use_line;
	run;
	
	* Grab the inline comments and add them to the set;
	%let prx_grab_inline_comment = %str(s/(\*\*)(.*)(;)/$2/); * Grabs the comment;
	proc sql noprint;

		create table _m_ds_single_line_comments as
		select script_no,
			line_no,
			prxchange("&prx_grab_inline_comment.", -1, source_line) as source_line length=&len_line.,
			script_order_no,
			. as continued_comment_block
		from &all_source_ds.
		where strip(source_line) like '**%;';
		
		insert into _m_ds_source_comments
		select *
		from _m_ds_single_line_comments;

	quit;
	
	* Remove repeated comments from including the same file multiple times;
	* Rename script number, and only use first occurence;
	proc sql noprint;
	
		update _m_ds_source_comments as com
		set script_no = (
			select rep.new_script_no 
			from &scripts_ds._repeated as rep
			where com.script_no = rep.old_script_no
		)
		where script_no in (select old_script_no from &scripts_ds._repeated);

		create table _m_ds_source_comments_no_repeat as
		select distinct script_no, line_no, source_line, min(script_order_no) as script_order_no, continued_comment_block
		from _m_ds_source_comments
		group by script_no, line_no, source_line
		order by script_order_no, line_no;

	quit;
	
	* Set prx change commands for aliases;
	%let _m_prx_alias_changes = ;
	data _null_;
		set &section_aliases;
		
		call symput("iter_short_keyword", trim(short_keyword) );
		call symput("iter_long_keyword", trim(long_keyword) );
		
		call execute('
			%let prx_keyword_alias = "s/(^|[^a-z])(&iter_short_keyword.)($|[^a-z])/$1&iter_long_keyword.$3/";
			%let _m_prx_alias_changes = &_m_prx_alias_changes keyword = prxchange(&prx_keyword_alias., -1, keyword)%str(;);
		');
		
	run;
	
	* Extract keywords, comments;
	* Extract the special @main :tag keywords as well;
	%let prx_grab_keyword = 's/(.*@)([\w\.]+ )(.*)/$2/'; * Grabs the keyword;
	%let prx_grab_comment = 's/(.*@)([\w\.]+ )(.*)/$3/'; * Grabs the comment;
	%let prx_grab_tag = 's/(.*:)(\w+ )(.*)/$2/'; * Grabs the tag;
	%let prx_grab_tagline = 's/(.*:)(\w+ )(.*)/$3/'; * Grabs the tagline;
	data _m_ds_comments_with_keywords (drop = source_line last_keyword continued_comment_block prev_script_order_no prev_line_no);
		set _m_ds_source_comments_no_repeat;
		retain last_keyword;
		length comment $&len_line.;
		
		comment_no = _N_;
		keyword = lowcase(prxchange(&prx_grab_keyword., -1, source_line));
		comment = prxchange(&prx_grab_comment., -1, source_line);
		continued_item = 0; * Only overwritten to 1 if true;

		prev_script_order_no = lag(script_order_no);
		prev_line_no = lag(line_no);
		
		* If there is no keyword defined, then the full line is repeated in both keyword and comment by the regular expression.;
		* This is overwritten: Either it is a continued item (so the keyword is transfered), or no keyword is provided;
		if keyword = lowcase(comment) then do;
			* Allow continuation for either comment blocks (before |) and multiline two-star comments (after |);
			if continued_comment_block = 1 
					| ( 	
						missing(continued_comment_block) 
						& (prev_script_order_no=script_order_no) 
						& ((prev_line_no+1)=line_no) 
					) then do;
				keyword = last_keyword;
				continued_item = 1;
			end;
			else do;
				keyword = 'no_keyword';
			end;
		end;
		
		* Implement aliases for keywords;
		&_m_prx_alias_changes.;
		
		* Get special tags for main statment;
		if keyword = 'main' then
			do;
				tag = lowcase(prxchange(&prx_grab_tag., -1, comment));
				tagline = prxchange(&prx_grab_tagline., -1, comment);
				
				* If there is no tag defined, then the full line is repeated in both tag and tagline.;
				* Only use define macro variable when it is a tag;
				if tag = lowcase(tagline) then tag = '';
				else do;
					call symput('tag_name', trim(tag) );
					call symput('tagline_text', trim(tagline) );
				
					call execute('%let _main_&tag_name = &tagline_text.');
				end;
			end;
		
		* Only use lines that are not empty and are not special main tags;
		if comment ^= '' and tag = '';
		
		last_keyword = keyword;
		
		drop tag tagline;
	run;
	
	* Get list of unique keywords in source and their order of appearance;
	* Change _ to space for header;
	%let prx_underscore_to_space = 's/_/ /';
	%let prx_grab_keyword_parent = 's/(.*)(\.)(\w+)/$1/'; * Grabs the parent of the key word, e.g. section.header.paragraph --> section.header;
	%let prx_grab_keyword_lowest_level = 's/(.*)(\.)(\w+)/$3/'; * Grabs the lowest level of the key word, e.g. section.header.paragraph --> paragraph;
	proc sql noprint;

		create table _m_ds_keyword_list as
		select distinct 
			keyword, 
			prxchange(&prx_grab_keyword_parent., -1, keyword) as keyword_parent, 
			prxchange(&prx_grab_keyword_lowest_level., -1, keyword) as section_keyword, 
			prxchange(&prx_underscore_to_space., -1, propcase(calculated section_keyword)) as keyword_header, 
			min(comment_no) as keyword_order_no,
			( strip(calculated section_keyword) || strip(put(calculated keyword_order_no, &len_line_no..)) ) as section_ID
		from _m_ds_comments_with_keywords
		group by keyword;
		
		* Set parent as missing if self = parent;
		update _m_ds_keyword_list
		set keyword_parent = ""
		where keyword = keyword_parent;
		
		* Get the number of digits of the maximum order number;
		select length(compress( put(max(keyword_order_no), &len_line_no..) ))
		into :n_digits_keyword_order_no
		from _m_ds_keyword_list;

	quit;
	%let n_digits_keyword_order_no = %cmpres(&n_digits_keyword_order_no);
	
	* Add missing parents for orphaned sections;
	%let N_orphans = 1; * Initialization;
	%do %while (&N_orphans > 0);
		
		proc sql noprint;

			create table _m_ds_orphaned_sections as
			select child.* 
			from _m_ds_keyword_list as child 
			where not missing(child.keyword_parent) 
				and child.keyword_parent not in (select parent.keyword from _m_ds_keyword_list as parent);

			select count(*)
			into :N_orphans
			from _m_ds_orphaned_sections;
			
			* Distinct if multiple orphans have the same parents;
			* Write this step out to understand what happens, basically the parents characteristics are set based on the orphans;
			create table _m_ds_orphaned_sections_parents as
			select keyword_parent as keyword,
				prxchange(&prx_grab_keyword_parent., -1, keyword_parent) as keyword_parent, 
				prxchange(&prx_grab_keyword_lowest_level., -1, keyword_parent) as section_keyword, 
				prxchange(&prx_underscore_to_space., -1, propcase(calculated section_keyword)) as keyword_header, 
				min(keyword_order_no-1) as keyword_order_no,
				( strip(calculated section_keyword) || strip(put(min(keyword_order_no-1), &len_line_no..)) ) as section_ID
			from _m_ds_orphaned_sections
			group by keyword_parent;

			* Set parent as missing if self = parent;
			update _m_ds_orphaned_sections_parents
			set keyword_parent = ""
			where keyword = keyword_parent;

			* Include in list;
			insert into _m_ds_keyword_list
			select *
			from _m_ds_orphaned_sections_parents;

		quit;
		
		%put &N_orphans. orphan(s) found its/their parents.;
	%end;
	
	* Set commands to overwrite orders and section headers;
	%let _m_order_overwrite = ;
	data _null_;
		set &section_order;
		
		call symput("iter_keyword", trim(keyword) );
		call symput("iter_order", order_no );
		
		call execute('%let _m_order_overwrite = &_m_order_overwrite if keyword = "&iter_keyword" then keyword_order_no = &iter_order.%str(;);');
	run;
	
	%let _m_header_overwrite = ;
	data _null_;
		set &section_headers;
		
		call symput("iter_keyword", trim(keyword) );
		call symput("iter_header", trim(header) );
		
		call execute('%let _m_header_overwrite = &_m_header_overwrite if keyword = "&iter_keyword" then keyword_header = "&iter_header."%str(;);');
	run;
	
	* Overwrite automatically generated properties with inputted formats;
	data _m_ds_keyword_list;
		set _m_ds_keyword_list;
		
		* Overwrite order with use-defined order for keywords;
		&_m_order_overwrite.
		
		* Create user-defined headings;
		&_m_header_overwrite.
	run;
	
	* Overwrite default order for non-specified subsection (they should fall under the main header);
	proc sort
		data = _m_ds_keyword_list
		out = _m_ds_keyword_list;
		by keyword;
	run;

	data _m_ds_keyword_list (drop = last_order_no);
		set _m_ds_keyword_list;
		retain last_order_no;

		if not missing(keyword_parent) and (keyword_order_no > 0) then do;
			keyword_order_no = last_order_no + 0.001;
		end;

		last_order_no = keyword_order_no;
	run;
	
	* Sort keywords in order of printing;
	proc sort
		data = _m_ds_keyword_list
		out = _m_ds_keyword_list;
		by keyword_order_no;
	run;
	
	* Section merge section idea onto comment dataset;
	proc sql noprint;

		create table _m_ds_comments_with_keywords_IDd as
		select com.*, key.section_ID
		from _m_ds_comments_with_keywords as com
		left outer join _m_ds_keyword_list as key
			on com.keyword = key.keyword
		order by script_order_no, line_no;

	quit;
	
	* Create empty datesets for comment keywords;
	data _null_;
		set _m_ds_keyword_list;
	
		call symput('iter_keyword', trim(keyword) );
		call symput('iter_section_ID', trim(section_ID) );
		
		call execute('proc sql noprint;
			
			create table _CP_&iter_section_ID.
				(
					script_no char(&len_script_no.),
					line_no num format=&len_line_no..,
					comment char(&len_line.),
					continued_item num
				);
			
		quit;');
	run;
	
	* Add individual comments to keyword datasets;
	* Note that line_no is numeric;
	%let prx_change_double_quote = 's/"/""/'; * Change " to "" to be added to dataset properly;
	data _null_;
		set _m_ds_comments_with_keywords_IDd;
		
		call symput('iter_script_no', trim(script_no) );
		call symput('iter_line_no', line_no );
		call symput('iter_section_ID', trim(section_ID) );
		call symput('iter_comment', prxchange(&prx_change_double_quote., -1, trim(comment)));
		call symput('iter_continued_item', continued_item );
		
		call execute('proc sql noprint;

			insert into _CP_&iter_section_ID.
			values ("&iter_script_no.", &iter_line_no., "&iter_comment.", &iter_continued_item.);
			
		quit;');
	run;
	
	* Define necessary metadata vars if needed;
	%if not %symexist(_main_title) %then %let _main_title = Untitled;
	%if not %symexist(_main_authors) %then %let _main_authors = Anonymous;
	%if not %symexist(_main_org) %then %let _main_org = No organization listed;
	%if not %symexist(_main_version) %then %let _main_version = No version listed;

	* Delete the output if it already exists;
	* The file does not need to be opened;
	filename file_cod &out_file_path.;
	%let rc = %sysfunc(fdelete(file_cod));
	
	* Write out document information as pandoc metadata (@main :tag stuff, dates);
	%write_metadata(
		output_file = &out_file_path,
		doc_title = %bquote(&_main_title),
		version = %bquote(&_main_version),
		authors = %bquote(&_main_authors),
		org = %bquote(&_main_org)
	);
	
	* Create scrubbed file with header if required;
	%if &out_file_scrubbed_path. ~= '0' %then %do;
		* Delete the scrubbed output if it already exists;
		filename file_scr &out_file_scrubbed_path.;
		%let rc = %sysfunc(fdelete(file_scr));
		
		* Set up doc with pandoc metadata;
		%write_metadata(
			output_file = &out_file_scrubbed_path,
			doc_title = %bquote(&_main_title),
			version = %bquote(&_main_version),
			authors = %bquote(&_main_authors),
			org = %bquote(&_main_org)
		);
	%end;
	
	* Write out included scripts;
	data _null_;
		file &out_file_path. mod;
		
		put;
		put "# Scripts/macros used for project";
	run;
	data _null_;
		set &scripts_ds._ordered;
		
		file &out_file_path. mod;
		
		print_line = ("* " || strip(script_no) || ": " || strip(script));
		put print_line;
	run;	
	
	* Write the output line to a dataset first;
	* Create an empty dataset;
	proc sql noprint;
		
		create table &output_lines_ds. 
			(
				print_line char(&len_line.),
				print_line_scrubbed char(&len_line.),
				continued_item num
			);
		
	quit;
	
	* Set command for scrubbed sections;
	%let _m_scrub_section = ;
	data _null_;
		set &sections_scrubbed;
		
		call symput("iter_keyword", trim(keyword) );
		call execute('%let _m_scrub_section = &_m_scrub_section if keyword = "&iter_keyword." then scrub_section = 1%str(;);');
	run;
	
	* Write paragraphs into dataset based on keyword list;
	* Use call execute to go through this;
	data _null_;
		set _m_ds_keyword_list;
		
		file &out_file_path. mod;
		
		section_level_minus_1 = countc(keyword, ".");
		print_line_heading = (repeat('#', section_level_minus_1) || " " || trim(keyword_header));
		
		* Determine what sections to scrub;
		scrub_section = 0;
		&_m_scrub_section.
		
		call symput('iter_section_ID', trim(section_ID) );
		call symput('print_line_heading_var', trim(print_line_heading) );
		call symput('iter_scrub_section', scrub_section );
		
		* Now loop over the keyword dataset;
		call execute('%write_paragraph_to_ds(
			output_text_line_ds = &output_lines_ds.,
			paragraph_ds = _CP_&iter_section_ID.,
			paragraph_header = &print_line_heading_var.,
			scrub_section = &iter_scrub_section
		);');
		
	run;
	
	* Write this dataset to the output file(s);
	data _null_;
		set &output_lines_ds.;
		
		file &out_file_path. mod;
		
		* Print continued items with markdown code for connecting lines (two spaces) always print two spaces at end.;
		if continued_item = 1 then put "  " @;
		put print_line @;
		put "  ";
		
	run;
	
	* Write main data to scrubbed file if required;
	%if &out_file_scrubbed_path. ~= '0' %then %do;
		data _null_;
			set &output_lines_ds.;
			
			file &out_file_scrubbed_path. mod;
			* Avoid superfluous line breaks from scrubbed sections;
			if print_line_scrubbed =: "#" then put;
			
			* Print continued items with markdown code for connecting lines (two spaces) always print two spaces at end.;
			if not missing(print_line_scrubbed) then do;
				if continued_item = 1 then put "  " @;
				put print_line_scrubbed  @;
				put "  ";
			end;
		run;
	%end;
	
	* The file does not need to be closed;
	* So do nothing..;	
	
	* Clean up after script if not in debug mode;
	* Needs both run and quit to run and end;
	%if not &debug_mode. %then %do;
		proc datasets noprint;
			delete _includes_:;
			delete _in_stata_:;
			delete _cp_:;
			delete _m_ds_:;
		run; 
		quit;
	%end;
	
	* Turn warning option back to incoming value;
	option &original_quotelenmax_value.; 
	
	%put %STR( -> End of %upcase( &sysmacroname ) macro );
	
%mend;

* Go recursively through includes;
%macro read_through_includes(
	input_file = ,
	script_ds = ,
	source_lines_ds = ,
	curr_script_no =
	);
	
	%put Process code from script &curr_script_no in file &input_file;
	
	* Ensure some macro variable are local only;
	%local iter_script_no iter_script curr_script_no curr_script_no_text;
	
	* Have text version of current script number without dots in it;
	%let curr_script_no_text = %sysfunc(tranwrd( &curr_script_no., ., _ ));
	
	* Only do this when the file exists;
	%let rc2 = %sysfunc( filename(fileref, &input_file) );
	
	%if %sysfunc( fexist(&fileref) ) %then %do;
			
		* Read code for the current script;
		%read_file_lines(
			_input_file = &input_file.,
			_output_ds = _m_ds_current_file_content
		);
		
		* Add this code to the source table;
		proc sql noprint;
			
			insert into &source_lines_ds.
			select "&curr_script_no." as script_no, line_no, source_line
			from _m_ds_current_file_content;
			
		quit;
		
		* Now find the SAS include files with local script/include number and number of includes;
		%let prx_grab_include_file = 's/(.*include ")(.+)(".*)/$2/'; * Grabs the included script name;
		data _includes_&curr_script_no_text.;
			set _m_ds_current_file_content;
			source_line = lowcase(source_line);
			if prxmatch("/.*include.*\.sas.*/", source_line);
		run;
		data _includes_&curr_script_no_text.;
			set _includes_&curr_script_no_text.;
			
			length script_no $&len_script_no.;
			length script $&len_script.;
			
			script_no = ("&curr_script_no." || "." || strip(put(_N_, &len_script_no..)));
			script = prxchange(&prx_grab_include_file., -1, source_line);
			
			drop line_no source_line;
		run;
		
		* Detect included Stata do files: Called from sas or included in other stata do files;
		%let input_file_type = %sysfunc( prxchange(s/(.*\.)(\w+$)/$2/, -1, &input_file) );
		%let input_file_type = %sysfunc( lowcase( &input_file_type ));
		
		* Find stata files called from sas;
		%let prx_grab_stata_file = 's/(.*do ")(.+)(".*)/$2/'; * Grabs the included script name;
		%if "&input_file_type." = "sas" %then %do;
			data _in_stata_&curr_script_no_text.;
				set _m_ds_current_file_content;
				source_line = lowcase(source_line);
				if prxmatch("/x .*stata.*do.*\.do.*/", source_line);
			run;
			data _in_stata_&curr_script_no_text.;
				set _in_stata_&curr_script_no_text.;
				
				length script_no $&len_script_no.;
				length script $&len_script.;

				script_no = ("&curr_script_no." || ".s" || strip(put(_N_, &len_script_no..)));
				script = prxchange(&prx_grab_stata_file., -1, source_line);
				
				drop line_no source_line;
			run;
		%end;

		* Regex to obtain the include/run/do files needed, for three common Stata import / embedded-call types;
		*;
		* 1) parse --> do /path/to/file.do;
		* 2) parse --> do "/path/to/file.do";
		* 3) avoid --> global F8 "do "P:\project_name\source\main.do"";
		%let prx_grab_stata_file = 's/^[\s\/\*]*(include|run|do)"?[ \t]+"?([^"]+\.do)"*/$2/';

		* Regex to grab the included script name;
		%let prx_stata_local_to_sas_macro = "s/`(\w+)'/&$1/";
		%let prx_stata_global_to_sas_macro = "s/\$(\w+)/&$1/";

		* Find stata files called from stata;
		%if "&input_file_type." = "do" %then %do;
			data _in_stata_&curr_script_no_text.;
				set _m_ds_current_file_content;
				
				length script_no $&len_script_no.;
				length script $&len_script.;

				* select only the source lines of interest;
				source_line = lowcase(source_line);

				if prxmatch(&prx_grab_stata_file, source_line);

				script_no = ("&curr_script_no." || ".s" || strip(put(_N_, &len_script_no..)));
				script = prxchange(&prx_grab_stata_file., -1, source_line);
				script = prxchange(&prx_stata_local_to_sas_macro., -1, script);
				script = prxchange(&prx_stata_global_to_sas_macro., -1, script);

				drop line_no source_line;
			run;
		%end;
		
		* Add these other scripts to the include list and all included files to script table;
		proc sql noprint;
			
			insert into _includes_&curr_script_no_text.
			select script_no, script
			from _in_stata_&curr_script_no_text.;
			
			insert into &script_ds.
			select script_no, script
			from _includes_&curr_script_no_text.;
		
		quit;
		
		* Run the reading macro recursively in a datastep for each row;
		data _null_;
			set _includes_&curr_script_no_text.;
			
			call symput('iter_script_no', trim(script_no) );
			call symput('iter_script', trim(script) );
		
			call execute('%read_through_includes(
				input_file = &iter_script.,
				script_ds = &scripts_ds.,
				source_lines_ds = &source_lines_ds.,
				curr_script_no = &iter_script_no.
			)');
		run;
	
	%end;
%mend;

* Read files line-by-line and returns line numbers with text;
%macro read_file_lines(
	_input_file = ,
	_output_ds =
);
	
	data &_output_ds.;
		length source_line $&len_line.;

		infile "&_input_file.";
		input;

		line_no = _N_;
		source_line = compress(_infile_,,'c');

	run;

%mend;

* Write metadata info to file (pandoc style);
%macro write_metadata(
	output_file = ,
	doc_title = ,
	version = ,
	authors = ,
	org = 
);
	
	data _null_;
		file &output_file mod;
		
		* Title and version;
		put "% "@@;
		put "&doc_title. "@@;

		%if "&version" ^= "No version listed" %then %do;
			put "(v &version)";
		%end;
		%else %do;
			put;
		%end;
		
		* Authors;
		put "% "@@;
		put "&authors."@@;
		
		* Organization;
		%if "&org" ^= "No organization listed"  %then %do;
			put "; &org";
		%end;
		%else %do;
			put;
		%end;
		
		* Date;
		%let _date_today = %sysfunc( putn(%sysfunc( date() ), worddate20. ));
		put "% &_date_today";
	run;

%mend;

* Write an output paragraph to a dataset with all textlines from both print_line and print_line_scrubbed;
%macro write_paragraph_to_ds(
	output_text_line_ds = ,
	paragraph_ds = ,
	paragraph_header = ,
	scrub_section =
);
	
	%put Writing: &paragraph_header.;
	
	%if &scrub_section = 0 %then %do;
		%let scrubbed_paragraph_header = &paragraph_header;
	%end;
	%else %do;
		%let scrubbed_paragraph_header = ;
	%end;
	
	* Define locals;
	%local print_line_text;
	
	* Print linebreak and header to start;
	proc sql noprint;
	
		insert into &output_text_line_ds.
		values (" ", " ", 0)
		values ("&paragraph_header.", "&scrubbed_paragraph_header.", 0);
		
	quit;
	
	* Get data as printed lines;
	data _m_ds_paragraph_list;
		length line_start $2.;
		
		set &paragraph_ds.;
		
		* Allow for multi-line comments, start them properly depending on the case;
		if continued_item = 0 then line_start = "* ";
		else line_start = "";
		
		length print_line $&len_line.;
		length print_line_scrubbed $&len_line.;
		print_line = (line_start || strip(script_no) || ":" || strip(line_no) || " " || strip(comment));
		if &scrub_section = 0 then print_line_scrubbed = (line_start || strip(comment));
	run;
	
	proc sql noprint;
				
		insert into &output_text_line_ds.
		select print_line, print_line_scrubbed, continued_item
		from _m_ds_paragraph_list;
		
	quit;
	
%mend;
