# Code Diary for SAS [![DOI](https://zenodo.org/badge/80657929.svg)](https://zenodo.org/badge/latestdoi/80657929)

An automatic documentation parser for SAS.
The main component is Code Diary, which can be used to easily collect and organize comments from source code called from a central main.
An extra component is Macro Diary, which can be used to collect special comment blocks from all macros in a common root directory.
A bonus component is a rudimentary, incomplete markdown to HTML converter implemented in SAS. 
This converter is not intended to replace full implementation, but rather to provide a quick visual on systems that do not allow the installation of other software.

## Components
Copy the relevant files from the [**source**](https://github.com/VaccineAndDrugEvaluationCentre/code-diary-sas/tree/master/source) folder:
- code_diary.sas for Code Diary
- macro_diary.sas for Macro Diary
- convert_markdown_to_html.sas for a rudimentary, incomplete markdown to HTML converter

## How to
See the files in the [**demo**](https://github.com/VaccineAndDrugEvaluationCentre/code-diary-sas/tree/master/demo) folder for example uses.
These examples, combined with the documentation in the files themselves, are the user manual.

## Citing
Code Diary has been published as *[From source code to publication: Code Diary, an automatic documentation parser for SAS](https://www.sciencedirect.com/science/article/pii/S2352711018300669)* in SoftwareX, please cite this paper when needed. Zenodo (https://zenodo.org) automatically registers a DOI for each new release (and updates the tag above) if you need a version-specific reference in your implementation.
