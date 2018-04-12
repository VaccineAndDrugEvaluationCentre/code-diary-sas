/*
 * @stata Edit this to reflect the current directory
 */
local demo_root C:\Users\bisewskr\development\code-diary-sas\demo

**@stata Just an example of Stata comments;

/*
@stata Stata comments can be parsed
using the same notation as in SAS.
*/

**@stata A one-line Stata command;

**@stata Test the include/run/do parsing;
include `demo_root'\stata_husk_a.do
run `demo_root'\stata_husk_b.do
do `demo_root'\stata_husk_c.do
