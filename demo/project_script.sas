/**
@excl.person Exclude Martians from analysis
@excl.person Exclude terrestial gods.
*/

* Some code;
%put Executing project_script.sas;

**@excl.time Exclude any record before 1960;

* Some code;

/**
@stat Use the fanciest order of tests
1. The Atlantic test procedures
2. The Pacific test procedures
3. The Arctic test procedures
*/

* Some code;

**@stat We use alpha=0.05 in all tests;

* Some code;

**@todo Insert this code from reference Qwerty (Nature, 2345);


**@analysis Use the Milkyway default analysis for grouping of people;
**The Milkyway has stars, this is a test for a single-line two star that is appended to the above in markdown / HTML;

**@regex Essential definitions for the text-parsing regex.;
* Additional code that defines a number of useful regexes, this should *not* be parsed *nor* appear;

**@testing Longer, multiple line comment test;
**This is an example of a multiple-line two star SAS comment which will
  be copied in as a single consecutive comment, it is terminated only
  by the semicolon;

/**@finalization How the end product will be determined: */
* The above is designed to account for how SAS handles slash-two-asterix *at* comments;

* Some more code, nothing too fancy...;
