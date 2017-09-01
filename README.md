# Code Diary for SAS 

An automatic documentation parser for SAS. Specifically, it consists of
three components; the Code Diary, the Macro Diary and the HTML Converter.

The main component is Code Diary, which can be used to easily collect and
organize comments from source code called from a central main.

The second component is the Macro Diary, which can be used to collect
special comment blocks from all macros in a common root directory.

The third component is a rudimentary, incomplete markdown to HTML converter
implemented in SAS. This converter is not intended to fully replace the
internal SAS implementation; instead it provides a quick visual on systems
that do not allow the installation of other software.

## Components

Copy the relevant files from the [**source**](https://github.com/VaccineAndDrugEvaluationCentre/code-diary-sas/tree/master/source) folder:

- code_diary.sas for Code Diary

- macro_diary.sas for Macro Diary

- convert_markdown_to_html.sas for a rudimentary, incomplete markdown to
  HTML converter

## Usage instructions

The usage depends on the version of the SAS IDE being used:

a) SAS 9.4 Unicode

Include the files in the *source* directory while you are creating and
running your SAS program.

b) SAS Enterprise Guide 7.1

Import the files into your program and save the entire project as an
Enterprise Guide project.

## Testing

The code in this project can be tested in the following manner:

1) Open the *project_main.sas* in the SAS 9.4 Unicode IDE

2) Run the code via the *Submit* button present at the top of the IDE

3) If the markdown and HTML generated correctly, you should see several
   files in the *demo* that contain the newly assembled comments.

4) Ensure that generated output is not broken or mangled, and that the
   numbering and markdown and HTML tags appear normal.

Ideally, testing ought to be done everytime the source code for this project
has been changed. It is recommended that multiple team members conduct
quality assurance since SAS code and comments tend to be very non-standard.

## Notes regarding the Code Diary regex

In the code_diary.sas program, a number of complex regexes are used to
extract data from each line of code and determine the different types of
comments are that permitted in SAS code.

For any future programmers who may have difficulty understanding why they
were used as such, documentation concerning them is provided below:

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

## Additional Notes

See the files in the [**demo**](https://github.com/VaccineAndDrugEvaluationCentre/code-diary-sas/tree/master/demo)
folder for example uses. These examples, combined with the documentation
in the files themselves, are the user manual.
