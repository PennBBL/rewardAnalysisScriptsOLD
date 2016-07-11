#V3 is an attempt to add the ability to select only certain measures
#V3.1 cleaned up code, fixed bugs leaving out participants with no slected measures, and dropped unnescessary columns
#V3.2 & V3.3 updated code, includes NA ratio and date range etc.
#V3.4 added support for new server, selkie instead of banshee RedCap

#Load Relevant Packages and set configurations in R for version R3.0.2
library("bitops")
library("REDCapR")
library("httr")
set_config(config(ssl_verifypeer = 0L))
set_config(config(sslversion = 1))
library("RCurl")
source("/data/joy/BBL/projects/rewardAnalysis/rewardAnalysisScripts/summaryScores/redcap_read_rdh.R")
version="collapse_redcap_data_across_forms_v3.4"

######date matching measures from redcap#######
#####parse arguments#####
print(commandArgs(trailingOnly=TRUE))
project<-commandArgs(trailingOnly=TRUE)[1]
range<-commandArgs(trailingOnly=TRUE)[2]
ids_path<-commandArgs(trailingOnly=TRUE)[3]
out_path<-commandArgs(trailingOnly=TRUE)[4]
minratio<-commandArgs(trailingOnly=TRUE)[5]
range<-as.numeric(range) #this must be set as numeric so that the ratio is read in as a value with which calculations can be completed
minratio<-as.numeric(minratio) #this must be set as numeric so that the ratio is read in as a value with which calculations can be completed
arguments_count<-length(commandArgs(trailingOnly=TRUE))
if (arguments_count > 6 ){
  selected_measures<-
    commandArgs(trailingOnly=TRUE)[6:arguments_count]
  print(paste("Selected measures are: ",paste(selected_measures,collapse=" "),sep=""))
} else if (arguments_count == 6 ){
  selected_measures<-
    commandArgs(trailingOnly=TRUE)[6]
  if (grepl(".csv", selected_measures)) {
    data.measures <- read.csv(selected_measures, as.is = T, header=F)
    selected_measures <- as.character(data.measures[,1])
    print(paste("Selected measures are: ",paste(selected_measures,collapse=" "),sep=""))
  } else {
    print(paste("Selected measures are: ",paste(selected_measures,collapse=" "),sep=""))
  }
}

#####

#ONLY UNCOMMENT FOR TESTING PURPOSES#
###variables for testing - sets args if in test mode#####
#if (exists("testing")){
  #project<-"Wolf Satterthwaite Repository"
  #ids_path<-"/import/monstrum/Users/hopsonr/test2_bblid_date.csv"
  #ids_path<-"/import/monstrum/Users/adaldal/Ryan Test/test_bblid_date2.csv"
  #ids_path<-"/import/monstrum/Users/adaldal/effort_45.csv"
  #ids_path<-"/import/monstrum/Users/adaldal/effort_350.csv"
  #ids_path<-"/import/monstrum/Users/adaldal/prt96fixdate4aylin.csv"
  #range=1500
  #out_path<-"/import/monstrum/Users/adaldal/test_12-17-15.csv"
  #selected_measures<-c("pas","qls")
  #selected_measures<-c("scanid","studyenroll","diagnosis","demographics","bdi","bdiold","grit","cdss","bdisummary","gritsummary","cdsssummary")
  #selected_measures<-c("prt", "bdisummary","sessummary","medications")
  #arguments_count<-6
  #minratio<-0.8
#}
#####

###read in bblid and date
ids<-read.csv(ids_path,header=F,col.names=c("bblid","date"))

#Scriptimports user projects from REDCap to R using an Application Programming Interface & User-Specific Tokens
#Tokens for projects provided by REDCap administrator
#Tokens need to be saved in a config file (.redcap.cfg) that is only editable by user

#Create a redcap.cfg file in Users directory with ALL User-Projects and User-specific Tokens
#read in path and token
redcap_uri <- "https://selkie.uphs.upenn.edu/api/"
ALL_Projects<-read.csv("~/.redcap.cfg")

#List of projects needed for full data import 
projects<-ALL_Projects[which(ALL_Projects[,1] == project),]

####Importing selected Selkie Redcap Project and Dictionary####
i<-1
p.token<-projects[i,2]
name<-(projects[i,1])
print(p.token)
print(name)

project_dictionary<-redcap_metadata_read(redcap_uri=redcap_uri, token=p.token)$data

unique_id<-project_dictionary$field_name[1]
batch=10000
project_ids<-redcap_read_rdh(
  redcap_uri = redcap_uri,
  token = p.token,
  #records = ids,
  #config_options = httr::config(ssl_verifypeer=FALSE,ssl_verifyhost=FALSE), #uncommented due to R update, not recognized in R3.0.2 but may be needed in future
  fields=unique_id,
  batch_size=batch
)$data

project_data<-redcap_read_rdh(
  redcap_uri = redcap_uri,
  token = p.token,
  #config_options = httr::config(ssl_verifypeer=FALSE,ssl_verifyhost=FALSE), #uncommented due to R update, not recognized in R3.0.2 but may be needed in future
  batch_size=1000,
  interbatch_delay=5
)$data

if(nrow(project_data)!=nrow(project_ids)){
  print("Error in reading data. Finding problem records")
  problemids<-project_ids$participant_id[which(! project_ids$participant_id %in% project_data$participant_id)]
  batch<-batch/10
  while(batch >= 1){
    #print(paste("batch: ",batch,sep="")) #uncomment if errors with downloading batches to see which exact batch the error occurred in, to narrow down which record contains the error
    #print(paste("problemids: ",problemids,sep="")) #uncomment if errors with downloading batches to see which exact batch the error occurred in, to narrow down which record contains the error
    project_data_issues<-redcap_read_rdh(
      redcap_uri = redcap_uri,
      token = p.token,
      #config_options = httr::config(ssl_verifypeer=FALSE,ssl_verifyhost=FALSE), #uncommented due to R update, not recognized in R3.0.2 but may be needed in future
      records=problemids,
      batch_size=batch
    )$data
    problemids<-problemids[which(! problemids %in% project_data_issues[[unique_id]])]
    batch<-batch/10
  }
  print("Error detected in: ")
  print(problemids)
}

#####

#fill in blank measures - removed starting in V3. procedure is required in redcap now, so can't be blank
#project_data$procedure<-matrix(unlist(strsplit(project_data$participant_id,split="_")), ncol=3, byrow=TRUE)[,2]
#backup<-project_data

###temporary fix to mismatched project_data$procedure/project_dictionary$form_name
if (length(unique(project_data$procedure)[which(! unique(project_data$procedure) %in% unique(project_dictionary$form_name))]) > 0){
  for (missing in unique(project_data$procedure)[which(! unique(project_data$procedure) %in% unique(project_dictionary$form_name))])
    print(paste("Procedure \'",missing,"\' does not exist in data dictionary.",sep=""))
  stop("Procedures and forms unmatched. Please check your Redcap data.")
}

###initialize output data frame#####
if (arguments_count > 5){
  project_measures<-unique(project_dictionary$form_name)[which(unique(project_dictionary$form_name) %in% selected_measures)]
  if(length(selected_measures[which(! selected_measures %in% unique(project_dictionary$form_name))]) > 0){
    missing_selected_measures<-selected_measures[which(! selected_measures %in% unique(project_dictionary$form_name))]
    stop(paste("One or more selected measures do not exist: ",paste(missing_selected_measures,collapse=" "),sep=""))
  }
  column_names<-project_dictionary$field_name[which(project_dictionary$form_name %in% c(project_measures,"general"))]
  project_data<-project_data[,c(column_names)]
  project_data<-project_data[which(project_data$procedure %in% project_measures),]
}else{
  project_measures<-unique(project_dictionary$form_name)
}
project_measures<-project_measures[which(! project_measures=="general")]
n_measures<-length(project_measures)
project_data[,paste(project_measures,"distance",sep="_")]<-NA
project_data[,paste(project_measures,"dovisit",sep="_")]<-NA
project_data[,paste(project_measures,"included",sep="_")]<-NA
project_data$dist<-NA
project_data$date_provided<-NA
project_data$dovisit2<-NA
project_data$age_at_date_provided<-NA
output<-as.data.frame(matrix(nrow=0,ncol=ncol(project_data)),row.names=NULL)
colnames(output)<-colnames(project_data)
bblid_row<-as.data.frame(matrix(nrow=1,ncol=ncol(project_data)),row.names=NULL)
colnames(bblid_row)<-colnames(project_data)

#####

#####convert dates to usable values####
formatA<-grep("/",project_data$dovisit,invert=T)
formatB<-grep("/",project_data$dovisit,invert=F)
project_data$dovisit2<-NA
project_data$dovisit2[c(formatA)]<-as.Date(project_data$dovisit[c(formatA)], format="%Y%m%d")
project_data$dovisit2[c(formatB)]<-as.Date(project_data$dovisit[c(formatB)], format="%m/%d/%y")
project_data$dovisit2<-as.Date(project_data$dovisit2,origin="1970-01-01")
#####

####convert dob to usable value####
if("demographics" %in% selected_measures){
  formatA<-grep("/",project_data$dob,invert=T)
  formatB<-grep("/",project_data$dob,invert=F)
  project_data$dob2<-NA
  project_data$dob2[c(formatA)]<-as.Date(project_data$dob[c(formatA)], format="%Y%m%d")
  project_data$dob2[c(formatB)]<-as.Date(project_data$dob[c(formatB)], format="%m/%d/%y")
  project_data$dob2<-as.Date(project_data$dob2,origin="1970-01-01")
  project_data$dob2[which(project_data$dob2 > as.Date("2008-01-01"))]<-project_data$dob2[which(project_data$dob2 > as.Date("2008-01-01"))]-36525
  project_data$dob<-project_data$dob2
  project_data$dob2<-NULL
}

####loop through participants (rows of participant_ids), collapse across forms####
for (i in 1:nrow(ids)){
  ####check date for participant
  bblid<-ids[i,1]
  date<-ids[i,2]
  #print(bblid)
  
  ##make first row
  bblid_row$bblid<-bblid
  bblid_row$date_provided<-date
  output<-rbind(output,bblid_row)
  
  #print(date)
  #date<-ids$date[which(ids$bblid==bblid)]
  #convert input date to usable
  date<-as.Date(as.character(date), format="%Y%m%d")
  
  #make temp of bblid
  temp<-project_data[which(project_data$bblid == bblid & project_data$dovisit2 > date - range & project_data$dovisit2 < date + range),]
  #get all measures for that participant
  measures=unique(temp$procedure)
  #get distance for rows
  temp$dist<-temp$dovisit2 - date
  if (length(measures) > 0){
    for (measure in measures){
      ###get the row that contains the version of the measure closest to the date
      row<-temp[which(temp$procedure==measure),]
      ###if more than one measure exists on the same day, take the one with fewest NAs
      #NAs are calculated based on columns in that specific measure, does not include participant_id or procedure columns when calculatin NAs but does include NAflag columns and measure_complete columns
      if (nrow(row) > 1){
        NAs<-apply(row[,c("bblid",project_dictionary$field_name[which(project_dictionary$form_name==measure)])],1,function(x) sum(is.na(x)))
        othernas<-apply(row[,c("bblid",project_dictionary$field_name[which(project_dictionary$form_name==measure)])],1,function(x) sum(x=="-9999",na.rm=T))
        na_counts<-NAs+othernas
        na_counts<-1-(na_counts/length(project_dictionary$field_name[which(project_dictionary$form_name==measure)])) #orig ryan code
        if(nrow(row[which(na_counts > minratio),]) > 0){row<-row[which(na_counts > minratio),]}
      }
      ###look for infinite min error
      if ( min(abs(temp$dist[which(temp$procedure==measure)])) == Inf){print(bblid)}
      ###take minium distance
      row<-row[which(abs(row$dist) == min(abs(row$dist))),]
      ###if more than one measure is the same distance from the date, take the first one
      if (nrow(row) > 1){row<-row[which.min(row$dovisit2),]}
      ###if there are STILL multiple measures, I give up, take the first one
      if (nrow(row) > 1){row<-row[1,]}
      ###fill in measures for output
      output[which(output$bblid==bblid & as.Date(as.character(output$date_provided), format="%Y%m%d")==date),c(project_dictionary$field_name[which(project_dictionary$form_name==measure)])]<-
        row[,c(project_dictionary$field_name[which(project_dictionary$form_name==measure)])]
      ###add distance and date for each measure
      output[which(output$bblid==bblid & as.Date(as.character(output$date_provided), format="%Y%m%d")==date),paste(measure,"distance",sep="_")]<-row$dist
      output[which(output$bblid==bblid & as.Date(as.character(output$date_provided), format="%Y%m%d")==date),paste(measure,"dovisit",sep="_")]<-row$dovisit
      output[which(output$bblid==bblid & as.Date(as.character(output$date_provided), format="%Y%m%d")==date),paste(measure,"included",sep="_")]<-1
      if(measure=="demographics"){output[which(output$bblid==bblid & as.Date(as.character(output$date_provided), format="%Y%m%d")==date),"age_at_date_provided"]<-as.numeric(date-row$dob)/365.25}
    }
  }
  ###set missing measures to NA
  for (missing_measure in project_measures[which(! project_measures %in% measures & project_measures != "general")]){
    output[which(output$bblid==bblid & output$date_provided==date),c(project_dictionary$field_name[which(project_dictionary$form_name==missing_measure)])]<-NA
    output[which(output$bblid==bblid & as.Date(as.character(output$date_provided), format="%Y%m%d")==date),paste(missing_measure,"included",sep="_")]<-0
  }
  
}
#####

###remove unnecessary columns added for collapsing#####
output$dovisit2=NULL
output$dist=NULL
output$dovisit=NULL
output$participant_id<-NULL
output$procedure<-NULL
output$version<-version
output$dob<-as.Date(output$dob,origin="1970-01-01")
output$date_range<-range
output$min_ratio_values_to_fields<-minratio
if (! "demographics" %in% measures){
  output<-output[,c("bblid","date_provided","date_range","min_ratio_values_to_fields",
                    colnames(output[which(! colnames(output) %in% c("bblid","date_provided","date_range","min_ratio_values_to_fields"))]))]
}else{
  output<-output[,c("bblid","date_provided","date_range","min_ratio_values_to_fields","age_at_date_provided",
                    project_dictionary$field_name[which(project_dictionary$form_name=="demographics")],
                    colnames(output[which(! colnames(output) %in% c("bblid","date_provided","date_range","min_ratio_values_to_fields") &
                                            ! colnames(output) %in% project_dictionary$field_name[which(project_dictionary$form_name=="demographics")])]))]
}

#####

####write out data####
write.table(output,file=out_path,sep=",",row.names=F)
####



