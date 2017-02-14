/**
@main :title Title for output document
@main :authors Christiaan Righolt (CR)
@main :org Vaccine and Drug Evaluation Centre (VDEC)
@main :version 1.2.3
@main This document is generated as an example output
@def The answer to life the universe and everything = 42
*/

* Define folders;
%let SOURCE_ROOT = %qsubstr(%sysget(SAS_EXECFILEPATH),1,%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname)));;
%let MACRO_ROOT = &SOURCE_ROOT;

* Included scripts;
%include "&SOURCE_ROOT\project_script.sas";

* Stata analysis;
*options noxwait;
/*x cd &SOURCE_ROOT; x '"C:\Program Files (x86)\Stata14\StataMP-64.exe" /e do "...\demo\project_stata.do"'; run;*/

* Documentation;
*%include "&SOURCE_ROOT\generate_documentation.sas";
