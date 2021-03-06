####################################################
####SVM Approaches
####################################################
source("data_prep.R")

# ######Fit a simple SVM using the e1071 package
# weights<-table(TRAIN$Productivity)/nrow(TRAIN)
# # ###this shows the effect of loss function
# # weights["A"]=0.97
# # weights["B"]=0.01
# # weights["C"]=0.01
# 
# 
# ####Do A linear Fit
# tune.out<-tune(svm,Productivity~H1+H2+Race,data=TRAIN,kernel="polynomial",
#          class.weights=weights,degree=1,scale=T,
#      ranges=list(cost=c(0.001,0.01,1,5,10,100)))
# summary(tune.out)
# 
# bestmod=tune.out$best.model
# summary(bestmod)
# 
# plot(bestmod,TRAIN,H1~H2)


###Plot the linear fit
######Plot 2-D grid of Classification Rule
create_grid<-function(x1,x2,n=1000){
  min_x1<-min(x1)
  max_x1<-max(x1)
  x1_seq<-seq(min_x1,max_x1,length.out=floor(sqrt(n)))
  min_x2<-min(x2)
  max_x2<-max(x2)
  x2_seq<-seq(min_x2,max_x2,length.out=floor(sqrt(n)))
  grid<-expand.grid(H1=x1_seq,H2=x2_seq)
  return(grid)
}

grid<-create_grid(DATA$H1,DATA$H2,n=10000)


par_disp<-unique(TRAIN$Race)
race=par_disp[3]


for(race in par_disp){
  CUT_TRAIN<-TRAIN[TRAIN$Race==race, ]
  weights<-100/table(CUT_TRAIN$Productivity)/nrow(CUT_TRAIN)
  ###this shows the effect of loss function
  # weights["A"]=0.97
  # weights["B"]=0.01
  # weights["C"]=0.01
  
  ####Do A linear Fit seperate for each race so the weights work properly
  tune.out<-tune(svm,Productivity~H1+H2,data=CUT_TRAIN,kernel="polynomial",
                 class.weights=weights,degree=1,scale=T,
                 ranges=list(cost=c(0.001,0.01,1,5,10,100)))
  summary(tune.out)
  bestmod=tune.out$best.model
  summary(bestmod)

  
    
  ###do the holdout validation
  CUT_TEST<-TEST[TEST$Race==race, ]
  grid$Race=CUT_TEST$Race[1]
  grid$class<-predict(bestmod,newdata = grid)
  class<-predict(bestmod,newdata=CUT_TEST)
  out<-data.frame(table(class,CUT_TEST$Productivity))
  for(id in unique(out$Var2)){
    out$Freq[out$Var2==id]<-out$Freq[out$Var2==id]/sum(out$Freq[out$Var2==id])
  }
  out<-out[ out$class==out$Var2,]
  c<-paste0(out$Var2,"=",round(out$Freq,2)*100,"%",collapse="; ")
  
  base_layer<-ggplot(data=grid,aes(x=H1,y=H2,colour=class))+
    ggtitle(paste("Decision Boundaries, Race=",race))+
    geom_point(size=3.5,alpha=1,shape=15)
  
  train_plot<-base_layer+geom_text(data=CUT_TEST,aes(x=H1,y=H2,label=Productivity),size=5,colour="black")+
    ggtitle(paste("Decision Boundaries for",race,"Percent Correct=",c))+facet_wrap(~Productivity,ncol=2)
  print(train_plot)
  
}









################################################
#######Radial Fit
################################################


for(race in par_disp){
  CUT_TRAIN<-TRAIN[TRAIN$Race==race, ]
  weights<-100/table(CUT_TRAIN$Productivity)/nrow(CUT_TRAIN)
  ###this shows the effect of loss function
  # weights["A"]=0.97
  # weights["B"]=0.01
  # weights["C"]=0.01
  
  ####Do A linear Fit seperate for each race so the weights work properly
  tune.out<-tune(svm,Productivity~H1+H2,data=CUT_TRAIN,kernel="radial",
                 class.weights=weights,degree=1,scale=T,
                 ranges=list(cost=c(0.001,0.01,1,5,10,100)))
  summary(tune.out)
  bestmod=tune.out$best.model
  summary(bestmod)
  
  
  
  ###do the holdout validation
  CUT_TEST<-TEST[TEST$Race==race, ]
  grid$Race=CUT_TEST$Race[1]
  grid$class<-predict(bestmod,newdata = grid)
  class<-predict(bestmod,newdata=CUT_TEST)
  out<-data.frame(table(class,CUT_TEST$Productivity))
  for(id in unique(out$Var2)){
    out$Freq[out$Var2==id]<-out$Freq[out$Var2==id]/sum(out$Freq[out$Var2==id])
  }
  out<-out[ out$class==out$Var2,]
  c<-paste0(out$Var2,"=",round(out$Freq,2)*100,"%",collapse="; ")
  
  base_layer<-ggplot(data=grid,aes(x=H1,y=H2,colour=class))+
    ggtitle(paste("Decision Boundaries, Race=",race))+
    geom_point(size=3.5,alpha=1,shape=15)
  
  train_plot<-base_layer+geom_text(data=CUT_TEST,aes(x=H1,y=H2,label=Productivity),size=5,colour="black")+
    ggtitle(paste("Decision Boundaries for",race,"Percent Correct=",c))+facet_wrap(~Productivity,ncol=2)
  print(train_plot)
  
}
