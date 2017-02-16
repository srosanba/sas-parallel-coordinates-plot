*--- where the macros live ---;
%let repo = _where_you_put_the_macro_;
options sasautos=("&repo" sasautos);

*--- where the calling program and output live ---;
%let prog = _where_you_want_your_output_;

*--- capture iris output as png ---;
ods listing gpath="&prog";
ods graphics / reset=all imagename="png_capture";
%parallel
   (data=sashelp.iris
   ,var=sepallength sepalwidth petallength petalwidth
   ,group=species
   );
