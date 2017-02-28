# Examples of usage
This implementatino should in principle work in SAS 9.3 and up.

## Code Diary
The script project_main.sas is the main script for the demo.
The included script generate_documentation.sas is the script that is used to call the relevant macros.

- The use of aliases for sections are meant to keep keywords short where appropriate. Keywords should in principle be limited to 25 characters and start with a letter.
- The order list overwrites the default order (which is by occurence in the source code). Use negative numbers to overwrite this default order. -3 is ordered before -2, etc.
- The header list can be used to define section header names.
- The scrub list is used to omit certain section from the final document that is intended to be distributed.

## Macro Diary
The script generate_macro_documentation.sas is the script for this demo.
