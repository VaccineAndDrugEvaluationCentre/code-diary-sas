/*
Just a regular block comment, should not be parsed 
*/

/* Inline block comment */

/*
Block comments
**@test Code Diary comment inside block comments;
*/

**Example of a comment without keyword;

/**@test Same line Code Diary block comment A*/

/**@test Same line Code Diary block comment B
*/

/**
@test Same line Code Diary block comment C*/

**
@test Different line Code Diary line comment A
;

**@test Different line Code Diary line comment B
;

**
@test Different line Code Diary line comment C;

data /**@test A tricky Code Diary
  comment*/ _null_;
  var_one = 1; **@test A Code Diary comment after code (not supported);
run;

/**
@excl.person Exclude Martians from analysis
@excl.person Exclude terrestrial gods.
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
* Additional code that defines a number of useful regexes; * the above two-star line should be parsed;
* but these single asterix lines should *not* be parsed *nor* appear;

**@test Longer, multiple line comment test;
**This is an example of a multiple-line two star SAS comment which will
  be copied in as a single consecutive comment, it is terminated only
  by the semicolon;

* Sample code here; /**@staging What needs to be done to move towards release. */
* Note: the above is an example of an inline slash-two-asterix SAS comment;

/**@finalization How the end product will be determined... */
* The above is designed to account for how SAS handles slash-two-asterix *at* comments;

* Some more code, nothing too fancy...;
