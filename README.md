## Parallel Coordinates Plot in SAS

A parallel coordinates plot is used to visualize multivariate data ([google image results](https://www.google.com/search?q=parallel+coordinates+plot&safe=off&source=lnms&tbm=isch&sa=X&ved=0ahUKEwjh5uKv_JLSAhVBjlQKHYe9DGEQ_AUICCgB&biw=1010&bih=892)). Producing a parallel coordinates plot in SAS is not straightforward. There definitely isn’t a PARALLEL statement in SGPLOT. The best approach I could find on lexjansen.com was from SAS author [Prashant Hebbar](https://support.sas.com/resources/papers/proceedings12/267-2012.pdf). The outlined process certainly works, but it's written for readability and not for flexibility or scalability. I decided to experiment to see if was possible to generate a parallel coordinates plot using more flexible and scalable code. The result of this experiment is a macro called `%parallelplot` which is capable of producing a parallel coordinates plot with a minimum of parameters.

**Example 1**: plotting based on percentiles.

```
%parallelplot
   (data=sashelp.iris
   ,var=sepallength sepalwidth petallength petalwidth
   ,group=species
   );
```

![parallel percentiles](https://github.com/srosanba/sas-parallelcoordinatesplot/blob/master/img/iris_by_percentiles.png)

**Example 2**: plotting based on data values.

```
%parallelplot
   (data=sashelp.iris
   ,var=sepallength sepalwidth petallength petalwidth
   ,group=species
   ,axistype=datavalues
   );
```

![parallel datavalues](https://github.com/srosanba/sas-parallelcoordinatesplot/blob/master/img/iris_by_datavalues.png)

See the [wiki](https://github.com/srosanba/sas-parallelcoordinatesplot/wiki) for more details on `%parallelplot`.
