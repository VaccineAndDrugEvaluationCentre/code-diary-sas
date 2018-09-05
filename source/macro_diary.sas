/*~
# Summary
Macro to parse documentation for all sas macros and scripts in a root directory.

# Usage
See sample_macro_documentation for markup of files.

# Parameters
* source_dir = The source root directory (e.g. C:\source\), the folder &source_dir._archive is skipped
* out_file_md = The output markdown file with documentation (e.g. 'C:\source\source_documentation.txt')
* debug_mode = Use debug mode or not [0 or 1, optional]

# Final
Authors: Christiaan Righolt
Copyright (c) 2016 Vaccine and Drug Evaluation Centre, Winnipeg.

~*/

%macro macro_diary(
	source_dir = ,
	out_file_md = ,
	debug_mode = 0
);

	%put %STR( -> Start of %upcase( &sysmacroname ) macro );
	
	* Define local dataset names;
	%let files_ds = work._m_ds_files;
	%let all_source_ds = work._m_ds_sas_source_all;
	
	* Define character lengths;
	%let len_no = 7;
	%let len_file = 255;
	%let len_line = 1023;
	
	* Read the all the files to include;
	filename filelist pipe "dir /b /s &source_dir.*.sas";

	data _m_ds_filelist_include_archive;
		infile filelist truncover;
		input full_file_path $&len_file..;
	run;

	* Remove archived files and find filename;
	%let prx_grab_filedir = 's/(.*\\)(\w[^\\]+)(.sas)/$1/'; * Grabs the dile dir;
	%let prx_grab_filename = 's/(.*\\)(\w[^\\]+)(.sas)/$2/'; * Grabs the filename;
	data &files_ds;
		length file_no &len_no.;
		file_no = _N_;
		
		set _m_ds_filelist_include_archive;
		
		if not find(full_file_path, "&source_dir._archive");
		
		relative_file_dir = tranwrd( prxchange(&prx_grab_filedir., -1, full_file_path), "&source_dir", "" );
		file_name = prxchange(&prx_grab_filename., -1, full_file_path);
		
		dir_levels = countc(relative_file_dir, "\");
		file_base_header_level = repeat('#', dir_levels);
	run;
	
	* Get directory structure;
	proc sql noprint;
	
		select max(dir_levels)
		into :max_dir_levels separated by ''
		from &files_ds;
		
	quit;
	
	data &files_ds (drop = ii);	
		set &files_ds;
		
		length dir_level_1-dir_level_&max_dir_levels. $&len_file..;
		array dir_level_array(*) dir_level_1-dir_level_&max_dir_levels.;
		
		do ii = 1 to &max_dir_levels.;
			if ii<=dir_levels then do;
				dir_level_array(ii) = ( repeat('#', ii-1) || " " || propcase(scan(relative_file_dir, ii, "\")) );
			end;
		end;
		
	run;
	
	* Start source table empty;
	proc sql noprint;
		
		create table &all_source_ds. 
			(
				file_no num format=&len_no..,
				line_no num format=&len_no..,
				source_line char(&len_line.)
			);
		
	quit;
	
	* Read through all source;
	data _null_;
		set &files_ds;
		
		call symput('iter_file_no', file_no );
		call symput('iter_file', trim(full_file_path) );
		call symput('iter_base_header', trim(file_base_header_level));
		
		call execute('%read_file_lines(
			_input_file = &iter_file.,
			_file_no = &iter_file_no.,
			_base_header = &iter_base_header.,
			_source_ds = &all_source_ds.
		);');
	run;
	
	* Only keep special comments;
	data _m_ds_source_comments (drop = is_comment use_line);
		set &all_source_ds.;
		retain is_comment;
		by file_no;
		
		if first.script_no then is_comment = 0;
		if find(source_line, '~*/') then is_comment = 0;
		
		if is_comment then use_line = 1;
		
		/* If you update this line, ALSO UPDATE THE SECOND LINE AFTER ACCORDINGLY!!!*/
		if find(source_line, '/*~') then is_comment = 1;
		/* But escape the line above when this comment parser file is included as part of main. */
		if find(source_line, "if find(source_line, '/*~') then is_comment = 1;") then is_comment = 0;/**/
		
		if use_line;
	run;
	
	* Determine which files have macro comments and which do not.;
	proc sql noprint;
	
		create table _m_ds_files_with_comments as
		select distinct fil.*
		from &files_ds. as fil
		inner join _m_ds_source_comments as com
			on fil.file_no = com.file_no
		order by file_no;
			
		create table _m_ds_files_without_comments as
		select * 
		from &files_ds.
		except
		select *
		from _m_ds_files_with_comments;
	
	quit;
	
	* Now create a data set with just the header information for the file structure;
	data _m_ds_file_structure_headers (keep = file_no line_no documentation_line);
		set _m_ds_files_with_comments;
		
		length old_dir_level_1-old_dir_level_&max_dir_levels. $&len_file..;
		retain old_dir_level_:;
		array dir_level_array(*) dir_level_1-dir_level_&max_dir_levels.;
		array old_dir_level_array(*) old_dir_level_1-old_dir_level_&max_dir_levels.;
		
		do ii = 1 to &max_dir_levels.;
			* Check that the level is new;
			if old_dir_level_array(ii) ^= dir_level_array(ii) then do;
				line_no = -1000+ii;
				documentation_line = dir_level_array(ii);
				
				* Empty old strings to ensure they are printed (all lower level headers should be printed);
				do jj = (ii+1) to &max_dir_levels.;
					old_dir_level_array(jj) = "";
				end;
				output;
			end; 
			
			* Update for next cycle;
			old_dir_level_array(ii) = dir_level_array(ii);
		end;
	run;
	
	* For files with comments: Create header + location at start;
	* From "macro read_file_lines" statement?;
	proc sql noprint;
		
		create table _m_ds_source_documentation as
		select file_no, line_no, source_line as documentation_line
		from _m_ds_source_comments
		union
		select file_no, -2 as line_no, ( strip(file_base_header_level) || " " || strip(file_name) ) as documentation_line
		from _m_ds_files_with_comments
		union
		select file_no, -1 as line_no, ("File location: " || strip(full_file_path)) as documentation_line
		from _m_ds_files_with_comments
		union
		select file_no, line_no, documentation_line
		from _m_ds_file_structure_headers
		order by file_no, line_no;
	
	quit;	
	
	* Write to output;
	* Write header info;
	filename fileref &out_file_md.;
	%let rc = %sysfunc(fdelete(fileref));
	%let _date_today = %sysfunc( putn(%sysfunc( date() ), worddate20. ));
	
	data _null_;

		file &out_file_md. mod;
		
		* Meta-data style for pandoc;
		put "% SAS macro and script library";
		put "% &_date_today.";
		put;
		
	run;
	
	* Write documentation;
	data _null_;
		set _m_ds_source_documentation;
		
		file &out_file_md. mod;
		put documentation_line;
	run;
	
	* Write out files without comments;
	data _null_;

		file &out_file_md. mod;
		
		* Meta-data style for pandoc;
		put;
		put "# Files without documentation";
		
	run;
	
	data _null_;
		set _m_ds_files_without_comments;
		
		file &out_file_md. mod;
		print_line = ("* " || strip(full_file_path));
		put print_line;
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

* Read through files;
%macro read_file_lines(
	_input_file = ,
	_file_no = ,
	_base_header = ,
	_source_ds =
);
	
	%put Read code from &_input_file;
	
	* Add to headers, first define regular expression, then change it in the line;
	* Remove archived files and find filename;
	%let prx_change_header_level = "s/(\s*)(#+)(.*)/&_base_header.$2$3/";
	
	data _m_ds__file_source;
		length line_no &len_no.;
		length source_line $&len_line.;

		infile "&_input_file.";
		input;

		line_no = _N_;
		source_line = compress(_infile_,,'c');
		source_line = prxchange(&prx_change_header_level., -1, source_line);

	run;
	
	proc sql noprint;
	
		insert into &_source_ds
		select
			&_file_no. as file_no,
			line_no,
			source_line
		from _m_ds__file_source;
	
	quit;

%mend;
