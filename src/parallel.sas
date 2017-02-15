ods listing close;
options nodate nonumber mprint orientation=landscape;
%include "S:/BASESTAT/RhoUtil/AxisOrder.sas";
%include "S:/BASESTAT/Autocall/LetPut.sas";

%let path = H:\GraphicsGroup\ParallelCoordinatesPlot;


%macro parallel
         (data=
         ,var=
         ,by=
         ,axistype=percentiles
         ,sgplot=y
         ) / minoperator;

   %local i linecolor;
   %let linecolor = cx2A25D9;
   %if &by = %str() %then
      %let by = dummyby;

   %*--- parse var list ---;
   %let i = 1;
   %do %while (%scan(&var,&i,%str( )) ne %str());
      %local var&i;
      %let var&i = %scan(&var,&i,%str( ));
      %let i = %eval(&i + 1);
   %end;
   %local var_n;
   %let var_n = %eval(&i - 1);
   %put &=var_n;
   %do i = 1 %to &var_n;
      %put var&i=&&var&i;
   %end;

   %*--- rename dataset for convenience ---;
   data _pcp10;
      set &data;
      dummyby = 1;
      keep &var &by;
   run;

   %*--- get variable labels for x2axis ---;
   %do i = 1 %to &var_n;
      %local label&i;
      proc sql noprint;
         select   label
         into     :label&i
         from     dictionary.columns
         where    libname = "WORK"
                  and memname = "_PCP10"
                  and upcase(name) = upcase("&&var&i")
         ;
      quit;
   %end;
   %do i = 1 %to &var_n;
      %put label&i=&&label&i;
   %end;

   %*--- make dataset vertical ---;
   data _pcp20;
      set _pcp10;
      series = _N_;
      %do i = 1 %to &var_n;
         group = &i;
         length groupc $40;
         groupc = "&&label&i";
         if groupc = "" then
            groupc = "&&var&i";
         yval = &&var&i;
         output;
      %end;
   run;

   %*--- standardize results based on start/end (dv) and min/max (pct) ---;
   %do i = 1 %to &var_n;

      data _pcp25;
         set _pcp20;
         where group = &i;
      run;

      %axisorder
         (data=_pcp25
         ,var=yval
         );

      %local AxisList&i AxisStart&i AxisEnd&i AxisMin&i AxisMax&i;
      %let AxisList&i = %sysfunc(translate(&_AxisList,%str(,),%str( )));
      %let AxisStart&i = &_AxisStart;
      %let AxisEnd&i = &_AxisEnd;
      %let AxisMin&i = &_AxisMin;
      %let AxisMax&i = &_AxisMax;
      %letput(AxisList&i);
      %letput(AxisStart&i);
      %letput(AxisEnd&i);
      %letput(AxisMin&i);
      %letput(AxisMax&i);

   %end;

   data _pcp30;
      set _pcp20;
      %do i = 1 %to &var_n;
         if group = &i then do;
            start = &&AxisStart&i;
            end = &&AxisEnd&i;
            dvrange = end - start;
            yval_dv = (yval - start) / dvrange;
            min = &&AxisMin&i;
            max = &&AxisMax&i;
            pctrange = max - min;
            yval_pct = (yval - min) / pctrange;
         end;
      %end;
   run;

   %*--- prep for legend ---;
   %local by_n;
   proc sql noprint;
      select   distinct &by
      into     :by1-
      from     _pcp30
      ;
      %let by_n = &sqlobs;
   quit;

   proc sort data=_pcp30;
      by &by series;
   run;

   data _pcp35;
      set _pcp30;
      by &by series;
      retain firstseries;
      if first.&by then
         firstseries = series;
      if series = firstseries then do;
         groupforlegend = group;
         yvalforlegend_dv = yval_dv;
         yvalforlegend_pct = yval_pct;
         seriesforlegend = &by;
         output;
      end;
   run;

   data _pcp40;
      set _pcp30 _pcp35;
   run;

   %*--- create group format ---;
   proc sql noprint;
      create   table _pcp45 as
      select   distinct
               "groupf" as fmtname,
               group as start,
               groupc as label
      from     _pcp40
      ;
   quit;

   proc format cntlin=_pcp45;
   run;

   data _pcp50;
      set _pcp40;
      format group groupforlegend groupf.;
   run;

   %*--- add records for datavalues ---;
   data _pcp55;
      %do i = 1 %to &var_n;
         xtext = &i;
         do yloop = &&AxisList&i;
            start = &&AxisStart&i;
            end = &&AxisEnd&i;
            dvrange = end - start;
            ytext = (yloop - start) / dvrange;
            texttext = strip(put(yloop,best.));
            output;
         end;
      %end;
   run;

   data _pcp60;
      set _pcp50 _pcp55;
      format xtext groupf.;
   run;

   %*--- calculate offset ---;
   data _null_;
      offset = 0.25*(1/&var_n);
      call symputx("offset",offset);
   run;
   %letput(offset);

   %*--- set some values pre-plot ---;
   %local yval yvalforlegend;
   %if &axistype = percentiles %then %do;
      %let yval = yval_pct;
      %let yvalforlegend = yvalforlegend_pct;
   %end;
   %else %if &axistype = datavalues %then %do;
      %let yval = yval_dv;
      %let yvalforlegend = yvalforlegend_dv;
   %end;

   %*--- at long last, we plot ---;
   %let sgplot = %upcase(&sgplot);
   %if &sgplot = Y %then %do;
      proc sgplot data=_pcp60 nocycleattrs noautolegend noborder;
         styleattrs axisextent=data;
         %*--- primary series plot ---;
         series x=group y=&yval / 
            group=series 
            %if &by ne dummyby %then %do;
               grouplc=&by
            %end;
            lineattrs=(
               pattern=solid 
               %if &by eq dummyby %then %do;
                  color=&linecolor
               %end;
               )
            x2axis
            ;
         %*--- copy to get y2axis ---;
         %if &axistype = percentiles %then %do;
            series x=group y=&yval / 
               group=series 
               %if &by ne dummyby %then %do;
                  grouplc=&by
               %end;
               lineattrs=(
                  pattern=solid 
                  %if &by eq dummyby %then %do;
                     color=&linecolor
                  %end;
                  )
               x2axis
               y2axis
               ;
         %end;
         %*--- tick values added sans tick marks ---;
         %if &axistype = datavalues %then %do;
            text x=xtext y=ytext text=texttext /
               x2axis
               backlight=1
               ;
         %end;
         %*--- top axis control ---;
         x2axis 
            type=discrete 
            display=(nolabel noline noticks)
            grid
            offsetmin=&offset 
            offsetmax=&offset
            ;
         %*--- make left/right the same ---;
         yaxis
            %if &axistype = percentiles %then %do;
               display=(nolabel)
               grid
            %end;
            %else %if &axistype = datavalues %then %do;
               display=none
            %end;
            ;
         %if &axistype = percentiles %then %do;
            y2axis
               %if &axistype = percentiles %then %do;
                  display=(nolabel)
                  grid
               %end;
               %else %if &axistype = datavalues %then %do;
                  display=none
               %end;
               ;
         %end;
         %*--- reduced version to get a legend ---;
         %if &by ne dummyby %then %do;
            series x=groupforlegend y=&yvalforlegend / 
               group=seriesforlegend 
               lineattrs=(pattern=1)
               x2axis
               name="forlegend"
               ;
            keylegend "forlegend" /
               exclude=(" ")
               noborder
               ;
         %end;
      run;
   %end;

%mend parallel;



data cars;
   set sashelp.cars;
   label
      horsepower = "Horsepower"
      msrp = "MSRP ($)"
      invoice = "Invoice ($)"
      ;
run;

%macro loop;

   ods listing gpath="&path";

   %do j = 1 %to 2;

      %if &j = 1 %then %let axistype = percentiles;
      %if &j = 2 %then %let axistype = datavalues;

      ods graphics / reset=all imagename="cars_by_&axistype";
      %parallel
         (data=cars
         ,var=enginesize horsepower msrp invoice weight length 
            mpg_city mpg_highway wheelbase
         ,by=origin
         ,axistype=&axistype
         );

      ods graphics / reset=all imagename="cars_noby_&axistype";
      %parallel
         (data=cars
         ,var=enginesize horsepower msrp invoice weight length 
            mpg_city mpg_highway wheelbase
         ,axistype=&axistype
         );

      ods graphics / reset=all imagename="iris_by_&axistype";
      %parallel
         (data=sashelp.iris
         ,var=sepallength sepalwidth petallength petalwidth
         ,by=species
         ,axistype=&axistype
         );

      ods graphics / reset=all imagename="iris_noby_&axistype";
      %parallel
         (data=sashelp.iris
         ,var=sepallength sepalwidth petallength petalwidth
         ,axistype=&axistype
         );

   %end;

%mend loop;

%loop




filename mprint "&path/mprint.sas";
options mprint mfile;

ods listing gpath="&path";
ods graphics / reset=all imagename="mprint";
%parallel
   (data=sashelp.iris
   ,var=sepallength sepalwidth petallength petalwidth
   );

filename mprint clear;
options nomprint nomfile;





data pathological;
   do subj = 1 to 9;
      x = subj/10;
      y = x;
      z = y;
      output;
   end;
run;

ods listing gpath="&path";
ods graphics / reset=all imagename="pathological";
%parallel
   (data=pathological
   ,var=x y z
   ,axistype=datavalues
   );
