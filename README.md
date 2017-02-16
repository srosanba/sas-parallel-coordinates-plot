## Parallel Coordinates Plot in SAS

A parallel coordinates plot is used to visualize multivariate data ([google image results](https://www.google.com/search?q=parallel+coordinates+plot&safe=off&source=lnms&tbm=isch&sa=X&ved=0ahUKEwjh5uKv_JLSAhVBjlQKHYe9DGEQ_AUICCgB&biw=1010&bih=892)). I could only find one example of such a plot having been created with SAS, on page 23 of a [SGF 2012 paper](https://support.sas.com/resources/papers/proceedings12/267-2012.pdf) by Prashant Hebbar of SAS. While the outline of the process for creating such a plot is revealed in this paper, the process comes across as being somewhat difficult (uses GTL) and mildly tedious (separate code blocks for each variable being plotted). I thought it would be nice to write some code to make it easier for the user to get from dataset to plot. The result is a macro called `%parallel` that produces a plot with a minimum of parameters.

**Example 1**: plotting based on percentiles.

```
%parallel
   (data=sashelp.iris
   ,var=sepallength sepalwidth petallength petalwidth
   ,group=species
   );
```

![parallel percentiles](https://github.com/srosanba/sas-parallelcoordinatesplot/blob/master/img/iris_by_percentiles.png)

**Example 2**: plotting based on data values.

```
%parallel
   (data=sashelp.iris
   ,var=sepallength sepalwidth petallength petalwidth
   ,group=species
   ,axistype=datavalues
   );
```

![parallel datavalues](https://github.com/srosanba/sas-parallelcoordinatesplot/blob/master/img/iris_by_datavalues.png)

See the [wiki](https://github.com/srosanba/sas-parallelcoordinatesplot/wiki) for more details on `%parallel`.
