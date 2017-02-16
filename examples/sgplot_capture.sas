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

filename mprint clear;
options nomprint nomfile;