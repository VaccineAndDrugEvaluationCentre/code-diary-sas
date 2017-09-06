# Code Diary for SAS 

An automatic documentation parser for SAS. 
Specifically, it consists of three components; Code Diary, Macro Diary and a SAS based markdown-to-HTML Converter.

The main component is Code Diary, which can be used to easily collect and organize comments from source code called from a central main.

The second component is Macro Diary, which can be used to collect special comment blocks from all macros in a common root directory.

The third component is a rudimentary, incomplete markdown-to-HTML converter implemented in SAS.
This converter is not intended to fully full converters like Pandoc; instead it provides a quick visual on systems that do not allow the installation of other software.

## Components

Copy the relevant files from the [**source**](https://github.com/VaccineAndDrugEvaluationCentre/code-diary-sas/tree/master/source) folder:

- code_diary.sas for Code Diary

- macro_diary.sas for Macro Diary

- convert_markdown_to_html.sas for a rudimentary, incomplete markdown-to-HTML converter

## Usage instructions
Include all relevant files files in a *main* file that runs all SAS code for the project and call Code Diary.

In SAS Enterprise Guide 7.1, the files can alternatively be imported and saved as an Enterprise Guide project.

## Testing/demo
See the files in the [**demo**](https://github.com/VaccineAndDrugEvaluationCentre/code-diary-sas/tree/master/demo) folder to test or demo Code Diary:

1. Open *project_main.sas* from the *demo* folder
1. Run the code
1. If run successful, you see the output files in the *demo* folder.
1. Ensure that generated output is not broken or mangled, and that the numbering and markdown and HTML tags appear normal.

## Notes regarding the Code Diary regex

In the code_diary.sas program, a number of complex regexes are used to extract data from each line of code and determine the different types of comments are that permitted in SAS code.
Documentation concerning them is provided below:

i) Search for `/** detailed comment regarding code` comments.

`/^\s{0,4}\/\*\*/`

ii) Search for starting `/*` of multi-line comments.

`/^\s{0,4}\/\*[^\*]/`

iii) Search for ending `*/` of multi-line comments.

`/\s{0,4}\*\//`

iv) Find all of the `/**@subheader This is a description. */` comments,
    both single-line and inline variants.

`s/^.*;?\s{0,4}\/\*\*\@(.+)\*\//\*\*\@$1;/`

v) Look for the two-star variant SAS comments, during the SQL stage, and
   extract the comment contents.

`s/\*\*([^;]+);/$1/`
