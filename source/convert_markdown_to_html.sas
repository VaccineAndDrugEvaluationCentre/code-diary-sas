/*~
# Summary
Macro to convert a markdown style document to html. This is not supposed to supplant proper tools like pandoc, but only to aid visualization on a closed system that does not allow the installation of software.

# Usage
The tool automatically creates a table of contents

The tool supports the following markdown markup:
* Pandoc-style metadata prefixed with %
* Headers prefixed with N # depending on the level (e.g. #### is 4th level)
* Unordered lists prefixed with *
* Order lists prefixed with n.

Not supported is:
* Nested lists
* Bold/italic text
* Links, images etc.

# Parameters
* in_file_md = = The input markdown file with documentation (e.g. "C:\source\source_documentation.md"")
* out_file_html = = The output html file with documentation (e.g. "C:\source\source_documentation.htm"")
* debug_mode = Use debug mode or not [0 or 1, optional]
  
# Final
Authors: Christiaan Righolt
Copyright (c) 2016 Vaccine and Drug Evaluation Centre, Winnipeg.

~*/

%macro convert_markdown_to_html(
	in_file_md = ,
	out_file_html = ,
	debug_mode = 0
);

	%put %STR( -> Start of %upcase( &sysmacroname ) macro );
	
	* Define character lengths;
	%let len_line = 1023;
	
	* First read in the dataset;
	data _m_ds_file_source;
		length input_line $&len_line.;

		infile &in_file_md.;
		input;

		input_line = compress(_infile_,,'c');
	run;
	
	* Detect markup, etc;
	%let prx_meta_text = 's/(% )(.*)/$2/'; * Grabs the metadata text;
	%let prx_header_hashes = 's/(#+)(.*)/$1/'; * Grabs the header count;
	%let prx_header_text = 's/(#+)(.*)/$2/'; * Grabs the header text;
	%let prx_ul_text = 's/(\*)(.*)/$2/'; * Grabs the unordered list text;
	%let prx_ol_text = 's/(^[0-9]+\.)(.*)/$2/'; * Grabs the ordered list text;
	data _m_ds_dissected_markup;
		set _m_ds_file_source;
		length clean_text $&len_line.;
		
		line_no = _N_;
		
		* Find meta-data;
		if input_line =: '% ' then do;
			markup_type = 'meta';
			clean_text = prxchange(&prx_meta_text., -1, input_line);
		end;
		
		* Find sections headers and levels;
		if input_line =: '#' then do;
			header_level = countc( prxchange(&prx_header_hashes., -1, input_line), '#');
			markup_type = ('h' || strip(header_level) );
			clean_text = prxchange(&prx_header_text., -1, input_line);
		end;
		
		* Find unordered lists;
		if input_line =: '* ' then do;
			markup_type = 'ul';
			clean_text = prxchange(&prx_ul_text., -1, input_line);
		end;
		
		* Find ordered list;
		length ol_find $&len_line.;
		ol_find = prxchange(&prx_ol_text., -1, input_line);
		if input_line ^= ol_find then do;
			markup_type = 'ol';
			clean_text = ol_find;
		end;
		drop ol_find;
		
		if missing(clean_text) then clean_text = input_line;
		
		* Find continued lines (starting with 2 spaces);
		if prxmatch('/^  \S+/' ,input_line) then do;
			continue_from_previous = 1;
		end;
		
	run;
	
	* Find which lines continue into next line, first sort in reverse order then retain the value and resort the right way;
	proc sort 
		data = _m_ds_dissected_markup
		out = _m_ds_dissected_markup;
		by descending line_no;
	run;

	data _m_ds_dissected_markup (drop = last_continue_from_previous);
		set _m_ds_dissected_markup;
		
		retain last_continue_from_previous;
		
		continue_to_next = last_continue_from_previous;
		last_continue_from_previous = continue_from_previous;
	run;

	proc sort 
		data = _m_ds_dissected_markup
		out = _m_ds_dissected_markup;
		by line_no;
	run;
	
	* Maximum header level;
	proc sql noprint;
	
		select max(header_level)
		into :max_header_level separated by ''
		from _m_ds_dissected_markup;
		
	quit;
	
	* Get meta-data, toc, body;
	%let prx_toc_tag = 's/\s/_/'; * Create table of content tags;
	proc sql noprint;
	
		create table _m_ds_meta_data as
		select line_no, clean_text
		from _m_ds_dissected_markup
		where markup_type = 'meta'
		order by line_no;
		
		create table _m_ds_toc_data as
		select line_no, markup_type, header_level, clean_text, (lowcase(prxchange(&prx_toc_tag., -1, strip(clean_text))) || strip(put(line_no, best12.)) ) as toc_tag
		from _m_ds_dissected_markup
		where markup_type like 'h%'
		order by line_no;
		
		create table _m_ds_body_data as
		select line_no, markup_type, clean_text, continue_from_previous, continue_to_next
		from _m_ds_dissected_markup
		where markup_type ^= 'meta'
			and not missing(clean_text)
		order by line_no;
		
		* Get number of observations in each ds;
		select count(*)
		into :n_obs_meta_data
		from _m_ds_meta_data;
		
		select count(*)
		into :n_obs_toc_data
		from _m_ds_toc_data;
		
		select count(*)
		into :n_obs_body_data
		from _m_ds_body_data;
	
	quit;	
	
	* Output to html;
	* Delete the output file if it already exists;
	filename fileref &out_file_html;
	%let rc = %sysfunc(fdelete(fileref));
	
	* Open file;
	data _null_;
		set _m_ds_meta_data;
		
		if _N_ = 1 then do;
			file &out_file_html mod;
			
			print_line = ("<title>" || strip(clean_text) || "</title>");

			put '<!DOCTYPE html>';
			put '<html lang="en">';
			put '<head>';
			put print_line;
			put '<meta charset="utf-8">';
			put '<style type="text/css">';
			put '</style>';
			put '</head>';
			put '<body>';
		end;

	run;
	
	* Write out header;
	data _null_;
		set _m_ds_meta_data end=last;
		
		file &out_file_html mod;
		
		if _N_ = 1 then do;
			put '<div id="header">';
			head_type = 'h1';
		end;
		else do;
			head_type = 'h2';
		end;
		
		print_line = ( "<" || strip(head_type) || ' class="title-data">' || strip(clean_text) || "</" || strip(head_type) || ">" );
		put print_line;
		
		if _N_ = &n_obs_meta_data then do;
			put '</div>';
		end;
		
	run;	
	
	* Write out table of contents;
	data _null_;
		set _m_ds_toc_data;
		
		array open_level_array(*) open_level_1-open_level_&max_header_level.;
		retain open_level_:;
		
		file &out_file_html mod;
		
		if _N_ = 1 then do;
			put '<div id="TOC">';
		end;
		
		* Close previous list (levels);
		do ii = (header_level + 1) to &max_header_level.;
			if open_level_array(ii) = 1 then do;
				put '</ul>';
				open_level_array(ii) = 0;
			end;
		end;
		
		* Open new list (levels);
		do ii = 1 to header_level;
			if open_level_array(ii) ^= 1 then do;
				put '<ul class="toc">';
				open_level_array(ii) = 1;
			end;
		end;
		
		print_line = ( '<li class="toc_line"><a href="#' || strip(toc_tag) || '">' || strip(clean_text) || "</a></li>" );
		put print_line;
		
		if _N_ = &n_obs_toc_data then do;
			* Close open lists;
			do ii = 1 to &max_header_level.;
				if open_level_array(ii) = 1 then do;
					put '</ul>';
					open_level_array(ii) = 0;
				end;
			end;
			* Close div;
			put '</div>';
		end;
		
	run;
	
	* Write out body;
	data _null_;
		set _m_ds_body_data;
		
		retain active_ol active_ul;
		if _N_ = 1 then do;
			active_ol = 0;
			active_ul = 0;
		end;
		
		file &out_file_html mod;
		
		* Open/close lists if needed;
		if (not active_ol) and (markup_type = 'ol') then do;
			active_ol = 1;
			put '<ol>';
		end;
		if (active_ol) and (markup_type ^= 'ol') and (continue_to_next ~= 1) and (continue_from_previous ~= 1) then do;
			active_ol = 0;
			put '</ol>';
		end;
		
		if (not active_ul) and (markup_type = 'ul') then do;
			active_ul = 1;
			put '<ul>';
		end;
		if (active_ul) and (markup_type ^= 'ul') and (continue_to_next ~= 1) and (continue_from_previous ~= 1) then do;
			active_ul = 0;
			put '</ul>';
		end;
		
		* Get html markup for the line;
		if markup_type =: 'h' then do;
			print_line = ( "<" || strip(markup_type) || ' id="' || lowcase(prxchange(&prx_toc_tag., -1, strip(clean_text))) || strip(put(line_no, best12.)) || '">' || strip(clean_text) || "</" || strip(markup_type)  || ">" );
		end;
		else if (markup_type = 'ol') or (markup_type = 'ul') then do;
			if continue_to_next = 1 then print_line = ( "<li>" || strip(clean_text) || "</li><br>" );
			else print_line = ( "<li>" || strip(clean_text) || "</li>" );
		end;
		else do;
			print_line = ( strip(clean_text) || "<br>" );
		end;
		
		* Print line;
		put print_line;
		
		* Close lists that did not close at end;
		if _N_ = &n_obs_body_data then do;
			if active_ol then put '</ol>';
			if active_ul then put '</ul>';
		end;
		
	run;
	
	* Close file;
	data _null_;

		file &out_file_html mod;

		put '</body>';
		put '</html>';

	run;
	
	* Clean up after script if not in debug mode;
	* Needs both run and quit to run and end;
	%if not &debug_mode. %then %do;
		proc datasets noprint;
			delete _m_ds_:;
		run; 
		quit;
	%end;
	
	%put %STR( -> End of %upcase( &sysmacroname ) macro );
	
%mend;