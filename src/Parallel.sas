/*--------------------------------------------------------------------------------------------------
Parallel coordinates plot macro, Shane Rosanbalm, Rho, Inc., 2017

Description:
   This macro generates a parallel coordinates plot. 
      http://www.datavizcatalogue.com/methods/parallel_coordinates.html
   The user specifies the name of a dataset, the names of several numeric 
   variables within that dataset, and an optional grouping variable. The 
   macro performs some data manipulation to scale the variables to fit 
   on a single plot before producing output via SGPLOT. The user writes 
   wrapper code around the macro call to capture the output in their 
   preferrred ODS destination.

Required parameters:
   data     =  Name of input dataset.
               E.g., data=sashelp.cars
   var      =  Space-separated list of numeric variables to plot.
               E.g., var=enginesize horsepower msrp invoice

Optional parmeters:
   group    =  Name of the grouping variable.
               E.g., group=origin
   axistype =  Type of yaxis to display.
               VALID: percentiles|datavalues
               DEFAULT: percentiles
               DETAILS: Using percentiles results in all variables being 
               scaled to [0,1] based on the min/max for that variable. 
               Axes are drawn on the left and right of the plot. Using 
               datavalues results in "nice" axis ranges being calculated
               for each variable. Tick values for each variable are 
               overlayed on top of the lines using the backlight option
               of the text statement.
   debug    =  To debug or not to debug...
               VALID: yes|no
               DEFAULT: no

Example 1:
   %parallel
      (data=sashelp.iris
      ,var=sepallength sepalwidth petallength petalwidth
      ,group=species
      );
   Result for this call:
      https://github.com/srosanba/sas-parallelcoordinatesplot/raw/master/img/iris_by_percentiles.png

Example 2:
   %parallel
      (data=sashelp.iris
      ,var=sepallength sepalwidth petallength petalwidth
      ,group=species
      ,axistype=datavalues
      );
   Result for this call:
      https://github.com/srosanba/sas-parallelcoordinatesplot/raw/master/img/iris_by_datavalues.png

--------------------------------------------------------------------------------------------------*/

%macro parallel
         (data=
         ,var=
         ,group=
         ,axistype=percentiles
         ,debug=no
         ) / minoperator;

   %*--- required checks ---;
   %if &data eq %str() %then 
      %put %str(W)ARNING: parameter DATA is required;
      
   %if &var eq %str() %then 
      %put %str(W)ARNING: parameter VAR is required;
      
   %*--- valid value checks ---;
   %let debug = %upcase(&debug);
   %if not (&debug in (YES Y NO N)) %then
      %put %str(W)ARNING: unexpected value of &=debug;
      
   %let axistype = %upcase(&axistype);
   %if not (&axistype in (PERCENTILES DATAVALUES)) %then
      %put %str(W)ARNING: unexpected value of &=axistype;
      
   %*--- bookkeeping ---;
   %local i linecolor;
   %let linecolor = cx2A25D9;
   %if &group = %str() %then
      %let group = _pcp_dummygroup;

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

   %*--- dataset existence check ---;
   %if not %sysfunc(exist(&data)) %then
      %put %str(W)ARNING: &=data does not exist;
      
   %*--- dataset conflict check ---;
   proc sql noprint;
      select   count(*)
      into     :pcpdatas
      from     dictionary.tables
      where    libname = "WORK"
               and substr(memname,1,4) = "_PCP"
      ;
      %put &=pcpdatas;
   quit;
   %if &pcpdatas > 0 %then %do;
      %put %str(W)ARNING: WORK dataset names beginning with "_PCP" can be problematic;
      %put NOTE: the above %str(W)ARNING is unavoidable if you have debug turned on;
   %end;
      
   %*--- rename dataset for convenience ---;
   data _pcp10;
      set &data;
      _pcp_dummygroup = 1;
      keep &var &group;
   run;

   %*--- variable existence checks ---;
   %do i = 1 %to &var_n;
      %if not %varexist(data=_pcp10,var=&&var&i) %then
         %put %str(W)ARNING: variable &&var&i does not exist;
   %end;
   
   %if &group ne %str() %then %do;
      %if not %varexist(data=_pcp10,var=&group) %then
         %put %str(W)ARNING: variable &group does not exist;
   %end;
   
   %*--- variable name conflict check ---;
   %local pcpvars;
   proc sql noprint;
      select   count(*)
      into     :pcpvars
      from     dictionary.columns
      where    libname = "WORK"
               and memname = "_PCP10"
               and upcase(substr(name,1,5)) = "_PCP_"
               and upcase(name) ne "_PCP_DUMMYGROUP"
      ;
      %put &=pcpvars;
   quit;
   %if &pcpvars > 0 %then %do;
      %put %str(W)ARNING: variable names in &=data beginning with "_PCP_" can be problematic;
      %put NOTE: avoid variable names beginning with "_PCP_" if at all possible;
   %end;
      
   %*--- type checks ---;
   %do i = 1 %to &var_n;
      %local type&i;
      proc sql noprint;
         select   type
         into     :type&i
         from     dictionary.columns
         where    libname = "WORK"
                  and memname = "_PCP10"
                  and upcase(name) = upcase("&&var&i")
         ;
      quit;
      %if &&type&i ne num %then
         %put %str(W)ARNING: variable &&var&i is not numeric;         
   %end;
   
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
      %put label&i=&&label&i;
   %end;

   %*--- make dataset vertical ---;
   data _pcp20;
      set _pcp10;
      _pcp_series = _N_;
      %do i = 1 %to &var_n;
         _pcp_var = &i;
         length _pcp_varc $40;
         _pcp_varc = "&&label&i";
         if _pcp_varc = "" then
            _pcp_varc = "&&var&i";
         _pcp_yval = &&var&i;
         output;
      %end;
   run;

   %*--- standardize results based on start/end (dv) and min/max (pct) ---;
   %do i = 1 %to &var_n;

      data _pcp25;
         set _pcp20;
         where _pcp_var = &i;
      run;

      %axisorder
         (data=_pcp25
         ,var=_pcp_yval
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
         if _pcp_var = &i then do;
            _pcp_start = &&AxisStart&i;
            _pcp_end = &&AxisEnd&i;
            _pcp_dvrange = _pcp_end - _pcp_start;
            _pcp_yval_dv = (_pcp_yval - _pcp_start) / _pcp_dvrange;
            _pcp_min = &&AxisMin&i;
            _pcp_max = &&AxisMax&i;
            _pcp_pctrange = _pcp_max - _pcp_min;
            _pcp_yval_pct = (_pcp_yval - _pcp_min) / _pcp_pctrange;
         end;
      %end;
   run;

   %*--- prep for legend ---;
   proc sort data=_pcp30;
      by &group _pcp_series;
   run;

   data _pcp35;
      set _pcp30;
      by &group _pcp_series;
      retain _pcp_firstseries;
      if first.&group then
         _pcp_firstseries = _pcp_series;
      if _pcp_series = _pcp_firstseries then do;
         _pcp_varforlegend = _pcp_var;
         _pcp_yvalforlegend_dv = _pcp_yval_dv;
         _pcp_yvalforlegend_pct = _pcp_yval_pct;
         _pcp_seriesforlegend = &group;
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
               "varf" as fmtname,
               _pcp_var as start,
               _pcp_varc as label
      from     _pcp40
      ;
   quit;

   proc format cntlin=_pcp45;
   run;

   data _pcp50;
      set _pcp40;
      format _pcp_var _pcp_varforlegend varf.;
   run;

   %*--- add records for datavalues ---;
   data _pcp55;
      %do i = 1 %to &var_n;
         _pcp_xtext = &i;
         do _pcp_yloop = &&AxisList&i;
            _pcp_start = &&AxisStart&i;
            _pcp_end = &&AxisEnd&i;
            _pcp_dvrange = _pcp_end - _pcp_start;
            _pcp_ytext = (_pcp_yloop - _pcp_start) / _pcp_dvrange;
            _pcp_texttext = strip(put(_pcp_yloop,best.));
            output;
         end;
      %end;
   run;

   data _pcp60;
      set _pcp50 _pcp55;
      format _pcp_xtext varf.;
   run;

   %*--- calculate offset ---;
   data _null_;
      offset = 0.25*(1/&var_n);
      call symputx("offset",offset);
   run;
   %letput(offset);

   %*--- set some values pre-plot ---;
   %local yval yvalforlegend;
   %if &axistype = PERCENTILES %then %do;
      %let yval = _pcp_yval_pct;
      %let yvalforlegend = _pcp_yvalforlegend_pct;
   %end;
   %else %if &axistype = DATAVALUES %then %do;
      %let yval = _pcp_yval_dv;
      %let yvalforlegend = _pcp_yvalforlegend_dv;
   %end;

   %*--- at long last, we plot ---;
   proc sgplot data=_pcp60 nocycleattrs noautolegend noborder;
      styleattrs axisextent=data;
      %*--- primary series plot ---;
      series x=_pcp_var y=&yval / 
         group=_pcp_series 
         %if &group ne _pcp_dummygroup %then %do;
            grouplc=&group
         %end;
         lineattrs=(
            pattern=solid 
            %if &group eq _pcp_dummygroup %then %do;
               color=&linecolor
            %end;
            )
         x2axis
         ;
      %*--- copy to get y2axis ---;
      %if &axistype = PERCENTILES %then %do;
         series x=_pcp_var y=&yval / 
            group=_pcp_series 
            %if &group ne _pcp_dummygroup %then %do;
               grouplc=&group
            %end;
            lineattrs=(
               pattern=solid 
               %if &group eq _pcp_dummygroup %then %do;
                  color=&linecolor
               %end;
               )
            x2axis
            y2axis
            ;
      %end;
      %*--- tick values added sans tick marks ---;
      %if &axistype = DATAVALUES %then %do;
         text x=_pcp_xtext y=_pcp_ytext text=_pcp_texttext /
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
         %if &axistype = PERCENTILES %then %do;
            display=(nolabel)
            grid
         %end;
         %else %if &axistype = DATAVALUES %then %do;
            display=none
         %end;
         ;
      y2axis
         %if &axistype = PERCENTILES %then %do;
            display=(nolabel)
            grid
         %end;
         %else %if &axistype = DATAVALUES %then %do;
            display=none
         %end;
         ;
      %*--- reduced version to get a legend ---;
      %if &group ne _pcp_dummygroup %then %do;
         series x=_pcp_varforlegend y=&yvalforlegend / 
            group=_pcp_seriesforlegend 
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
   
   %*--- clean up ---;
   %if &debug in (N NO) %then %do;
      proc datasets library=work;
         delete _pcp:;
      run; quit;
   %end;

%mend parallel;
