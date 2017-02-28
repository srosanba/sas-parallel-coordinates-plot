*--- where the macros live ---;

%let repo = _where_you_put_the_macro_;
options sasautos=("&repo" sasautos);

*--- where the calling program and output live ---;

%let prog = _where_you_want_your_output_;

*--- capture sgplot code in myparallel.sas, discard image ---;

ods listing gpath="&prog";
ods graphics / reset=all imagename="junk";

%parallel
   (data=sashelp.iris
   ,var=sepallength sepalwidth petallength petalwidth
   ,group=species
   ,sgplotout=C:/temp/myparallel.sas
   );

*--- copy code from myparallel.sas and edit away ---;

ods listing gpath="&prog";
ods graphics / reset=all imagename="parallel";

/* begin copied code */
proc sgplot data=_pcp60 nocycleattrs noautolegend noborder;
styleattrs axisextent=data;
series x=_pcp_var y=_pcp_yval_pct / group=_pcp_series grouplc=species lineattrs=(pattern=solid) x2axis
name="series" ;
series x=_pcp_var y=_pcp_yval_pct / group=_pcp_series grouplc=species lineattrs=(pattern=solid) x2axis
y2axis ;
;
x2axis type=discrete display=(nolabel noline noticks) grid offsetmin=0.0625 offsetmax=0.0625 ;
yaxis
display=(nolabel) grid
;
y2axis
display=(nolabel) grid
;
keylegend "series" / exclude=(" ") noborder type=linecolor ;
run;
/* end copied code */