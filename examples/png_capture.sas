*--- where the macros live ---;
%let repo = H:\GitHub\srosanba\sas-parallelcoordinatesplot\src;
options sasautos=("&repo" sasautos);

*--- where the calling program and output live ---;
%let prog = H:\GraphicsGroup\ParallelCoordinatesPlot;

*--- capture iris output as png ---;
ods listing gpath="&prog";
ods graphics / reset=all imagename="png_capture";
%parallel
   (data=sashelp.iris
   ,var=sepallength sepalwidth petallength petalwidth
   ,group=species
   );
