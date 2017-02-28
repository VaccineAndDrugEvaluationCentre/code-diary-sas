% SAS macro and script library
% February 28, 2017

#  Demo
##org_macro_A
File location: C:\Users\righoltc\Documents\GitHub\code-diary-sas\demo\org_macro_A.sas
### Summary
The A macro, it does everything you could ever wish for.
 
### Usage
Use it wisely
 
### Parameters
- var_99 = Description
- var_100 = Description
 
### Some other heading
More fancy text
 
##org_macro_B
File location: C:\Users\righoltc\Documents\GitHub\code-diary-sas\demo\org_macro_B.sas
### Summary
Macro B for out glorious institute, it just misses the S.
 
### Usage
Like a macro
 
### Parameters
* input_1 = blabla
* input_2 = bleh
* input_3 = bluh
 
### Some other heading
More fancy text
 
#  Source
##code_diary
File location: C:\Users\righoltc\Documents\GitHub\code-diary-sas\source\code_diary.sas
 
### Summary
* This macro parses a main file for include statements and will read specifically formatted comments to create code-generated documentation.
* It does reads include files recursively as long as they have the format: %include "C:\dir\file.sas";
* The output is formatted as a markdown file, which can be transfered/translated in your file format of choice.
* The macro also reads included Stata files as long as the stata main is called using SAS' x command window and all relative path macro variables are identically defined in both SAS and Stata.
 
### Usage
#### Comment block
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
 
#### Single line comments
Parsable single line comments are also supported:
The line starts with: **
The line ends with: ;
 
#### Document structure
The lines are all grabbed and can be organized by using @keyword for the same themes (e.g. @def in the example, will put all @def lines together). Use . as a seperator for multi-level keywords, e.g. @covar.cost.
There are a few special tags (e.g. @main :title) that grab the document metadata.
If a line within a comment block does not have a keyword it is seen as a continuation of the previous line (in the same block)
 
The output can be converted to any format (e.g. pdf [needs latex installed], word, html) using pandoc. (See Google for details)
Go to the directory in the command window and use
* markdown to pdf: pandoc infile.txt --toc --latex-engine=pdflatex -o outfile.pdf
* markdown to word: pandoc -s -S infile.txt --toc -o outfile.docx
* markdown to html: pandoc -s infile.txt --toc -o outfile.htm
 
### Parameters
* input_main_file = Is the main file for the sas project tree, all files/scripts called from this main will be read recursively. (e.g P:\project\source\main.sas)
* out_dir = Is the output folder (e.g. P:\project\)
* out_file = Is the resulting markdown file in which the results are written with script and line information. (e.g. workplan_coding.txt)
* out_file_scrubbed = Is the resulting markdown file in which the comments without script and line information is written. [Optional (e.g. workplan_output.txt')]
* debug_mode = Set to 1 to run in debug mode. (This does not delete macro data-sets for troubleshooting) [optional]
* section_aliases = This is the dataset with keyword aliases to cause multiple keywords to map to the same section [optional]. See example for structure.
* section_order = This is the dataset to overwrite the order of sections (all values should be negative, with the lowest order number coming first) [optional]. See example for structure.
* section_headers = This is the dataset to determine section headers [optional]. See example for structure.
* sections_scrubbed = This is the dataset with a list of sections to omit from the scrubbed file [optional]. See example for structure.
 
### Notes
* There is a practical limit to the number of include files because of the creation of the dataset _includes_&curr_script_no_text. When this exceeds 32 characters it will cause an error, because of internal sas limits.
* The maximum of several fields is hard-coded under the comment "Define character lengths" with several %let statements. Adjust these if needed for longer comments.
* The warning<br>WARNING: The quoted string currently being processed has become more than 262 characters long. You might have unbalanced quotation marks.<br>Is turned off for the duration of the macro.
* Keyword comments are all saved in their own intermediate datasets, which need to meet SAS 32 character limit. This should not cause any issues as long as keywords are 20 chars or less. (Use section_headers entries to define longer headings in the created report.)
 
### Example
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
 
### Final
Authors: Christiaan Righolt
Copyright (c) 2016 Vaccine and Drug Evaluation Centre, Winnipeg.
 
##convert_markdown_to_html
File location: C:\Users\righoltc\Documents\GitHub\code-diary-sas\source\convert_markdown_to_html.sas
### Summary
Macro to convert a markdown style document to html. This is not supposed to supplant proper tools like pandoc, but only to aid visualization on a closed system that does not allow the installation of software.
 
### Usage
The tool automatically creates a table of contents
 
The tool supports the following markdown markup:
* Pandoc-style metadata prefixed with %
* Headers prefixed with N### depending on the level (e.g. #### is 4th level)
* Unordered lists prefixed with *
* Order lists prefixed with n.
 
Not supported is:
* Nested lists
* Bold/italic text
* Links, images etc.
 
### Parameters
* in_file_md = = The input markdown file with documentation (e.g. "C:\source\source_documentation.md"")
* out_file_html = = The output html file with documentation (e.g. "C:\source\source_documentation.htm"")
* debug_mode = Use debug mode or not [0 or 1, optional]
 
### Final
Authors: Christiaan Righolt
Copyright (c) 2016 Vaccine and Drug Evaluation Centre, Winnipeg.
 
##macro_diary
File location: C:\Users\righoltc\Documents\GitHub\code-diary-sas\source\macro_diary.sas
### Summary
Macro to parse documentation for all sas macros and scripts in a root directory.
 
### Usage
See sample_macro_documentation for markup of files.
 
### Parameters
* source_dir = The source root directory (e.g. C:\source\), the folder &source_dir._archive is skipped
* out_file_md = The output markdown file with documentation (e.g. 'C:\source\source_documentation.txt')
* debug_mode = Use debug mode or not [0 or 1, optional]
 
### Final
Authors: Christiaan Righolt
Copyright (c) 2016 Vaccine and Drug Evaluation Centre, Winnipeg.
 
##sample_macro_documentation
File location: C:\Users\righoltc\Documents\GitHub\code-diary-sas\source\sample_macro_documentation.sas
### Summary
This file is a example/template for macro documentation that describes what sections could be included. This documentation is written in markdown.
 
### Usage
General comments on how to use it. (e.g. macro's to call before and or after this one)
 
A list of parameters (and their meaning) used in the macro.
* parameter_1 = First parameter
* parameter_2 = Second parameter [optional]
 
### Notes
Other detailed information about how to use the macro properly (e.g. details on the format of certain parameters)
 
### Known issues
List of known issues/warnings/etc. for the macro.
* This file is not really code, just documentation
 
### Version history
* v1.1.1; Programmer Two, August 2016; Implemented documentation house style.
* v1.1.0; Programmer Two, June 2016; A way better version with added functionality XYZ
* v1.0.0; Programmer One, May 2016; Initial version
 
Placeholder copyright line (c).
 

# Files without documentation
* C:\Users\righoltc\Documents\GitHub\code-diary-sas\demo\generate_documentation.sas
* C:\Users\righoltc\Documents\GitHub\code-diary-sas\demo\generate_macro_documentation.sas
* C:\Users\righoltc\Documents\GitHub\code-diary-sas\demo\project_main.sas
* C:\Users\righoltc\Documents\GitHub\code-diary-sas\demo\project_script.sas
