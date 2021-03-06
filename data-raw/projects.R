# projects table
# 
# loads CSV files from NIH EXPORTER into tbl_df format
#
library(dplyr)
library(stringr)
library(tidyr)
library(lubridate)
library(readr)

## PROJECTS tables

# load projects data
path = 'data-raw//PROJECTS'
csvfiles <- dir(path, pattern = '\\.csv', full.names = TRUE)

col_types <- '_ccic____ccc_ic__c___c_c_c_i_ccc____c_c_ii'
tables <- lapply(csvfiles, function(x) read_csv(x, col_types = col_types))

projects.tbl <- rbind_all(tables)
projects.tbl <- tbl_df(projects.tbl)

# coerce colnames
names(projects.tbl) <- names(projects.tbl) %>%
  str_to_lower() %>%
  str_replace_all('_','.')

# org table - link on org.duns
project_orgs <- projects.tbl %>%
  select(org.city, org.state, org.duns, org.name) %>%
  filter(org.duns != '') %>%
  distinct() %>%
  arrange(org.duns)
save(project_orgs, file = 'data/project_orgs.rdata', compress = 'xz')

# project_pis table
project_pis <- projects.tbl %>%
  select(core.project.num, pi.ids) %>%
  rename(project.num = core.project.num) %>%
  separate(pi.ids, into = c(1:20), sep = ';', extra = 'drop') %>%
  gather(project.num) %>%
  setNames(c('project.num', 'pi.num', 'pi.id')) %>%
  filter(pi.id != '') %>%
  select(project.num, pi.id) %>%
  arrange(project.num)
save(project_pis, file = 'data/project_pis.rdata', compress = 'xz')

# projects table - only provide data after fy 2000 as costs are only available 2000 and onward.
projects <- projects.tbl %>%
  select(administering.ic, activity,
         core.project.num, fy, org.duns,
         project.start, project.end,
         study.section, suffix, total.cost) %>%
  rename(project.num = core.project.num,
         fiscal.year = fy,
         institute = administering.ic) %>%  
  mutate(project.end = mdy(project.end),
         project.start = mdy(project.start))
save(projects, file = 'data/projects.rdata', compress = 'xz')         
