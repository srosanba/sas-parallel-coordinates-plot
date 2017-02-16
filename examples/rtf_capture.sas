*--- where the macros live ---;
%let repo = H:\GitHub\srosanba\sas-parallelcoordinatesplot\src;
options sasautos=("&repo" sasautos);

*--- where the calling program and output live ---;
%let prog = H:\GraphicsGroup\ParallelCoordinatesPlot;

*--- capture iris output as rtf ---;
ods listing close;
ods rtf file="&prog/iris_percentiles.rtf";
%parallel
   (data=sashelp.iris
   ,var=sepallength sepalwidth petallength petalwidth
   ,group=species
   );
ods rtf close;