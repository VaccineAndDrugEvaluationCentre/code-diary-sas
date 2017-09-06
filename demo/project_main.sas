/**
@main :title Title for output document, just an example
@main :authors Christiaan Righolt, Barret Monchka, Robert Bisewski, Salah Mahmud
@main :org Vaccine and Drug Evaluation Centre (VDEC)
@main :version 1.2.3
@main This document is generated as an example output
@def The answer to life the universe and everything = 42
*/

* Define folders;
%let DEMO_ROOT = %qsubstr(%sysget(SAS_EXECFILEPATH),1,%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname)));
%let MACRO_ROOT = %qsubstr(&DEMO_ROOT,1,%length(&DEMO_ROOT)-5)source\;

* Included scripts;
%include "&DEMO_ROOT.project_script.sas";

* Stata analysis;
*options noxwait;
/*x cd &DEMO_ROOT; x '"C:\Program Files (x86)\Stata14\StataMP-64.exe" /e do "&DEMO_ROOT.project_stata.do"'; run;*/

* Documentation;
%include "&DEMO_ROOT.generate_documentation.sas";
