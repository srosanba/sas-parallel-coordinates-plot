/*----------------------------------------------------------------------------------*

   *******************************************************
   *** Copyright 2015, Rho, Inc.  All rights reserved. ***
   *******************************************************

   MACRO:      %LetPut
   
   PURPOSE:    Write %let and %put statements for a given macro variable. E.g.,
   
                  %let mymacvar = &mymacvar;
                  %put NOTE- mymacvar = [&mymacvar];
               
   ARGUMENTS:  _mvar    => macro variable name.

   RETURNS:    None.

   USAGE:      Call the macro as a standalone statement. E.g., 

                  %LetPut(sqlobs);

   NOTES:      The purpose of the %let half of the macro is to trim leading and
               trailing spaces from the macro variable value.
               The purpose of the %put half of the macro is to write the value
               of the macro variable to the log (indented and blue).

   PROGRAM HISTORY:

   Date        Programmer        Description
   ---------   ---------------   ----------------------------------------------------
   2015-07-16  Shane Rosanbalm   Original program. 
   2016-03-23  Shane Rosanbalm   Defend against macro variables beginning with SYS.   
   2016-12-12  Shane Rosanbalm   Defend against apostrophes in macro values.

*-----------------------------------------------------------------------------------*/

%macro letput(_mvar);

   %if %symexist(&_mvar) eq 1 %then %do;

      %let issys = 0;
      
      %*--- if macro variable name begins with SYS, send a message ---;
      
      %if %length(&_mvar) >= 3 %then %do;
      
         %if %upcase(%substr(&_mvar,1,3)) = SYS %then %do;
         
            %let issys = 1;
            %put NOTE- Macro variable name %upcase(&_mvar) begins with SYS,;
            %put NOTE- which is common of read-only system macro variables.;
            %put NOTE- Macro LetPut will not attempt the Let portion of the operation.;
         
         %end;
         
      %end;
      
      %*--- only attempt to left-justify non-AUTOMATIC ---;
      
      %if &issys = 0 %then 
         %let &_mvar = %nrbquote(%sysfunc(strip(&&&_mvar)));
      
      %*--- write to log, indented and blue and bracketed ---;   
      
      %put NOTE- &_mvar = [%nrbquote(&&&_mvar)];

   %end;

   %else %put NOTE- Macro variable %upcase(&_mvar) does not exist.;

%mend letput;