[![Travis-CI Build Status](https://travis-ci.org/jayhesselberth/nihexporter.png?branch=master)](https://travis-ci.org/jayhesselberth/nihexporter)

nihexporter
===========

The `nihexporter` package provides a minimal set of data from [NIH EXPORTER](http://exporter.nih.gov/default.aspx), which contains information on NIH biomedical research funding from 1985-2014 (and continues monthly in a given fiscal year).

Information about specific columns in the tables is [here](http://exporter.nih.gov/about.aspx).

The package contains the following tables:

-   `projects`: provides data on funded projects by NIH.

-   `project_pis`: links project numbers (`project.num`) to PI ID (`pi.id`), which can used in NIH REPORTER searches

-   `project_orgs`: links DUNS numbers (`org.duns`) from `projects` table to information on specific organizations

-   `publinks`: links Pubmed IDs (`pmid`) to project numbers (`project.num`)

-   `patents`: links project IDs (`project.num`) to `patent.id`

-   `project_io`: pre-computed `n.pubs`, `n.patents` and `project.cost`

There are also a few helper variables that make exploratory analysis a bit easier:

-   `nih.institutes`: 27 NIH institutes in two-letter format

Data summary
------------

There is a lot of data in NIH EXPORTER, so this package aims to provide a minimal set of data without being too unwieldy. There are download and import scripts in the `data-raw/` directory in the package.

Because `total.cost` is only available from fiscal year 2000 and onward, only data from those years is provided in the `projects` table. The `publinks` table goes back to 1985.

Install
-------

Install the `nihexporter` package from github with:

    devtools::install_github("jayhesselberth/nihexporter")

Examples
--------

``` r
library(dplyr)
library(knitr)
library(ggplot2)
#> Warning: package 'ggplot2' was built under R version 3.1.3
library(nihexporter)
```

List the all-time most expensive grants from each institute:

``` r
expensive.projects <- projects %>%
  select(project.num, institute, total.cost, project.start, project.end) %>%
  group_by(project.num, institute) %>%
  summarise(overall.cost = sum(total.cost, na.rm = TRUE)) %>%
  ungroup() %>%
  group_by(institute) %>%
  arrange(desc(overall.cost)) %>%
  slice(1:1) %>%
  ungroup() %>%
  arrange(desc(overall.cost)) %>%
  mutate(cost.in.billions = overall.cost / 1e9)

head(expensive.projects)
#> Source: local data frame [6 x 4]
#> 
#>   project.num institute overall.cost cost.in.billions
#> 1 ZIHLM200888        LM   1544981304        1.5449813
#> 2 ZIFBC000001        CA    652060692        0.6520607
#> 3 U54HG003067        HG    527942706        0.5279427
#> 4 ZIFAI000001        AI    389496063        0.3894961
#> 5 ZIIMD000005        MD    373377914        0.3733779
#> 6 U62PS223540        PS    298137847        0.2981378
```

Let's look at the amounts spent on R01 grants at each NIH institute. Note this filters for NIH institutes.

``` r
grant.costs <- projects %>% 
  filter(institute %in% nih.institutes) %>%
  filter(activity == 'R01' & total.cost > 0) %>%
  select(institute, total.cost)

library(scales)
grant.costs %>%
  ggplot(aes(reorder(institute, total.cost, median, order=TRUE), total.cost)) +
  geom_boxplot(outlier.shape = NA) +
  coord_flip() +
  scale_y_continuous(limits = c(0, 8e5), labels = comma) +
  ylab('Total cost (dollars)') +
  xlab('NIH institute') + 
  ggtitle('Total cost of R01 grants from 2000-2014')
```

![](README-plot_grant_costs-1.png)

Vignettes
---------

See the [vignette](http://rpubs.com/jayhesselberth/nihexporter-vignette) or the [vignette source](vignettes/nihexporter.Rmd) for more examples.
