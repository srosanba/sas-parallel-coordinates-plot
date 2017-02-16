*--- where the macros live ---;
%let repo = _where_you_put_the_macro_;
options sasautos=("&repo" sasautos);

*--- where the calling program and output live ---;
%let prog = _where_you_want_your_output_;

*--- capture sgplot code in mprint.sas ---;
filename mprint "&prog/mprint.sas";
options mprint mfile;

ods listing close;
%parallel
   (data=sashelp.iris
   ,var=sepallength sepalwidth petallength petalwidth
   ,group=species
   );
ods listing;

filename mprint clear;
options nomprint nomfile;

/* 
having captured the sgplot code in mprint.sas, you now paste 
that code below the macro call and edit away until you achieve 
the cosmetics that you're looking for.
*/